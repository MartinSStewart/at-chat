module Evergreen.V184.Types exposing (..)

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
import Evergreen.V184.AiChat
import Evergreen.V184.ChannelName
import Evergreen.V184.Coord
import Evergreen.V184.CssPixels
import Evergreen.V184.Discord
import Evergreen.V184.DiscordAttachmentId
import Evergreen.V184.DiscordUserData
import Evergreen.V184.DmChannel
import Evergreen.V184.Editable
import Evergreen.V184.EmailAddress
import Evergreen.V184.Embed
import Evergreen.V184.Emoji
import Evergreen.V184.FileStatus
import Evergreen.V184.GuildName
import Evergreen.V184.Id
import Evergreen.V184.ImageEditor
import Evergreen.V184.Local
import Evergreen.V184.LocalState
import Evergreen.V184.Log
import Evergreen.V184.LoginForm
import Evergreen.V184.MembersAndOwner
import Evergreen.V184.Message
import Evergreen.V184.MessageInput
import Evergreen.V184.MessageView
import Evergreen.V184.MyUi
import Evergreen.V184.NonemptyDict
import Evergreen.V184.NonemptySet
import Evergreen.V184.OneToOne
import Evergreen.V184.Pages.Admin
import Evergreen.V184.Pagination
import Evergreen.V184.PersonName
import Evergreen.V184.Ports
import Evergreen.V184.Postmark
import Evergreen.V184.RichText
import Evergreen.V184.Route
import Evergreen.V184.SecretId
import Evergreen.V184.SessionIdHash
import Evergreen.V184.Slack
import Evergreen.V184.TextEditor
import Evergreen.V184.Touch
import Evergreen.V184.TwoFactorAuthentication
import Evergreen.V184.Ui.Anim
import Evergreen.V184.Untrusted
import Evergreen.V184.User
import Evergreen.V184.UserAgent
import Evergreen.V184.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V184.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V184.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) Evergreen.V184.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.LocalState.DiscordFrontendGuild
    , user : Evergreen.V184.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V184.SessionIdHash.SessionIdHash Evergreen.V184.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V184.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V184.Route.Route
    , windowSize : Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V184.Ports.NotificationPermission
    , pwaStatus : Evergreen.V184.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V184.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V184.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V184.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))) Evergreen.V184.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V184.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))) Evergreen.V184.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) Evergreen.V184.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.UserSession.ToBeFilledInByBackend (Evergreen.V184.SecretId.SecretId Evergreen.V184.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V184.GuildName.GuildName (Evergreen.V184.UserSession.ToBeFilledInByBackend (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage Evergreen.V184.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage Evergreen.V184.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V184.Id.GuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))) (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V184.Id.DiscordGuildOrDmId_DmData (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V184.UserSession.SetViewing
    | Local_SetName Evergreen.V184.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V184.Id.GuildOrDmId (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V184.Id.GuildOrDmId (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V184.Id.DiscordGuildOrDmId (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V184.Id.DiscordGuildOrDmId (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V184.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V184.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V184.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V184.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V184.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V184.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Effect.Time.Posix Evergreen.V184.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))) Evergreen.V184.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V184.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))) Evergreen.V184.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) Evergreen.V184.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.SecretId.SecretId Evergreen.V184.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V184.LocalState.JoinGuildError
            { guildId : Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId
            , guild : Evergreen.V184.LocalState.FrontendGuild
            , owner : Evergreen.V184.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Id.GuildOrDmId Evergreen.V184.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Id.GuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage Evergreen.V184.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Id.GuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage Evergreen.V184.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage Evergreen.V184.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage Evergreen.V184.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Id.GuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))) (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V184.Id.DiscordGuildOrDmId_DmData (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V184.SessionIdHash.SessionIdHash Evergreen.V184.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V184.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V184.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V184.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.ChannelName.ChannelName (Evergreen.V184.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId)
        (Evergreen.V184.NonemptyDict.NonemptyDict
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) Evergreen.V184.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Maybe (Evergreen.V184.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V184.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V184.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V184.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V184.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V184.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V184.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) (Evergreen.V184.Discord.OptionalData String) (Evergreen.V184.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
        (Evergreen.V184.MembersAndOwner.MembersAndOwner
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.PersonName.PersonName


type LocalMsg
    = LocalChange (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) Evergreen.V184.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V184.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V184.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V184.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V184.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V184.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V184.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V184.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V184.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V184.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels) (Maybe Evergreen.V184.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V184.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V184.Local.Local LocalMsg Evergreen.V184.LocalState.LocalState
    , admin : Evergreen.V184.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId, Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V184.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V184.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V184.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.NonemptyDict.NonemptyDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V184.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V184.TextEditor.Model
    , profilePictureEditor : Evergreen.V184.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V184.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V184.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V184.SecretId.SecretId Evergreen.V184.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V184.MyUi.Range
                , direction : Evergreen.V184.MyUi.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V184.NonemptyDict.NonemptyDict Int Evergreen.V184.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V184.NonemptyDict.NonemptyDict Int Evergreen.V184.Touch.Touch
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
    | AdminToFrontend Evergreen.V184.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V184.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V184.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V184.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V184.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V184.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V184.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V184.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V184.Ports.NotificationPermission
    , pwaStatus : Evergreen.V184.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V184.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V184.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V184.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V184.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V184.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V184.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V184.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId, Evergreen.V184.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V184.DmChannel.DmChannelId, Evergreen.V184.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId, Evergreen.V184.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId, Evergreen.V184.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V184.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V184.NonemptyDict.NonemptyDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V184.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V184.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V184.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V184.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V184.DmChannel.DmChannelId Evergreen.V184.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) Evergreen.V184.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V184.OneToOne.OneToOne (Evergreen.V184.Slack.Id Evergreen.V184.Slack.ChannelId) Evergreen.V184.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V184.OneToOne.OneToOne String (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    , slackUsers : Evergreen.V184.OneToOne.OneToOne (Evergreen.V184.Slack.Id Evergreen.V184.Slack.UserId) (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
    , slackServers : Evergreen.V184.OneToOne.OneToOne (Evergreen.V184.Slack.Id Evergreen.V184.Slack.TeamId) (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    , slackToken : Maybe Evergreen.V184.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V184.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V184.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V184.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V184.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId, Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V184.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V184.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V184.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V184.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.LocalState.LoadingDiscordChannel (List Evergreen.V184.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Array.Array Effect.Time.Posix)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V184.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V184.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V184.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V184.Route.Route
    | SelectedFilesToAttach ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) Evergreen.V184.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) Evergreen.V184.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V184.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V184.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V184.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V184.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V184.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V184.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V184.NonemptyDict.NonemptyDict Int Evergreen.V184.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V184.NonemptyDict.NonemptyDict Int Evergreen.V184.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V184.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V184.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V184.Editable.Msg Evergreen.V184.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V184.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V184.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V184.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute ) (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRouteWithMessage Evergreen.V184.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V184.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V184.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V184.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V184.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId
        , otherUserId : Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V184.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRoute Evergreen.V184.MessageInput.Msg
    | MessageInputMsg Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRoute Evergreen.V184.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V184.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V184.MyUi.Range, Evergreen.V184.MyUi.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V184.MyUi.Range, Evergreen.V184.MyUi.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V184.Id.AnyGuildOrDmId Evergreen.V184.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V184.Id.Id Evergreen.V184.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V184.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V184.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V184.Untrusted.Untrusted Evergreen.V184.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V184.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V184.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V184.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.SecretId.SecretId Evergreen.V184.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V184.PersonName.PersonName Evergreen.V184.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V184.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V184.Slack.OAuthCode Evergreen.V184.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V184.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V184.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V184.Id.Id Evergreen.V184.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V184.EmailAddress.EmailAddress (Result Evergreen.V184.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V184.EmailAddress.EmailAddress (Result Evergreen.V184.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V184.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMaybeMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Result Evergreen.V184.Discord.HttpError Evergreen.V184.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V184.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Result Evergreen.V184.Discord.HttpError Evergreen.V184.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) (Result Evergreen.V184.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) (Result Evergreen.V184.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) (Result Evergreen.V184.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) (Result Evergreen.V184.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji (Result Evergreen.V184.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji (Result Evergreen.V184.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji (Result Evergreen.V184.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji (Result Evergreen.V184.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V184.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V184.Discord.HttpError (List ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId, Maybe Evergreen.V184.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V184.Slack.CurrentUser
            , team : Evergreen.V184.Slack.Team
            , users : List Evergreen.V184.Slack.User
            , channels : List ( Evergreen.V184.Slack.Channel, List Evergreen.V184.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Result Effect.Http.Error Evergreen.V184.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Discord.UserAuth (Result Evergreen.V184.Discord.HttpError Evergreen.V184.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Result Evergreen.V184.Discord.HttpError Evergreen.V184.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
        (Result
            Evergreen.V184.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId
                , members : List (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
                }
            , List
                ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId
                , { guild : Evergreen.V184.Discord.GatewayGuild
                  , channels : List Evergreen.V184.Discord.Channel
                  , icon : Maybe Evergreen.V184.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V184.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.AttachmentId, Evergreen.V184.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V184.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.AttachmentId, Evergreen.V184.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V184.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V184.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V184.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V184.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) (Result Evergreen.V184.Discord.HttpError (List Evergreen.V184.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Result Evergreen.V184.Discord.HttpError (List Evergreen.V184.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V184.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V184.DmChannel.DmChannelId Evergreen.V184.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V184.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V184.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V184.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
        (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V184.Discord.HttpError
            { guild : Evergreen.V184.Discord.GatewayGuild
            , channels : List Evergreen.V184.Discord.Channel
            , icon : Maybe Evergreen.V184.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Result Evergreen.V184.Discord.HttpError ()) Effect.Time.Posix
