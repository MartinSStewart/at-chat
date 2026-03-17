module Evergreen.V157.Types exposing (..)

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
import Evergreen.V157.AiChat
import Evergreen.V157.ChannelName
import Evergreen.V157.Coord
import Evergreen.V157.CssPixels
import Evergreen.V157.Discord
import Evergreen.V157.DiscordAttachmentId
import Evergreen.V157.DiscordUserData
import Evergreen.V157.DmChannel
import Evergreen.V157.Editable
import Evergreen.V157.EmailAddress
import Evergreen.V157.Emoji
import Evergreen.V157.FileStatus
import Evergreen.V157.GuildName
import Evergreen.V157.Id
import Evergreen.V157.ImageEditor
import Evergreen.V157.Local
import Evergreen.V157.LocalState
import Evergreen.V157.Log
import Evergreen.V157.LoginForm
import Evergreen.V157.Message
import Evergreen.V157.MessageInput
import Evergreen.V157.MessageView
import Evergreen.V157.NonemptyDict
import Evergreen.V157.NonemptySet
import Evergreen.V157.OneToOne
import Evergreen.V157.Pages.Admin
import Evergreen.V157.Pagination
import Evergreen.V157.PersonName
import Evergreen.V157.Ports
import Evergreen.V157.Postmark
import Evergreen.V157.RichText
import Evergreen.V157.Route
import Evergreen.V157.SecretId
import Evergreen.V157.SessionIdHash
import Evergreen.V157.Slack
import Evergreen.V157.TextEditor
import Evergreen.V157.Touch
import Evergreen.V157.TwoFactorAuthentication
import Evergreen.V157.Ui.Anim
import Evergreen.V157.User
import Evergreen.V157.UserAgent
import Evergreen.V157.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V157.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V157.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) Evergreen.V157.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.LocalState.DiscordFrontendGuild
    , user : Evergreen.V157.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V157.SessionIdHash.SessionIdHash Evergreen.V157.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V157.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V157.Route.Route
    , windowSize : Evergreen.V157.Coord.Coord Evergreen.V157.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V157.Ports.NotificationPermission
    , pwaStatus : Evergreen.V157.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V157.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V157.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V157.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))) Evergreen.V157.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V157.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))) Evergreen.V157.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) Evergreen.V157.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.UserSession.ToBeFilledInByBackend (Evergreen.V157.SecretId.SecretId Evergreen.V157.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V157.GuildName.GuildName (Evergreen.V157.UserSession.ToBeFilledInByBackend (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage Evergreen.V157.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage Evergreen.V157.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V157.Id.GuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))) (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V157.Id.DiscordGuildOrDmId_DmData (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V157.UserSession.SetViewing
    | Local_SetName Evergreen.V157.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V157.Id.GuildOrDmId (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V157.Id.GuildOrDmId (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V157.Id.DiscordGuildOrDmId (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V157.Id.DiscordGuildOrDmId (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V157.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V157.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V157.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V157.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Effect.Time.Posix Evergreen.V157.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))) Evergreen.V157.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V157.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))) Evergreen.V157.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) Evergreen.V157.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.SecretId.SecretId Evergreen.V157.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V157.LocalState.JoinGuildError
            { guildId : Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId
            , guild : Evergreen.V157.LocalState.FrontendGuild
            , owner : Evergreen.V157.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Id.GuildOrDmId Evergreen.V157.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Id.GuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage Evergreen.V157.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Id.GuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage Evergreen.V157.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage Evergreen.V157.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage Evergreen.V157.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Id.GuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))) (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V157.Id.DiscordGuildOrDmId_DmData (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V157.SessionIdHash.SessionIdHash Evergreen.V157.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V157.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V157.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V157.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.ChannelName.ChannelName (Evergreen.V157.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId)
        (Evergreen.V157.NonemptyDict.NonemptyDict
            (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) Evergreen.V157.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Maybe (Evergreen.V157.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V157.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V157.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage ( Int, Result () Evergreen.V157.RichText.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Id.ThreadRouteWithMessage ( Int, Result () Evergreen.V157.RichText.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage ( Int, Result () Evergreen.V157.RichText.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) ( Int, Result () Evergreen.V157.RichText.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) (Evergreen.V157.Discord.OptionalData String) (Evergreen.V157.Discord.OptionalData (Maybe String))


type LocalMsg
    = LocalChange (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) Evergreen.V157.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V157.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V157.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V157.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V157.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V157.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V157.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V157.Coord.Coord Evergreen.V157.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V157.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V157.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V157.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V157.Local.Local LocalMsg Evergreen.V157.LocalState.LocalState
    , admin : Evergreen.V157.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId, Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V157.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V157.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.NonemptyDict.NonemptyDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V157.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V157.TextEditor.Model
    , profilePictureEditor : Evergreen.V157.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V157.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V157.SecretId.SecretId Evergreen.V157.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V157.NonemptyDict.NonemptyDict Int Evergreen.V157.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V157.NonemptyDict.NonemptyDict Int Evergreen.V157.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V157.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V157.Coord.Coord Evergreen.V157.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V157.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V157.Ports.NotificationPermission
    , pwaStatus : Evergreen.V157.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V157.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V157.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V157.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V157.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V157.Coord.Coord Evergreen.V157.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V157.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V157.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V157.NonemptyDict.NonemptyDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V157.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V157.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V157.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V157.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V157.DmChannel.DmChannelId Evergreen.V157.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) Evergreen.V157.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V157.OneToOne.OneToOne (Evergreen.V157.Slack.Id Evergreen.V157.Slack.ChannelId) Evergreen.V157.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V157.OneToOne.OneToOne String (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    , slackUsers : Evergreen.V157.OneToOne.OneToOne (Evergreen.V157.Slack.Id Evergreen.V157.Slack.UserId) (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    , slackServers : Evergreen.V157.OneToOne.OneToOne (Evergreen.V157.Slack.Id Evergreen.V157.Slack.TeamId) (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    , slackToken : Maybe Evergreen.V157.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V157.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V157.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V157.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V157.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId, Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V157.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V157.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V157.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V157.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.LocalState.LoadingDiscordChannel (List Evergreen.V157.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V157.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V157.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V157.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V157.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) Evergreen.V157.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) Evergreen.V157.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V157.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V157.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Coord.Coord Evergreen.V157.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V157.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V157.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V157.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V157.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V157.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V157.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V157.NonemptyDict.NonemptyDict Int Evergreen.V157.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V157.NonemptyDict.NonemptyDict Int Evergreen.V157.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V157.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V157.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V157.Editable.Msg Evergreen.V157.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V157.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V157.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V157.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute ) (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRouteWithMessage Evergreen.V157.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V157.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V157.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V157.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V157.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId
        , otherUserId : Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V157.RichText.Domain
    | PressedContinueToSite


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V157.Id.AnyGuildOrDmId Evergreen.V157.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V157.Id.Id Evergreen.V157.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V157.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V157.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V157.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V157.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V157.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V157.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.SecretId.SecretId Evergreen.V157.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V157.PersonName.PersonName Evergreen.V157.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V157.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V157.Slack.OAuthCode Evergreen.V157.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V157.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V157.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V157.Id.Id Evergreen.V157.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V157.EmailAddress.EmailAddress (Result Evergreen.V157.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V157.EmailAddress.EmailAddress (Result Evergreen.V157.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V157.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMaybeMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Result Evergreen.V157.Discord.HttpError Evergreen.V157.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V157.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Result Evergreen.V157.Discord.HttpError Evergreen.V157.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) (Result Evergreen.V157.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) (Result Evergreen.V157.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) (Result Evergreen.V157.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) (Result Evergreen.V157.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji (Result Evergreen.V157.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji (Result Evergreen.V157.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji (Result Evergreen.V157.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji (Result Evergreen.V157.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V157.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V157.Discord.HttpError (List ( Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId, Maybe Evergreen.V157.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V157.Slack.CurrentUser
            , team : Evergreen.V157.Slack.Team
            , users : List Evergreen.V157.Slack.User
            , channels : List ( Evergreen.V157.Slack.Channel, List Evergreen.V157.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Result Effect.Http.Error Evergreen.V157.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Discord.UserAuth (Result Evergreen.V157.Discord.HttpError Evergreen.V157.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Result Evergreen.V157.Discord.HttpError Evergreen.V157.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
        (Result
            Evergreen.V157.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId
                , members : List (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
                }
            , List
                ( Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId
                , { guild : Evergreen.V157.Discord.GatewayGuild
                  , channels : List Evergreen.V157.Discord.Channel
                  , icon : Maybe Evergreen.V157.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V157.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V157.Discord.Id Evergreen.V157.Discord.AttachmentId, Evergreen.V157.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V157.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V157.Discord.Id Evergreen.V157.Discord.AttachmentId, Evergreen.V157.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V157.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V157.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V157.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V157.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) (Result Evergreen.V157.Discord.HttpError (List Evergreen.V157.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Result Evergreen.V157.Discord.HttpError (List Evergreen.V157.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage ( Int, Result Effect.Http.Error Evergreen.V157.RichText.EmbedData )
    | GotDmMessageEmbed Evergreen.V157.DmChannel.DmChannelId Evergreen.V157.Id.ThreadRouteWithMessage ( Int, Result Effect.Http.Error Evergreen.V157.RichText.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage ( Int, Result Effect.Http.Error Evergreen.V157.RichText.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) ( Int, Result Effect.Http.Error Evergreen.V157.RichText.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
        (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V157.Discord.HttpError
            { guild : Evergreen.V157.Discord.GatewayGuild
            , channels : List Evergreen.V157.Discord.Channel
            , icon : Maybe Evergreen.V157.FileStatus.UploadResponse
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
    | AdminToFrontend Evergreen.V157.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V157.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V157.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V157.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V157.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V157.ImageEditor.ToFrontend
