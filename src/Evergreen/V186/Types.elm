module Evergreen.V186.Types exposing (..)

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
import Evergreen.V186.AiChat
import Evergreen.V186.ChannelName
import Evergreen.V186.Coord
import Evergreen.V186.CssPixels
import Evergreen.V186.Discord
import Evergreen.V186.DiscordAttachmentId
import Evergreen.V186.DiscordUserData
import Evergreen.V186.DmChannel
import Evergreen.V186.Editable
import Evergreen.V186.EmailAddress
import Evergreen.V186.Embed
import Evergreen.V186.Emoji
import Evergreen.V186.FileStatus
import Evergreen.V186.GuildName
import Evergreen.V186.Id
import Evergreen.V186.ImageEditor
import Evergreen.V186.Local
import Evergreen.V186.LocalState
import Evergreen.V186.Log
import Evergreen.V186.LoginForm
import Evergreen.V186.MembersAndOwner
import Evergreen.V186.Message
import Evergreen.V186.MessageInput
import Evergreen.V186.MessageView
import Evergreen.V186.MyUi
import Evergreen.V186.NonemptyDict
import Evergreen.V186.NonemptySet
import Evergreen.V186.OneToOne
import Evergreen.V186.Pages.Admin
import Evergreen.V186.Pagination
import Evergreen.V186.PersonName
import Evergreen.V186.Ports
import Evergreen.V186.Postmark
import Evergreen.V186.RichText
import Evergreen.V186.Route
import Evergreen.V186.SecretId
import Evergreen.V186.SessionIdHash
import Evergreen.V186.Slack
import Evergreen.V186.TextEditor
import Evergreen.V186.Touch
import Evergreen.V186.TwoFactorAuthentication
import Evergreen.V186.Ui.Anim
import Evergreen.V186.Untrusted
import Evergreen.V186.User
import Evergreen.V186.UserAgent
import Evergreen.V186.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V186.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V186.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) Evergreen.V186.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.LocalState.DiscordFrontendGuild
    , user : Evergreen.V186.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V186.SessionIdHash.SessionIdHash Evergreen.V186.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V186.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V186.Route.Route
    , windowSize : Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V186.Ports.NotificationPermission
    , pwaStatus : Evergreen.V186.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V186.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V186.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V186.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))) Evergreen.V186.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V186.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))) Evergreen.V186.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) Evergreen.V186.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.UserSession.ToBeFilledInByBackend (Evergreen.V186.SecretId.SecretId Evergreen.V186.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V186.GuildName.GuildName (Evergreen.V186.UserSession.ToBeFilledInByBackend (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage Evergreen.V186.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage Evergreen.V186.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V186.Id.GuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))) (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V186.Id.DiscordGuildOrDmId_DmData (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V186.UserSession.SetViewing
    | Local_SetName Evergreen.V186.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V186.Id.GuildOrDmId (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V186.Id.GuildOrDmId (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V186.Id.DiscordGuildOrDmId (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V186.Id.DiscordGuildOrDmId (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V186.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V186.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V186.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V186.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V186.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V186.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Effect.Time.Posix Evergreen.V186.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))) Evergreen.V186.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V186.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))) Evergreen.V186.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) Evergreen.V186.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.SecretId.SecretId Evergreen.V186.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V186.LocalState.JoinGuildError
            { guildId : Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId
            , guild : Evergreen.V186.LocalState.FrontendGuild
            , owner : Evergreen.V186.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Id.GuildOrDmId Evergreen.V186.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Id.GuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage Evergreen.V186.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Id.GuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage Evergreen.V186.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage Evergreen.V186.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage Evergreen.V186.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Id.GuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))) (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V186.Id.DiscordGuildOrDmId_DmData (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V186.SessionIdHash.SessionIdHash Evergreen.V186.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V186.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V186.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V186.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.ChannelName.ChannelName (Evergreen.V186.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId)
        (Evergreen.V186.NonemptyDict.NonemptyDict
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) Evergreen.V186.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Maybe (Evergreen.V186.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V186.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V186.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V186.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V186.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V186.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V186.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) (Evergreen.V186.Discord.OptionalData String) (Evergreen.V186.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
        (Evergreen.V186.MembersAndOwner.MembersAndOwner
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.PersonName.PersonName


type LocalMsg
    = LocalChange (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) Evergreen.V186.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V186.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V186.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V186.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V186.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V186.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V186.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V186.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V186.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V186.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels) (Maybe Evergreen.V186.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V186.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V186.Local.Local LocalMsg Evergreen.V186.LocalState.LocalState
    , admin : Evergreen.V186.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId, Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V186.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V186.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V186.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.NonemptyDict.NonemptyDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V186.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V186.TextEditor.Model
    , profilePictureEditor : Evergreen.V186.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V186.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V186.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V186.SecretId.SecretId Evergreen.V186.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V186.MyUi.Range
                , direction : Evergreen.V186.MyUi.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V186.NonemptyDict.NonemptyDict Int Evergreen.V186.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V186.NonemptyDict.NonemptyDict Int Evergreen.V186.Touch.Touch
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
    | AdminToFrontend Evergreen.V186.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V186.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V186.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V186.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V186.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V186.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V186.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V186.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V186.Ports.NotificationPermission
    , pwaStatus : Evergreen.V186.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V186.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V186.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V186.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V186.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V186.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V186.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V186.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId, Evergreen.V186.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V186.DmChannel.DmChannelId, Evergreen.V186.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId, Evergreen.V186.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId, Evergreen.V186.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V186.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V186.NonemptyDict.NonemptyDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V186.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V186.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V186.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V186.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V186.DmChannel.DmChannelId Evergreen.V186.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) Evergreen.V186.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V186.OneToOne.OneToOne (Evergreen.V186.Slack.Id Evergreen.V186.Slack.ChannelId) Evergreen.V186.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V186.OneToOne.OneToOne String (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    , slackUsers : Evergreen.V186.OneToOne.OneToOne (Evergreen.V186.Slack.Id Evergreen.V186.Slack.UserId) (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
    , slackServers : Evergreen.V186.OneToOne.OneToOne (Evergreen.V186.Slack.Id Evergreen.V186.Slack.TeamId) (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    , slackToken : Maybe Evergreen.V186.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V186.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V186.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V186.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V186.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId, Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V186.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V186.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V186.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V186.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.LocalState.LoadingDiscordChannel (List Evergreen.V186.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Array.Array Effect.Time.Posix)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V186.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V186.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V186.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V186.Route.Route
    | SelectedFilesToAttach ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) Evergreen.V186.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) Evergreen.V186.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V186.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V186.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V186.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V186.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V186.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V186.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V186.NonemptyDict.NonemptyDict Int Evergreen.V186.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V186.NonemptyDict.NonemptyDict Int Evergreen.V186.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V186.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V186.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V186.Editable.Msg Evergreen.V186.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V186.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V186.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V186.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute ) (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRouteWithMessage Evergreen.V186.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V186.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V186.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V186.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V186.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId
        , otherUserId : Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V186.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRoute Evergreen.V186.MessageInput.Msg
    | MessageInputMsg Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRoute Evergreen.V186.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V186.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V186.MyUi.Range, Evergreen.V186.MyUi.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V186.MyUi.Range, Evergreen.V186.MyUi.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V186.Id.AnyGuildOrDmId Evergreen.V186.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V186.Id.Id Evergreen.V186.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V186.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V186.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V186.Untrusted.Untrusted Evergreen.V186.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V186.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V186.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V186.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.SecretId.SecretId Evergreen.V186.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V186.PersonName.PersonName Evergreen.V186.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V186.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V186.Slack.OAuthCode Evergreen.V186.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V186.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V186.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V186.Id.Id Evergreen.V186.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V186.EmailAddress.EmailAddress (Result Evergreen.V186.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V186.EmailAddress.EmailAddress (Result Evergreen.V186.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V186.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMaybeMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Result Evergreen.V186.Discord.HttpError Evergreen.V186.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V186.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Result Evergreen.V186.Discord.HttpError Evergreen.V186.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) (Result Evergreen.V186.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) (Result Evergreen.V186.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) (Result Evergreen.V186.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) (Result Evergreen.V186.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji (Result Evergreen.V186.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji (Result Evergreen.V186.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji (Result Evergreen.V186.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji (Result Evergreen.V186.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V186.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V186.Discord.HttpError (List ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId, Maybe Evergreen.V186.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V186.Slack.CurrentUser
            , team : Evergreen.V186.Slack.Team
            , users : List Evergreen.V186.Slack.User
            , channels : List ( Evergreen.V186.Slack.Channel, List Evergreen.V186.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Result Effect.Http.Error Evergreen.V186.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Discord.UserAuth (Result Evergreen.V186.Discord.HttpError Evergreen.V186.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Result Evergreen.V186.Discord.HttpError Evergreen.V186.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
        (Result
            Evergreen.V186.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId
                , members : List (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
                }
            , List
                ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId
                , { guild : Evergreen.V186.Discord.GatewayGuild
                  , channels : List Evergreen.V186.Discord.Channel
                  , icon : Maybe Evergreen.V186.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V186.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.AttachmentId, Evergreen.V186.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V186.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.AttachmentId, Evergreen.V186.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V186.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V186.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V186.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V186.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) (Result Evergreen.V186.Discord.HttpError (List Evergreen.V186.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Result Evergreen.V186.Discord.HttpError (List Evergreen.V186.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V186.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V186.DmChannel.DmChannelId Evergreen.V186.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V186.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V186.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V186.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
        (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V186.Discord.HttpError
            { guild : Evergreen.V186.Discord.GatewayGuild
            , channels : List Evergreen.V186.Discord.Channel
            , icon : Maybe Evergreen.V186.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Result Evergreen.V186.Discord.HttpError ()) Effect.Time.Posix
