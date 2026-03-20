module Evergreen.V161.Types exposing (..)

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
import Evergreen.V161.AiChat
import Evergreen.V161.ChannelName
import Evergreen.V161.Coord
import Evergreen.V161.CssPixels
import Evergreen.V161.Discord
import Evergreen.V161.DiscordAttachmentId
import Evergreen.V161.DiscordUserData
import Evergreen.V161.DmChannel
import Evergreen.V161.Editable
import Evergreen.V161.EmailAddress
import Evergreen.V161.Emoji
import Evergreen.V161.FileStatus
import Evergreen.V161.GuildName
import Evergreen.V161.Id
import Evergreen.V161.ImageEditor
import Evergreen.V161.Local
import Evergreen.V161.LocalState
import Evergreen.V161.Log
import Evergreen.V161.LoginForm
import Evergreen.V161.Message
import Evergreen.V161.MessageInput
import Evergreen.V161.MessageView
import Evergreen.V161.NonemptyDict
import Evergreen.V161.NonemptySet
import Evergreen.V161.OneToOne
import Evergreen.V161.Pages.Admin
import Evergreen.V161.Pagination
import Evergreen.V161.PersonName
import Evergreen.V161.Ports
import Evergreen.V161.Postmark
import Evergreen.V161.RichText
import Evergreen.V161.Route
import Evergreen.V161.SecretId
import Evergreen.V161.SessionIdHash
import Evergreen.V161.Slack
import Evergreen.V161.TextEditor
import Evergreen.V161.Touch
import Evergreen.V161.TwoFactorAuthentication
import Evergreen.V161.Ui.Anim
import Evergreen.V161.User
import Evergreen.V161.UserAgent
import Evergreen.V161.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V161.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V161.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) Evergreen.V161.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.LocalState.DiscordFrontendGuild
    , user : Evergreen.V161.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V161.SessionIdHash.SessionIdHash Evergreen.V161.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V161.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V161.Route.Route
    , windowSize : Evergreen.V161.Coord.Coord Evergreen.V161.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V161.Ports.NotificationPermission
    , pwaStatus : Evergreen.V161.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V161.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V161.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V161.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))) Evergreen.V161.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V161.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))) Evergreen.V161.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) Evergreen.V161.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.UserSession.ToBeFilledInByBackend (Evergreen.V161.SecretId.SecretId Evergreen.V161.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V161.GuildName.GuildName (Evergreen.V161.UserSession.ToBeFilledInByBackend (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage Evergreen.V161.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage Evergreen.V161.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V161.Id.GuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))) (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V161.Id.DiscordGuildOrDmId_DmData (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V161.UserSession.SetViewing
    | Local_SetName Evergreen.V161.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V161.Id.GuildOrDmId (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V161.Id.GuildOrDmId (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V161.Id.DiscordGuildOrDmId (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V161.Id.DiscordGuildOrDmId (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V161.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V161.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V161.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V161.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Effect.Time.Posix Evergreen.V161.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))) Evergreen.V161.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V161.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))) Evergreen.V161.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) Evergreen.V161.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.SecretId.SecretId Evergreen.V161.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V161.LocalState.JoinGuildError
            { guildId : Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId
            , guild : Evergreen.V161.LocalState.FrontendGuild
            , owner : Evergreen.V161.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Id.GuildOrDmId Evergreen.V161.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Id.GuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage Evergreen.V161.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Id.GuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage Evergreen.V161.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage Evergreen.V161.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage Evergreen.V161.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Id.GuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))) (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V161.Id.DiscordGuildOrDmId_DmData (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V161.SessionIdHash.SessionIdHash Evergreen.V161.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V161.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V161.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V161.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.ChannelName.ChannelName (Evergreen.V161.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId)
        (Evergreen.V161.NonemptyDict.NonemptyDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) Evergreen.V161.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Maybe (Evergreen.V161.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V161.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V161.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V161.RichText.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V161.RichText.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V161.RichText.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V161.RichText.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) (Evergreen.V161.Discord.OptionalData String) (Evergreen.V161.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
        (SeqDict.SeqDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) Evergreen.V161.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V161.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V161.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V161.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V161.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V161.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V161.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V161.Coord.Coord Evergreen.V161.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V161.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V161.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V161.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V161.Local.Local LocalMsg Evergreen.V161.LocalState.LocalState
    , admin : Evergreen.V161.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId, Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V161.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V161.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.NonemptyDict.NonemptyDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V161.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V161.TextEditor.Model
    , profilePictureEditor : Evergreen.V161.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V161.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V161.SecretId.SecretId Evergreen.V161.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V161.NonemptyDict.NonemptyDict Int Evergreen.V161.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V161.NonemptyDict.NonemptyDict Int Evergreen.V161.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V161.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V161.Coord.Coord Evergreen.V161.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V161.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V161.Ports.NotificationPermission
    , pwaStatus : Evergreen.V161.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V161.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V161.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V161.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V161.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V161.Coord.Coord Evergreen.V161.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V161.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V161.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V161.NonemptyDict.NonemptyDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V161.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V161.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V161.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V161.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V161.DmChannel.DmChannelId Evergreen.V161.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) Evergreen.V161.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V161.OneToOne.OneToOne (Evergreen.V161.Slack.Id Evergreen.V161.Slack.ChannelId) Evergreen.V161.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V161.OneToOne.OneToOne String (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    , slackUsers : Evergreen.V161.OneToOne.OneToOne (Evergreen.V161.Slack.Id Evergreen.V161.Slack.UserId) (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    , slackServers : Evergreen.V161.OneToOne.OneToOne (Evergreen.V161.Slack.Id Evergreen.V161.Slack.TeamId) (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    , slackToken : Maybe Evergreen.V161.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V161.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V161.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V161.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V161.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId, Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V161.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V161.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V161.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V161.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.LocalState.LoadingDiscordChannel (List Evergreen.V161.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V161.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V161.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V161.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V161.Route.Route
    | SelectedFilesToAttach ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) Evergreen.V161.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) Evergreen.V161.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V161.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Coord.Coord Evergreen.V161.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V161.Emoji.Emoji
    | MessageMenu_PressedReply Evergreen.V161.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V161.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V161.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V161.NonemptyDict.NonemptyDict Int Evergreen.V161.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V161.NonemptyDict.NonemptyDict Int Evergreen.V161.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V161.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V161.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V161.Editable.Msg Evergreen.V161.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V161.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V161.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V161.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute ) (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRouteWithMessage Evergreen.V161.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V161.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V161.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V161.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V161.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId
        , otherUserId : Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V161.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRoute Evergreen.V161.MessageInput.Msg
    | MessageInputMsg Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRoute Evergreen.V161.MessageInput.Msg


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V161.Id.AnyGuildOrDmId Evergreen.V161.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V161.Id.Id Evergreen.V161.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V161.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V161.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V161.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V161.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V161.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V161.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.SecretId.SecretId Evergreen.V161.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V161.PersonName.PersonName Evergreen.V161.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V161.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V161.Slack.OAuthCode Evergreen.V161.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V161.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V161.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V161.Id.Id Evergreen.V161.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V161.EmailAddress.EmailAddress (Result Evergreen.V161.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V161.EmailAddress.EmailAddress (Result Evergreen.V161.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V161.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMaybeMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Result Evergreen.V161.Discord.HttpError Evergreen.V161.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V161.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Result Evergreen.V161.Discord.HttpError Evergreen.V161.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) (Result Evergreen.V161.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) (Result Evergreen.V161.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) (Result Evergreen.V161.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) (Result Evergreen.V161.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji (Result Evergreen.V161.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji (Result Evergreen.V161.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji (Result Evergreen.V161.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji (Result Evergreen.V161.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V161.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V161.Discord.HttpError (List ( Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId, Maybe Evergreen.V161.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V161.Slack.CurrentUser
            , team : Evergreen.V161.Slack.Team
            , users : List Evergreen.V161.Slack.User
            , channels : List ( Evergreen.V161.Slack.Channel, List Evergreen.V161.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Result Effect.Http.Error Evergreen.V161.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Discord.UserAuth (Result Evergreen.V161.Discord.HttpError Evergreen.V161.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Result Evergreen.V161.Discord.HttpError Evergreen.V161.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
        (Result
            Evergreen.V161.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId
                , members : List (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
                }
            , List
                ( Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId
                , { guild : Evergreen.V161.Discord.GatewayGuild
                  , channels : List Evergreen.V161.Discord.Channel
                  , icon : Maybe Evergreen.V161.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V161.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V161.Discord.Id Evergreen.V161.Discord.AttachmentId, Evergreen.V161.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V161.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V161.Discord.Id Evergreen.V161.Discord.AttachmentId, Evergreen.V161.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V161.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V161.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V161.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V161.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) (Result Evergreen.V161.Discord.HttpError (List Evergreen.V161.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Result Evergreen.V161.Discord.HttpError (List Evergreen.V161.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V161.RichText.EmbedData )
    | GotDmMessageEmbed Evergreen.V161.DmChannel.DmChannelId Evergreen.V161.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V161.RichText.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V161.RichText.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V161.RichText.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
        (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V161.Discord.HttpError
            { guild : Evergreen.V161.Discord.GatewayGuild
            , channels : List Evergreen.V161.Discord.Channel
            , icon : Maybe Evergreen.V161.FileStatus.UploadResponse
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
    | AdminToFrontend Evergreen.V161.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V161.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V161.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V161.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V161.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V161.ImageEditor.ToFrontend
