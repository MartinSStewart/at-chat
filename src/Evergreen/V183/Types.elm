module Evergreen.V183.Types exposing (..)

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
import Evergreen.V183.AiChat
import Evergreen.V183.ChannelName
import Evergreen.V183.Coord
import Evergreen.V183.CssPixels
import Evergreen.V183.Discord
import Evergreen.V183.DiscordAttachmentId
import Evergreen.V183.DiscordUserData
import Evergreen.V183.DmChannel
import Evergreen.V183.Editable
import Evergreen.V183.EmailAddress
import Evergreen.V183.Embed
import Evergreen.V183.Emoji
import Evergreen.V183.FileStatus
import Evergreen.V183.GuildName
import Evergreen.V183.Id
import Evergreen.V183.ImageEditor
import Evergreen.V183.Local
import Evergreen.V183.LocalState
import Evergreen.V183.Log
import Evergreen.V183.LoginForm
import Evergreen.V183.MembersAndOwner
import Evergreen.V183.Message
import Evergreen.V183.MessageInput
import Evergreen.V183.MessageView
import Evergreen.V183.MyUi
import Evergreen.V183.NonemptyDict
import Evergreen.V183.NonemptySet
import Evergreen.V183.OneToOne
import Evergreen.V183.Pages.Admin
import Evergreen.V183.Pagination
import Evergreen.V183.PersonName
import Evergreen.V183.Ports
import Evergreen.V183.Postmark
import Evergreen.V183.RichText
import Evergreen.V183.Route
import Evergreen.V183.SecretId
import Evergreen.V183.SessionIdHash
import Evergreen.V183.Slack
import Evergreen.V183.TextEditor
import Evergreen.V183.Touch
import Evergreen.V183.TwoFactorAuthentication
import Evergreen.V183.Ui.Anim
import Evergreen.V183.Untrusted
import Evergreen.V183.User
import Evergreen.V183.UserAgent
import Evergreen.V183.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V183.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V183.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) Evergreen.V183.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.LocalState.DiscordFrontendGuild
    , user : Evergreen.V183.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V183.SessionIdHash.SessionIdHash Evergreen.V183.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V183.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V183.Route.Route
    , windowSize : Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V183.Ports.NotificationPermission
    , pwaStatus : Evergreen.V183.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V183.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V183.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V183.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))) Evergreen.V183.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V183.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))) Evergreen.V183.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) Evergreen.V183.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.UserSession.ToBeFilledInByBackend (Evergreen.V183.SecretId.SecretId Evergreen.V183.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V183.GuildName.GuildName (Evergreen.V183.UserSession.ToBeFilledInByBackend (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage Evergreen.V183.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage Evergreen.V183.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V183.Id.GuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))) (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V183.Id.DiscordGuildOrDmId_DmData (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V183.UserSession.SetViewing
    | Local_SetName Evergreen.V183.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V183.Id.GuildOrDmId (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V183.Id.GuildOrDmId (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V183.Id.DiscordGuildOrDmId (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V183.Id.DiscordGuildOrDmId (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V183.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V183.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V183.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V183.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V183.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V183.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Effect.Time.Posix Evergreen.V183.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))) Evergreen.V183.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V183.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))) Evergreen.V183.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) Evergreen.V183.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.SecretId.SecretId Evergreen.V183.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V183.LocalState.JoinGuildError
            { guildId : Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId
            , guild : Evergreen.V183.LocalState.FrontendGuild
            , owner : Evergreen.V183.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Id.GuildOrDmId Evergreen.V183.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Id.GuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage Evergreen.V183.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Id.GuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage Evergreen.V183.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage Evergreen.V183.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage Evergreen.V183.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Id.GuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))) (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V183.Id.DiscordGuildOrDmId_DmData (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V183.SessionIdHash.SessionIdHash Evergreen.V183.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V183.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V183.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V183.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.ChannelName.ChannelName (Evergreen.V183.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId)
        (Evergreen.V183.NonemptyDict.NonemptyDict
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) Evergreen.V183.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Maybe (Evergreen.V183.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V183.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V183.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V183.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V183.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V183.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V183.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) (Evergreen.V183.Discord.OptionalData String) (Evergreen.V183.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
        (Evergreen.V183.MembersAndOwner.MembersAndOwner
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.PersonName.PersonName


type LocalMsg
    = LocalChange (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) Evergreen.V183.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V183.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V183.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V183.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V183.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V183.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V183.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V183.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V183.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V183.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels) (Maybe Evergreen.V183.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V183.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V183.Local.Local LocalMsg Evergreen.V183.LocalState.LocalState
    , admin : Evergreen.V183.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId, Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V183.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V183.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V183.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.NonemptyDict.NonemptyDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V183.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V183.TextEditor.Model
    , profilePictureEditor : Evergreen.V183.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V183.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V183.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V183.SecretId.SecretId Evergreen.V183.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V183.MyUi.Range
                , direction : Evergreen.V183.MyUi.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V183.NonemptyDict.NonemptyDict Int Evergreen.V183.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V183.NonemptyDict.NonemptyDict Int Evergreen.V183.Touch.Touch
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
    | AdminToFrontend Evergreen.V183.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V183.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V183.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V183.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V183.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V183.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V183.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V183.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V183.Ports.NotificationPermission
    , pwaStatus : Evergreen.V183.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V183.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V183.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V183.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V183.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V183.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V183.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V183.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId, Evergreen.V183.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V183.DmChannel.DmChannelId, Evergreen.V183.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId, Evergreen.V183.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId, Evergreen.V183.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V183.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V183.NonemptyDict.NonemptyDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V183.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V183.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V183.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V183.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V183.DmChannel.DmChannelId Evergreen.V183.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) Evergreen.V183.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V183.OneToOne.OneToOne (Evergreen.V183.Slack.Id Evergreen.V183.Slack.ChannelId) Evergreen.V183.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V183.OneToOne.OneToOne String (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    , slackUsers : Evergreen.V183.OneToOne.OneToOne (Evergreen.V183.Slack.Id Evergreen.V183.Slack.UserId) (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
    , slackServers : Evergreen.V183.OneToOne.OneToOne (Evergreen.V183.Slack.Id Evergreen.V183.Slack.TeamId) (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    , slackToken : Maybe Evergreen.V183.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V183.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V183.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V183.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V183.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId, Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V183.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V183.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V183.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V183.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.LocalState.LoadingDiscordChannel (List Evergreen.V183.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Array.Array Effect.Time.Posix)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V183.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V183.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V183.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V183.Route.Route
    | SelectedFilesToAttach ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) Evergreen.V183.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) Evergreen.V183.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V183.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V183.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V183.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V183.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V183.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V183.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V183.NonemptyDict.NonemptyDict Int Evergreen.V183.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V183.NonemptyDict.NonemptyDict Int Evergreen.V183.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V183.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V183.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V183.Editable.Msg Evergreen.V183.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V183.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V183.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V183.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute ) (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRouteWithMessage Evergreen.V183.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V183.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V183.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V183.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V183.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId
        , otherUserId : Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V183.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRoute Evergreen.V183.MessageInput.Msg
    | MessageInputMsg Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRoute Evergreen.V183.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V183.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V183.MyUi.Range, Evergreen.V183.MyUi.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V183.MyUi.Range, Evergreen.V183.MyUi.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V183.Id.AnyGuildOrDmId Evergreen.V183.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V183.Id.Id Evergreen.V183.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V183.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V183.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V183.Untrusted.Untrusted Evergreen.V183.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V183.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V183.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V183.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.SecretId.SecretId Evergreen.V183.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V183.PersonName.PersonName Evergreen.V183.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V183.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V183.Slack.OAuthCode Evergreen.V183.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V183.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V183.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V183.Id.Id Evergreen.V183.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V183.EmailAddress.EmailAddress (Result Evergreen.V183.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V183.EmailAddress.EmailAddress (Result Evergreen.V183.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V183.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMaybeMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Result Evergreen.V183.Discord.HttpError Evergreen.V183.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V183.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Result Evergreen.V183.Discord.HttpError Evergreen.V183.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) (Result Evergreen.V183.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) (Result Evergreen.V183.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) (Result Evergreen.V183.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) (Result Evergreen.V183.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji (Result Evergreen.V183.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji (Result Evergreen.V183.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji (Result Evergreen.V183.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji (Result Evergreen.V183.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V183.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V183.Discord.HttpError (List ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId, Maybe Evergreen.V183.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V183.Slack.CurrentUser
            , team : Evergreen.V183.Slack.Team
            , users : List Evergreen.V183.Slack.User
            , channels : List ( Evergreen.V183.Slack.Channel, List Evergreen.V183.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Result Effect.Http.Error Evergreen.V183.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Discord.UserAuth (Result Evergreen.V183.Discord.HttpError Evergreen.V183.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Result Evergreen.V183.Discord.HttpError Evergreen.V183.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
        (Result
            Evergreen.V183.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId
                , members : List (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
                }
            , List
                ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId
                , { guild : Evergreen.V183.Discord.GatewayGuild
                  , channels : List Evergreen.V183.Discord.Channel
                  , icon : Maybe Evergreen.V183.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V183.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.AttachmentId, Evergreen.V183.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V183.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.AttachmentId, Evergreen.V183.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V183.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V183.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V183.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V183.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) (Result Evergreen.V183.Discord.HttpError (List Evergreen.V183.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Result Evergreen.V183.Discord.HttpError (List Evergreen.V183.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V183.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V183.DmChannel.DmChannelId Evergreen.V183.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V183.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V183.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V183.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
        (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V183.Discord.HttpError
            { guild : Evergreen.V183.Discord.GatewayGuild
            , channels : List Evergreen.V183.Discord.Channel
            , icon : Maybe Evergreen.V183.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Result Evergreen.V183.Discord.HttpError ()) Effect.Time.Posix
