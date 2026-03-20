module Evergreen.V160.Types exposing (..)

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
import Evergreen.V160.AiChat
import Evergreen.V160.ChannelName
import Evergreen.V160.Coord
import Evergreen.V160.CssPixels
import Evergreen.V160.Discord
import Evergreen.V160.DiscordAttachmentId
import Evergreen.V160.DiscordUserData
import Evergreen.V160.DmChannel
import Evergreen.V160.Editable
import Evergreen.V160.EmailAddress
import Evergreen.V160.Emoji
import Evergreen.V160.FileStatus
import Evergreen.V160.GuildName
import Evergreen.V160.Id
import Evergreen.V160.ImageEditor
import Evergreen.V160.Local
import Evergreen.V160.LocalState
import Evergreen.V160.Log
import Evergreen.V160.LoginForm
import Evergreen.V160.Message
import Evergreen.V160.MessageInput
import Evergreen.V160.MessageView
import Evergreen.V160.NonemptyDict
import Evergreen.V160.NonemptySet
import Evergreen.V160.OneToOne
import Evergreen.V160.Pages.Admin
import Evergreen.V160.Pagination
import Evergreen.V160.PersonName
import Evergreen.V160.Ports
import Evergreen.V160.Postmark
import Evergreen.V160.RichText
import Evergreen.V160.Route
import Evergreen.V160.SecretId
import Evergreen.V160.SessionIdHash
import Evergreen.V160.Slack
import Evergreen.V160.TextEditor
import Evergreen.V160.Touch
import Evergreen.V160.TwoFactorAuthentication
import Evergreen.V160.Ui.Anim
import Evergreen.V160.User
import Evergreen.V160.UserAgent
import Evergreen.V160.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V160.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V160.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) Evergreen.V160.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.LocalState.DiscordFrontendGuild
    , user : Evergreen.V160.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V160.SessionIdHash.SessionIdHash Evergreen.V160.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V160.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V160.Route.Route
    , windowSize : Evergreen.V160.Coord.Coord Evergreen.V160.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V160.Ports.NotificationPermission
    , pwaStatus : Evergreen.V160.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V160.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V160.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V160.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))) Evergreen.V160.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V160.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))) Evergreen.V160.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) Evergreen.V160.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.UserSession.ToBeFilledInByBackend (Evergreen.V160.SecretId.SecretId Evergreen.V160.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V160.GuildName.GuildName (Evergreen.V160.UserSession.ToBeFilledInByBackend (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage Evergreen.V160.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage Evergreen.V160.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V160.Id.GuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))) (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V160.Id.DiscordGuildOrDmId_DmData (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V160.UserSession.SetViewing
    | Local_SetName Evergreen.V160.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V160.Id.GuildOrDmId (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V160.Id.GuildOrDmId (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V160.Id.DiscordGuildOrDmId (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V160.Id.DiscordGuildOrDmId (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V160.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V160.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V160.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V160.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Effect.Time.Posix Evergreen.V160.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))) Evergreen.V160.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V160.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))) Evergreen.V160.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) Evergreen.V160.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.SecretId.SecretId Evergreen.V160.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V160.LocalState.JoinGuildError
            { guildId : Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId
            , guild : Evergreen.V160.LocalState.FrontendGuild
            , owner : Evergreen.V160.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Id.GuildOrDmId Evergreen.V160.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Id.GuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage Evergreen.V160.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Id.GuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage Evergreen.V160.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage Evergreen.V160.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage Evergreen.V160.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Id.GuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))) (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V160.Id.DiscordGuildOrDmId_DmData (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V160.SessionIdHash.SessionIdHash Evergreen.V160.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V160.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V160.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V160.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.ChannelName.ChannelName (Evergreen.V160.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId)
        (Evergreen.V160.NonemptyDict.NonemptyDict
            (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) Evergreen.V160.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Maybe (Evergreen.V160.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V160.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V160.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V160.RichText.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V160.RichText.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V160.RichText.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V160.RichText.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) (Evergreen.V160.Discord.OptionalData String) (Evergreen.V160.Discord.OptionalData (Maybe String))


type LocalMsg
    = LocalChange (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) Evergreen.V160.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V160.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V160.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V160.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V160.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V160.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V160.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V160.Coord.Coord Evergreen.V160.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V160.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V160.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V160.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V160.Local.Local LocalMsg Evergreen.V160.LocalState.LocalState
    , admin : Evergreen.V160.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId, Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V160.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V160.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.NonemptyDict.NonemptyDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V160.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V160.TextEditor.Model
    , profilePictureEditor : Evergreen.V160.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V160.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V160.SecretId.SecretId Evergreen.V160.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V160.NonemptyDict.NonemptyDict Int Evergreen.V160.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V160.NonemptyDict.NonemptyDict Int Evergreen.V160.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V160.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V160.Coord.Coord Evergreen.V160.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V160.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V160.Ports.NotificationPermission
    , pwaStatus : Evergreen.V160.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V160.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V160.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V160.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V160.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V160.Coord.Coord Evergreen.V160.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V160.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V160.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V160.NonemptyDict.NonemptyDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V160.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V160.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V160.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V160.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V160.DmChannel.DmChannelId Evergreen.V160.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) Evergreen.V160.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V160.OneToOne.OneToOne (Evergreen.V160.Slack.Id Evergreen.V160.Slack.ChannelId) Evergreen.V160.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V160.OneToOne.OneToOne String (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    , slackUsers : Evergreen.V160.OneToOne.OneToOne (Evergreen.V160.Slack.Id Evergreen.V160.Slack.UserId) (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    , slackServers : Evergreen.V160.OneToOne.OneToOne (Evergreen.V160.Slack.Id Evergreen.V160.Slack.TeamId) (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    , slackToken : Maybe Evergreen.V160.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V160.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V160.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V160.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V160.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId, Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V160.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V160.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V160.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V160.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.LocalState.LoadingDiscordChannel (List Evergreen.V160.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V160.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V160.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V160.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V160.Route.Route
    | SelectedFilesToAttach ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) Evergreen.V160.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) Evergreen.V160.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V160.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Coord.Coord Evergreen.V160.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V160.Emoji.Emoji
    | MessageMenu_PressedReply Evergreen.V160.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V160.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V160.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V160.NonemptyDict.NonemptyDict Int Evergreen.V160.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V160.NonemptyDict.NonemptyDict Int Evergreen.V160.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V160.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V160.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V160.Editable.Msg Evergreen.V160.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V160.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V160.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V160.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute ) (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRouteWithMessage Evergreen.V160.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V160.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V160.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V160.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V160.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId
        , otherUserId : Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V160.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRoute Evergreen.V160.MessageInput.Msg
    | MessageInputMsg Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRoute Evergreen.V160.MessageInput.Msg


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V160.Id.AnyGuildOrDmId Evergreen.V160.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V160.Id.Id Evergreen.V160.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V160.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V160.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V160.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V160.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V160.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V160.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.SecretId.SecretId Evergreen.V160.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V160.PersonName.PersonName Evergreen.V160.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V160.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V160.Slack.OAuthCode Evergreen.V160.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V160.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V160.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V160.Id.Id Evergreen.V160.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V160.EmailAddress.EmailAddress (Result Evergreen.V160.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V160.EmailAddress.EmailAddress (Result Evergreen.V160.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V160.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMaybeMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Result Evergreen.V160.Discord.HttpError Evergreen.V160.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V160.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Result Evergreen.V160.Discord.HttpError Evergreen.V160.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) (Result Evergreen.V160.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) (Result Evergreen.V160.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) (Result Evergreen.V160.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) (Result Evergreen.V160.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji (Result Evergreen.V160.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji (Result Evergreen.V160.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji (Result Evergreen.V160.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji (Result Evergreen.V160.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V160.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V160.Discord.HttpError (List ( Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId, Maybe Evergreen.V160.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V160.Slack.CurrentUser
            , team : Evergreen.V160.Slack.Team
            , users : List Evergreen.V160.Slack.User
            , channels : List ( Evergreen.V160.Slack.Channel, List Evergreen.V160.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Result Effect.Http.Error Evergreen.V160.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Discord.UserAuth (Result Evergreen.V160.Discord.HttpError Evergreen.V160.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Result Evergreen.V160.Discord.HttpError Evergreen.V160.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
        (Result
            Evergreen.V160.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId
                , members : List (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
                }
            , List
                ( Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId
                , { guild : Evergreen.V160.Discord.GatewayGuild
                  , channels : List Evergreen.V160.Discord.Channel
                  , icon : Maybe Evergreen.V160.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V160.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V160.Discord.Id Evergreen.V160.Discord.AttachmentId, Evergreen.V160.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V160.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V160.Discord.Id Evergreen.V160.Discord.AttachmentId, Evergreen.V160.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V160.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V160.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V160.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V160.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) (Result Evergreen.V160.Discord.HttpError (List Evergreen.V160.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Result Evergreen.V160.Discord.HttpError (List Evergreen.V160.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V160.RichText.EmbedData )
    | GotDmMessageEmbed Evergreen.V160.DmChannel.DmChannelId Evergreen.V160.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V160.RichText.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V160.RichText.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V160.RichText.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
        (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V160.Discord.HttpError
            { guild : Evergreen.V160.Discord.GatewayGuild
            , channels : List Evergreen.V160.Discord.Channel
            , icon : Maybe Evergreen.V160.FileStatus.UploadResponse
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
    | AdminToFrontend Evergreen.V160.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V160.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V160.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V160.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V160.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V160.ImageEditor.ToFrontend
