module Evergreen.V166.Types exposing (..)

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
import Evergreen.V166.AiChat
import Evergreen.V166.ChannelName
import Evergreen.V166.Coord
import Evergreen.V166.CssPixels
import Evergreen.V166.Discord
import Evergreen.V166.DiscordAttachmentId
import Evergreen.V166.DiscordUserData
import Evergreen.V166.DmChannel
import Evergreen.V166.Editable
import Evergreen.V166.EmailAddress
import Evergreen.V166.Emoji
import Evergreen.V166.FileStatus
import Evergreen.V166.GuildName
import Evergreen.V166.Id
import Evergreen.V166.ImageEditor
import Evergreen.V166.Local
import Evergreen.V166.LocalState
import Evergreen.V166.Log
import Evergreen.V166.LoginForm
import Evergreen.V166.MembersAndOwner
import Evergreen.V166.Message
import Evergreen.V166.MessageInput
import Evergreen.V166.MessageView
import Evergreen.V166.NonemptyDict
import Evergreen.V166.NonemptySet
import Evergreen.V166.OneToOne
import Evergreen.V166.Pages.Admin
import Evergreen.V166.Pagination
import Evergreen.V166.PersonName
import Evergreen.V166.Ports
import Evergreen.V166.Postmark
import Evergreen.V166.RichText
import Evergreen.V166.Route
import Evergreen.V166.SecretId
import Evergreen.V166.SessionIdHash
import Evergreen.V166.Slack
import Evergreen.V166.TextEditor
import Evergreen.V166.Touch
import Evergreen.V166.TwoFactorAuthentication
import Evergreen.V166.Ui.Anim
import Evergreen.V166.User
import Evergreen.V166.UserAgent
import Evergreen.V166.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V166.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V166.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) Evergreen.V166.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.LocalState.DiscordFrontendGuild
    , user : Evergreen.V166.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V166.SessionIdHash.SessionIdHash Evergreen.V166.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V166.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V166.Route.Route
    , windowSize : Evergreen.V166.Coord.Coord Evergreen.V166.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V166.Ports.NotificationPermission
    , pwaStatus : Evergreen.V166.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V166.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V166.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V166.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))) Evergreen.V166.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V166.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))) Evergreen.V166.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) Evergreen.V166.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.UserSession.ToBeFilledInByBackend (Evergreen.V166.SecretId.SecretId Evergreen.V166.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V166.GuildName.GuildName (Evergreen.V166.UserSession.ToBeFilledInByBackend (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage Evergreen.V166.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage Evergreen.V166.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V166.Id.GuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))) (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V166.Id.DiscordGuildOrDmId_DmData (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V166.UserSession.SetViewing
    | Local_SetName Evergreen.V166.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V166.Id.GuildOrDmId (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V166.Id.GuildOrDmId (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V166.Id.DiscordGuildOrDmId (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V166.Id.DiscordGuildOrDmId (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V166.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V166.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V166.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V166.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Effect.Time.Posix Evergreen.V166.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))) Evergreen.V166.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V166.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))) Evergreen.V166.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) Evergreen.V166.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.SecretId.SecretId Evergreen.V166.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V166.LocalState.JoinGuildError
            { guildId : Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId
            , guild : Evergreen.V166.LocalState.FrontendGuild
            , owner : Evergreen.V166.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Id.GuildOrDmId Evergreen.V166.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Id.GuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage Evergreen.V166.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Id.GuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage Evergreen.V166.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage Evergreen.V166.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage Evergreen.V166.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Id.GuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))) (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V166.Id.DiscordGuildOrDmId_DmData (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V166.SessionIdHash.SessionIdHash Evergreen.V166.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V166.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V166.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V166.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.ChannelName.ChannelName (Evergreen.V166.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId)
        (Evergreen.V166.NonemptyDict.NonemptyDict
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) Evergreen.V166.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Maybe (Evergreen.V166.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V166.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V166.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V166.RichText.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V166.RichText.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V166.RichText.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V166.RichText.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) (Evergreen.V166.Discord.OptionalData String) (Evergreen.V166.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
        (Evergreen.V166.MembersAndOwner.MembersAndOwner
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) Evergreen.V166.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V166.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V166.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V166.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V166.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V166.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V166.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V166.Coord.Coord Evergreen.V166.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V166.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V166.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V166.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V166.Local.Local LocalMsg Evergreen.V166.LocalState.LocalState
    , admin : Evergreen.V166.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId, Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V166.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V166.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.NonemptyDict.NonemptyDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V166.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V166.TextEditor.Model
    , profilePictureEditor : Evergreen.V166.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V166.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V166.SecretId.SecretId Evergreen.V166.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V166.NonemptyDict.NonemptyDict Int Evergreen.V166.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V166.NonemptyDict.NonemptyDict Int Evergreen.V166.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V166.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V166.Coord.Coord Evergreen.V166.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V166.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V166.Ports.NotificationPermission
    , pwaStatus : Evergreen.V166.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V166.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V166.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V166.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V166.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V166.Coord.Coord Evergreen.V166.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V166.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V166.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId, Evergreen.V166.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V166.DmChannel.DmChannelId, Evergreen.V166.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId, Evergreen.V166.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId, Evergreen.V166.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V166.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V166.NonemptyDict.NonemptyDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V166.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V166.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V166.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V166.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V166.DmChannel.DmChannelId Evergreen.V166.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) Evergreen.V166.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V166.OneToOne.OneToOne (Evergreen.V166.Slack.Id Evergreen.V166.Slack.ChannelId) Evergreen.V166.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V166.OneToOne.OneToOne String (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    , slackUsers : Evergreen.V166.OneToOne.OneToOne (Evergreen.V166.Slack.Id Evergreen.V166.Slack.UserId) (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
    , slackServers : Evergreen.V166.OneToOne.OneToOne (Evergreen.V166.Slack.Id Evergreen.V166.Slack.TeamId) (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    , slackToken : Maybe Evergreen.V166.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V166.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V166.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V166.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V166.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId, Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V166.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V166.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V166.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V166.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.LocalState.LoadingDiscordChannel (List Evergreen.V166.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V166.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V166.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V166.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V166.Route.Route
    | SelectedFilesToAttach ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) Evergreen.V166.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) Evergreen.V166.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V166.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Coord.Coord Evergreen.V166.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V166.Emoji.Emoji
    | MessageMenu_PressedReply Evergreen.V166.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V166.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V166.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V166.NonemptyDict.NonemptyDict Int Evergreen.V166.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V166.NonemptyDict.NonemptyDict Int Evergreen.V166.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V166.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V166.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V166.Editable.Msg Evergreen.V166.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V166.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V166.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V166.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute ) (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRouteWithMessage Evergreen.V166.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V166.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V166.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V166.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V166.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId
        , otherUserId : Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V166.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRoute Evergreen.V166.MessageInput.Msg
    | MessageInputMsg Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRoute Evergreen.V166.MessageInput.Msg


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V166.Id.AnyGuildOrDmId Evergreen.V166.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V166.Id.Id Evergreen.V166.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V166.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V166.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V166.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V166.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V166.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V166.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.SecretId.SecretId Evergreen.V166.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V166.PersonName.PersonName Evergreen.V166.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V166.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V166.Slack.OAuthCode Evergreen.V166.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V166.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V166.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V166.Id.Id Evergreen.V166.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V166.EmailAddress.EmailAddress (Result Evergreen.V166.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V166.EmailAddress.EmailAddress (Result Evergreen.V166.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V166.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMaybeMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Result Evergreen.V166.Discord.HttpError Evergreen.V166.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V166.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Result Evergreen.V166.Discord.HttpError Evergreen.V166.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) (Result Evergreen.V166.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) (Result Evergreen.V166.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) (Result Evergreen.V166.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) (Result Evergreen.V166.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji (Result Evergreen.V166.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji (Result Evergreen.V166.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji (Result Evergreen.V166.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji (Result Evergreen.V166.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V166.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V166.Discord.HttpError (List ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId, Maybe Evergreen.V166.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V166.Slack.CurrentUser
            , team : Evergreen.V166.Slack.Team
            , users : List Evergreen.V166.Slack.User
            , channels : List ( Evergreen.V166.Slack.Channel, List Evergreen.V166.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Result Effect.Http.Error Evergreen.V166.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Discord.UserAuth (Result Evergreen.V166.Discord.HttpError Evergreen.V166.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Result Evergreen.V166.Discord.HttpError Evergreen.V166.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
        (Result
            Evergreen.V166.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId
                , members : List (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
                }
            , List
                ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId
                , { guild : Evergreen.V166.Discord.GatewayGuild
                  , channels : List Evergreen.V166.Discord.Channel
                  , icon : Maybe Evergreen.V166.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V166.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.AttachmentId, Evergreen.V166.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V166.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.AttachmentId, Evergreen.V166.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V166.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V166.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V166.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V166.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) (Result Evergreen.V166.Discord.HttpError (List Evergreen.V166.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Result Evergreen.V166.Discord.HttpError (List Evergreen.V166.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V166.RichText.EmbedData )
    | GotDmMessageEmbed Evergreen.V166.DmChannel.DmChannelId Evergreen.V166.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V166.RichText.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V166.RichText.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V166.RichText.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
        (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V166.Discord.HttpError
            { guild : Evergreen.V166.Discord.GatewayGuild
            , channels : List Evergreen.V166.Discord.Channel
            , icon : Maybe Evergreen.V166.FileStatus.UploadResponse
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
    | AdminToFrontend Evergreen.V166.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V166.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V166.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V166.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V166.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V166.ImageEditor.ToFrontend
