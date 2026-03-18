module Evergreen.V158.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V158.AiChat
import Evergreen.V158.ChannelName
import Evergreen.V158.Coord
import Evergreen.V158.CssPixels
import Evergreen.V158.Discord
import Evergreen.V158.DiscordAttachmentId
import Evergreen.V158.DiscordUserData
import Evergreen.V158.DmChannel
import Evergreen.V158.Editable
import Evergreen.V158.EmailAddress
import Evergreen.V158.Emoji
import Evergreen.V158.FileStatus
import Evergreen.V158.GuildName
import Evergreen.V158.Id
import Evergreen.V158.ImageEditor
import Evergreen.V158.Local
import Evergreen.V158.LocalState
import Evergreen.V158.Log
import Evergreen.V158.LoginForm
import Evergreen.V158.Message
import Evergreen.V158.MessageInput
import Evergreen.V158.MessageView
import Evergreen.V158.NonemptyDict
import Evergreen.V158.NonemptySet
import Evergreen.V158.OneToOne
import Evergreen.V158.Pages.Admin
import Evergreen.V158.Pagination
import Evergreen.V158.PersonName
import Evergreen.V158.Ports
import Evergreen.V158.Postmark
import Evergreen.V158.RichText
import Evergreen.V158.Route
import Evergreen.V158.SecretId
import Evergreen.V158.SessionIdHash
import Evergreen.V158.Slack
import Evergreen.V158.TextEditor
import Evergreen.V158.Touch
import Evergreen.V158.TwoFactorAuthentication
import Evergreen.V158.Ui.Anim
import Evergreen.V158.User
import Evergreen.V158.UserAgent
import Evergreen.V158.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V158.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V158.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) Evergreen.V158.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.LocalState.DiscordFrontendGuild
    , user : Evergreen.V158.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V158.SessionIdHash.SessionIdHash Evergreen.V158.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V158.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V158.Route.Route
    , windowSize : Evergreen.V158.Coord.Coord Evergreen.V158.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V158.Ports.NotificationPermission
    , pwaStatus : Evergreen.V158.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V158.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V158.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V158.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))) Evergreen.V158.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V158.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))) Evergreen.V158.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) Evergreen.V158.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.UserSession.ToBeFilledInByBackend (Evergreen.V158.SecretId.SecretId Evergreen.V158.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V158.GuildName.GuildName (Evergreen.V158.UserSession.ToBeFilledInByBackend (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage Evergreen.V158.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage Evergreen.V158.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V158.Id.GuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))) (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V158.Id.DiscordGuildOrDmId_DmData (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V158.UserSession.SetViewing
    | Local_SetName Evergreen.V158.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V158.Id.GuildOrDmId (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V158.Id.GuildOrDmId (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V158.Id.DiscordGuildOrDmId (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V158.Id.DiscordGuildOrDmId (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V158.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V158.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V158.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V158.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Effect.Time.Posix Evergreen.V158.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))) Evergreen.V158.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V158.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))) Evergreen.V158.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) Evergreen.V158.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.SecretId.SecretId Evergreen.V158.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V158.LocalState.JoinGuildError
            { guildId : Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId
            , guild : Evergreen.V158.LocalState.FrontendGuild
            , owner : Evergreen.V158.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Id.GuildOrDmId Evergreen.V158.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Id.GuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage Evergreen.V158.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Id.GuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage Evergreen.V158.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage Evergreen.V158.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage Evergreen.V158.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Id.GuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))) (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V158.Id.DiscordGuildOrDmId_DmData (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V158.SessionIdHash.SessionIdHash Evergreen.V158.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V158.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V158.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V158.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.ChannelName.ChannelName (Evergreen.V158.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId)
        (Evergreen.V158.NonemptyDict.NonemptyDict
            (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) Evergreen.V158.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Maybe (Evergreen.V158.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V158.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V158.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V158.RichText.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V158.RichText.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V158.RichText.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V158.RichText.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) (Evergreen.V158.Discord.OptionalData String) (Evergreen.V158.Discord.OptionalData (Maybe String))


type LocalMsg
    = LocalChange (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) Evergreen.V158.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V158.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V158.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V158.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V158.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V158.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V158.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V158.Coord.Coord Evergreen.V158.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V158.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V158.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V158.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V158.Local.Local LocalMsg Evergreen.V158.LocalState.LocalState
    , admin : Evergreen.V158.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId, Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V158.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V158.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.NonemptyDict.NonemptyDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V158.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V158.TextEditor.Model
    , profilePictureEditor : Evergreen.V158.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V158.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V158.SecretId.SecretId Evergreen.V158.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V158.NonemptyDict.NonemptyDict Int Evergreen.V158.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V158.NonemptyDict.NonemptyDict Int Evergreen.V158.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V158.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V158.Coord.Coord Evergreen.V158.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V158.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V158.Ports.NotificationPermission
    , pwaStatus : Evergreen.V158.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V158.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V158.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V158.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V158.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V158.Coord.Coord Evergreen.V158.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V158.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V158.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V158.NonemptyDict.NonemptyDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V158.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V158.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V158.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V158.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V158.DmChannel.DmChannelId Evergreen.V158.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) Evergreen.V158.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V158.OneToOne.OneToOne (Evergreen.V158.Slack.Id Evergreen.V158.Slack.ChannelId) Evergreen.V158.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V158.OneToOne.OneToOne String (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    , slackUsers : Evergreen.V158.OneToOne.OneToOne (Evergreen.V158.Slack.Id Evergreen.V158.Slack.UserId) (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    , slackServers : Evergreen.V158.OneToOne.OneToOne (Evergreen.V158.Slack.Id Evergreen.V158.Slack.TeamId) (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    , slackToken : Maybe Evergreen.V158.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V158.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V158.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V158.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V158.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId, Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V158.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V158.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V158.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V158.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.LocalState.LoadingDiscordChannel (List Evergreen.V158.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V158.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V158.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V158.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V158.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) Evergreen.V158.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) Evergreen.V158.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V158.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V158.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Coord.Coord Evergreen.V158.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V158.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V158.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V158.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V158.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V158.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V158.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V158.NonemptyDict.NonemptyDict Int Evergreen.V158.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V158.NonemptyDict.NonemptyDict Int Evergreen.V158.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V158.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V158.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V158.Editable.Msg Evergreen.V158.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V158.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V158.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V158.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute ) (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRouteWithMessage Evergreen.V158.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V158.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V158.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V158.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V158.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId
        , otherUserId : Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V158.RichText.Domain
    | PressedContinueToSite


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V158.Id.AnyGuildOrDmId Evergreen.V158.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V158.Id.Id Evergreen.V158.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V158.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V158.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V158.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V158.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V158.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V158.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.SecretId.SecretId Evergreen.V158.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V158.PersonName.PersonName Evergreen.V158.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V158.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V158.Slack.OAuthCode Evergreen.V158.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V158.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V158.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V158.Id.Id Evergreen.V158.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V158.EmailAddress.EmailAddress (Result Evergreen.V158.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V158.EmailAddress.EmailAddress (Result Evergreen.V158.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V158.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMaybeMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Result Evergreen.V158.Discord.HttpError Evergreen.V158.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V158.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Result Evergreen.V158.Discord.HttpError Evergreen.V158.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) (Result Evergreen.V158.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) (Result Evergreen.V158.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) (Result Evergreen.V158.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) (Result Evergreen.V158.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji (Result Evergreen.V158.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji (Result Evergreen.V158.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji (Result Evergreen.V158.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji (Result Evergreen.V158.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V158.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V158.Discord.HttpError (List ( Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId, Maybe Evergreen.V158.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V158.Slack.CurrentUser
            , team : Evergreen.V158.Slack.Team
            , users : List Evergreen.V158.Slack.User
            , channels : List ( Evergreen.V158.Slack.Channel, List Evergreen.V158.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Result Effect.Http.Error Evergreen.V158.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Discord.UserAuth (Result Evergreen.V158.Discord.HttpError Evergreen.V158.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Result Evergreen.V158.Discord.HttpError Evergreen.V158.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
        (Result
            Evergreen.V158.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId
                , members : List (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
                }
            , List
                ( Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId
                , { guild : Evergreen.V158.Discord.GatewayGuild
                  , channels : List Evergreen.V158.Discord.Channel
                  , icon : Maybe Evergreen.V158.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V158.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V158.Discord.Id Evergreen.V158.Discord.AttachmentId, Evergreen.V158.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V158.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V158.Discord.Id Evergreen.V158.Discord.AttachmentId, Evergreen.V158.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V158.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V158.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V158.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V158.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) (Result Evergreen.V158.Discord.HttpError (List Evergreen.V158.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Result Evergreen.V158.Discord.HttpError (List Evergreen.V158.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V158.RichText.EmbedData )
    | GotDmMessageEmbed Evergreen.V158.DmChannel.DmChannelId Evergreen.V158.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V158.RichText.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V158.RichText.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V158.RichText.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
        (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V158.Discord.HttpError
            { guild : Evergreen.V158.Discord.GatewayGuild
            , channels : List Evergreen.V158.Discord.Channel
            , icon : Maybe Evergreen.V158.FileStatus.UploadResponse
            }
        )


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
    | AdminToFrontend Evergreen.V158.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V158.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V158.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V158.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V158.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V158.ImageEditor.ToFrontend
