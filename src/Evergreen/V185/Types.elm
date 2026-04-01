module Evergreen.V185.Types exposing (..)

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
import Evergreen.V185.AiChat
import Evergreen.V185.ChannelName
import Evergreen.V185.Coord
import Evergreen.V185.CssPixels
import Evergreen.V185.Discord
import Evergreen.V185.DiscordAttachmentId
import Evergreen.V185.DiscordUserData
import Evergreen.V185.DmChannel
import Evergreen.V185.Editable
import Evergreen.V185.EmailAddress
import Evergreen.V185.Embed
import Evergreen.V185.Emoji
import Evergreen.V185.FileStatus
import Evergreen.V185.GuildName
import Evergreen.V185.Id
import Evergreen.V185.ImageEditor
import Evergreen.V185.Local
import Evergreen.V185.LocalState
import Evergreen.V185.Log
import Evergreen.V185.LoginForm
import Evergreen.V185.MembersAndOwner
import Evergreen.V185.Message
import Evergreen.V185.MessageInput
import Evergreen.V185.MessageView
import Evergreen.V185.MyUi
import Evergreen.V185.NonemptyDict
import Evergreen.V185.NonemptySet
import Evergreen.V185.OneToOne
import Evergreen.V185.Pages.Admin
import Evergreen.V185.Pagination
import Evergreen.V185.PersonName
import Evergreen.V185.Ports
import Evergreen.V185.Postmark
import Evergreen.V185.RichText
import Evergreen.V185.Route
import Evergreen.V185.SecretId
import Evergreen.V185.SessionIdHash
import Evergreen.V185.Slack
import Evergreen.V185.TextEditor
import Evergreen.V185.Touch
import Evergreen.V185.TwoFactorAuthentication
import Evergreen.V185.Ui.Anim
import Evergreen.V185.Untrusted
import Evergreen.V185.User
import Evergreen.V185.UserAgent
import Evergreen.V185.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V185.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V185.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) Evergreen.V185.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.LocalState.DiscordFrontendGuild
    , user : Evergreen.V185.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V185.SessionIdHash.SessionIdHash Evergreen.V185.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V185.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V185.Route.Route
    , windowSize : Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V185.Ports.NotificationPermission
    , pwaStatus : Evergreen.V185.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V185.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V185.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V185.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))) Evergreen.V185.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V185.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))) Evergreen.V185.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) Evergreen.V185.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.UserSession.ToBeFilledInByBackend (Evergreen.V185.SecretId.SecretId Evergreen.V185.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V185.GuildName.GuildName (Evergreen.V185.UserSession.ToBeFilledInByBackend (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage Evergreen.V185.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage Evergreen.V185.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V185.Id.GuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))) (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V185.Id.DiscordGuildOrDmId_DmData (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V185.UserSession.SetViewing
    | Local_SetName Evergreen.V185.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V185.Id.GuildOrDmId (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V185.Id.GuildOrDmId (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V185.Id.DiscordGuildOrDmId (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V185.Id.DiscordGuildOrDmId (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V185.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V185.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V185.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V185.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V185.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V185.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Effect.Time.Posix Evergreen.V185.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))) Evergreen.V185.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V185.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))) Evergreen.V185.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) Evergreen.V185.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.SecretId.SecretId Evergreen.V185.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V185.LocalState.JoinGuildError
            { guildId : Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId
            , guild : Evergreen.V185.LocalState.FrontendGuild
            , owner : Evergreen.V185.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Id.GuildOrDmId Evergreen.V185.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Id.GuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage Evergreen.V185.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Id.GuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage Evergreen.V185.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage Evergreen.V185.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage Evergreen.V185.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Id.GuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))) (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V185.Id.DiscordGuildOrDmId_DmData (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V185.SessionIdHash.SessionIdHash Evergreen.V185.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V185.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V185.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V185.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.ChannelName.ChannelName (Evergreen.V185.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId)
        (Evergreen.V185.NonemptyDict.NonemptyDict
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) Evergreen.V185.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Maybe (Evergreen.V185.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V185.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V185.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V185.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V185.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V185.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V185.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) (Evergreen.V185.Discord.OptionalData String) (Evergreen.V185.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
        (Evergreen.V185.MembersAndOwner.MembersAndOwner
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.PersonName.PersonName


type LocalMsg
    = LocalChange (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) Evergreen.V185.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V185.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V185.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V185.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V185.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V185.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V185.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V185.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V185.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V185.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels) (Maybe Evergreen.V185.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V185.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V185.Local.Local LocalMsg Evergreen.V185.LocalState.LocalState
    , admin : Evergreen.V185.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId, Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V185.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V185.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V185.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.NonemptyDict.NonemptyDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V185.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V185.TextEditor.Model
    , profilePictureEditor : Evergreen.V185.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V185.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V185.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V185.SecretId.SecretId Evergreen.V185.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V185.MyUi.Range
                , direction : Evergreen.V185.MyUi.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V185.NonemptyDict.NonemptyDict Int Evergreen.V185.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V185.NonemptyDict.NonemptyDict Int Evergreen.V185.Touch.Touch
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
    | AdminToFrontend Evergreen.V185.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V185.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V185.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V185.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V185.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V185.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V185.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V185.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V185.Ports.NotificationPermission
    , pwaStatus : Evergreen.V185.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V185.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V185.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V185.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V185.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V185.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V185.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V185.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId, Evergreen.V185.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V185.DmChannel.DmChannelId, Evergreen.V185.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId, Evergreen.V185.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId, Evergreen.V185.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V185.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V185.NonemptyDict.NonemptyDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V185.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V185.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V185.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V185.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V185.DmChannel.DmChannelId Evergreen.V185.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) Evergreen.V185.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V185.OneToOne.OneToOne (Evergreen.V185.Slack.Id Evergreen.V185.Slack.ChannelId) Evergreen.V185.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V185.OneToOne.OneToOne String (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    , slackUsers : Evergreen.V185.OneToOne.OneToOne (Evergreen.V185.Slack.Id Evergreen.V185.Slack.UserId) (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
    , slackServers : Evergreen.V185.OneToOne.OneToOne (Evergreen.V185.Slack.Id Evergreen.V185.Slack.TeamId) (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    , slackToken : Maybe Evergreen.V185.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V185.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V185.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V185.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V185.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId, Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V185.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V185.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V185.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V185.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.LocalState.LoadingDiscordChannel (List Evergreen.V185.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Array.Array Effect.Time.Posix)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V185.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V185.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V185.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V185.Route.Route
    | SelectedFilesToAttach ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) Evergreen.V185.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) Evergreen.V185.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V185.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V185.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V185.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V185.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V185.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V185.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V185.NonemptyDict.NonemptyDict Int Evergreen.V185.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V185.NonemptyDict.NonemptyDict Int Evergreen.V185.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V185.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V185.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V185.Editable.Msg Evergreen.V185.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V185.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V185.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V185.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute ) (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRouteWithMessage Evergreen.V185.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V185.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V185.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V185.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V185.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId
        , otherUserId : Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V185.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRoute Evergreen.V185.MessageInput.Msg
    | MessageInputMsg Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRoute Evergreen.V185.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V185.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V185.MyUi.Range, Evergreen.V185.MyUi.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V185.MyUi.Range, Evergreen.V185.MyUi.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V185.Id.AnyGuildOrDmId Evergreen.V185.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V185.Id.Id Evergreen.V185.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V185.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V185.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V185.Untrusted.Untrusted Evergreen.V185.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V185.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V185.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V185.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.SecretId.SecretId Evergreen.V185.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V185.PersonName.PersonName Evergreen.V185.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V185.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V185.Slack.OAuthCode Evergreen.V185.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V185.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V185.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V185.Id.Id Evergreen.V185.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V185.EmailAddress.EmailAddress (Result Evergreen.V185.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V185.EmailAddress.EmailAddress (Result Evergreen.V185.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V185.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMaybeMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Result Evergreen.V185.Discord.HttpError Evergreen.V185.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V185.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Result Evergreen.V185.Discord.HttpError Evergreen.V185.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) (Result Evergreen.V185.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) (Result Evergreen.V185.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) (Result Evergreen.V185.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) (Result Evergreen.V185.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji (Result Evergreen.V185.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji (Result Evergreen.V185.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji (Result Evergreen.V185.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji (Result Evergreen.V185.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V185.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V185.Discord.HttpError (List ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId, Maybe Evergreen.V185.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V185.Slack.CurrentUser
            , team : Evergreen.V185.Slack.Team
            , users : List Evergreen.V185.Slack.User
            , channels : List ( Evergreen.V185.Slack.Channel, List Evergreen.V185.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Result Effect.Http.Error Evergreen.V185.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Discord.UserAuth (Result Evergreen.V185.Discord.HttpError Evergreen.V185.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Result Evergreen.V185.Discord.HttpError Evergreen.V185.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
        (Result
            Evergreen.V185.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId
                , members : List (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
                }
            , List
                ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId
                , { guild : Evergreen.V185.Discord.GatewayGuild
                  , channels : List Evergreen.V185.Discord.Channel
                  , icon : Maybe Evergreen.V185.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V185.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.AttachmentId, Evergreen.V185.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V185.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.AttachmentId, Evergreen.V185.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V185.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V185.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V185.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V185.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) (Result Evergreen.V185.Discord.HttpError (List Evergreen.V185.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Result Evergreen.V185.Discord.HttpError (List Evergreen.V185.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V185.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V185.DmChannel.DmChannelId Evergreen.V185.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V185.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V185.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V185.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
        (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V185.Discord.HttpError
            { guild : Evergreen.V185.Discord.GatewayGuild
            , channels : List Evergreen.V185.Discord.Channel
            , icon : Maybe Evergreen.V185.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Result Evergreen.V185.Discord.HttpError ()) Effect.Time.Posix
