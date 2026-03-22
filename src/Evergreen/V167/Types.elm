module Evergreen.V167.Types exposing (..)

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
import Evergreen.V167.AiChat
import Evergreen.V167.ChannelName
import Evergreen.V167.Coord
import Evergreen.V167.CssPixels
import Evergreen.V167.Discord
import Evergreen.V167.DiscordAttachmentId
import Evergreen.V167.DiscordUserData
import Evergreen.V167.DmChannel
import Evergreen.V167.Editable
import Evergreen.V167.EmailAddress
import Evergreen.V167.Embed
import Evergreen.V167.Emoji
import Evergreen.V167.FileStatus
import Evergreen.V167.GuildName
import Evergreen.V167.Id
import Evergreen.V167.ImageEditor
import Evergreen.V167.Local
import Evergreen.V167.LocalState
import Evergreen.V167.Log
import Evergreen.V167.LoginForm
import Evergreen.V167.MembersAndOwner
import Evergreen.V167.Message
import Evergreen.V167.MessageInput
import Evergreen.V167.MessageView
import Evergreen.V167.NonemptyDict
import Evergreen.V167.NonemptySet
import Evergreen.V167.OneToOne
import Evergreen.V167.Pages.Admin
import Evergreen.V167.Pagination
import Evergreen.V167.PersonName
import Evergreen.V167.Ports
import Evergreen.V167.Postmark
import Evergreen.V167.RichText
import Evergreen.V167.Route
import Evergreen.V167.SecretId
import Evergreen.V167.SessionIdHash
import Evergreen.V167.Slack
import Evergreen.V167.TextEditor
import Evergreen.V167.Touch
import Evergreen.V167.TwoFactorAuthentication
import Evergreen.V167.Ui.Anim
import Evergreen.V167.User
import Evergreen.V167.UserAgent
import Evergreen.V167.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V167.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V167.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) Evergreen.V167.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.LocalState.DiscordFrontendGuild
    , user : Evergreen.V167.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V167.SessionIdHash.SessionIdHash Evergreen.V167.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V167.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V167.Route.Route
    , windowSize : Evergreen.V167.Coord.Coord Evergreen.V167.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V167.Ports.NotificationPermission
    , pwaStatus : Evergreen.V167.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V167.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V167.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V167.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))) Evergreen.V167.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V167.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))) Evergreen.V167.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) Evergreen.V167.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.UserSession.ToBeFilledInByBackend (Evergreen.V167.SecretId.SecretId Evergreen.V167.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V167.GuildName.GuildName (Evergreen.V167.UserSession.ToBeFilledInByBackend (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage Evergreen.V167.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage Evergreen.V167.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V167.Id.GuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))) (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V167.Id.DiscordGuildOrDmId_DmData (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V167.UserSession.SetViewing
    | Local_SetName Evergreen.V167.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V167.Id.GuildOrDmId (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V167.Id.GuildOrDmId (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V167.Id.DiscordGuildOrDmId (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V167.Id.DiscordGuildOrDmId (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V167.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V167.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V167.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V167.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Effect.Time.Posix Evergreen.V167.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))) Evergreen.V167.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V167.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))) Evergreen.V167.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) Evergreen.V167.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.SecretId.SecretId Evergreen.V167.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V167.LocalState.JoinGuildError
            { guildId : Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId
            , guild : Evergreen.V167.LocalState.FrontendGuild
            , owner : Evergreen.V167.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Id.GuildOrDmId Evergreen.V167.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Id.GuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage Evergreen.V167.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Id.GuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage Evergreen.V167.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage Evergreen.V167.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage Evergreen.V167.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Id.GuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))) (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V167.Id.DiscordGuildOrDmId_DmData (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V167.SessionIdHash.SessionIdHash Evergreen.V167.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V167.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V167.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V167.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.ChannelName.ChannelName (Evergreen.V167.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId)
        (Evergreen.V167.NonemptyDict.NonemptyDict
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) Evergreen.V167.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Maybe (Evergreen.V167.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V167.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V167.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V167.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V167.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V167.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V167.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) (Evergreen.V167.Discord.OptionalData String) (Evergreen.V167.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
        (Evergreen.V167.MembersAndOwner.MembersAndOwner
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) Evergreen.V167.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V167.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V167.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V167.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V167.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V167.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V167.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V167.Coord.Coord Evergreen.V167.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V167.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V167.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V167.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V167.Local.Local LocalMsg Evergreen.V167.LocalState.LocalState
    , admin : Evergreen.V167.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId, Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V167.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V167.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.NonemptyDict.NonemptyDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V167.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V167.TextEditor.Model
    , profilePictureEditor : Evergreen.V167.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V167.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V167.SecretId.SecretId Evergreen.V167.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V167.NonemptyDict.NonemptyDict Int Evergreen.V167.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V167.NonemptyDict.NonemptyDict Int Evergreen.V167.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V167.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V167.Coord.Coord Evergreen.V167.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V167.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V167.Ports.NotificationPermission
    , pwaStatus : Evergreen.V167.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V167.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V167.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V167.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V167.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V167.Coord.Coord Evergreen.V167.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V167.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V167.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId, Evergreen.V167.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V167.DmChannel.DmChannelId, Evergreen.V167.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId, Evergreen.V167.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId, Evergreen.V167.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V167.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V167.NonemptyDict.NonemptyDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V167.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V167.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V167.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V167.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V167.DmChannel.DmChannelId Evergreen.V167.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) Evergreen.V167.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V167.OneToOne.OneToOne (Evergreen.V167.Slack.Id Evergreen.V167.Slack.ChannelId) Evergreen.V167.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V167.OneToOne.OneToOne String (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    , slackUsers : Evergreen.V167.OneToOne.OneToOne (Evergreen.V167.Slack.Id Evergreen.V167.Slack.UserId) (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
    , slackServers : Evergreen.V167.OneToOne.OneToOne (Evergreen.V167.Slack.Id Evergreen.V167.Slack.TeamId) (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    , slackToken : Maybe Evergreen.V167.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V167.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V167.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V167.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V167.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId, Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V167.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V167.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V167.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V167.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.LocalState.LoadingDiscordChannel (List Evergreen.V167.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V167.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V167.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V167.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V167.Route.Route
    | SelectedFilesToAttach ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) Evergreen.V167.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) Evergreen.V167.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V167.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Coord.Coord Evergreen.V167.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V167.Emoji.Emoji
    | MessageMenu_PressedReply Evergreen.V167.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V167.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V167.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V167.NonemptyDict.NonemptyDict Int Evergreen.V167.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V167.NonemptyDict.NonemptyDict Int Evergreen.V167.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V167.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V167.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V167.Editable.Msg Evergreen.V167.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V167.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V167.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V167.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute ) (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRouteWithMessage Evergreen.V167.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V167.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V167.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V167.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V167.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId
        , otherUserId : Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V167.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRoute Evergreen.V167.MessageInput.Msg
    | MessageInputMsg Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRoute Evergreen.V167.MessageInput.Msg


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V167.Id.AnyGuildOrDmId Evergreen.V167.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V167.Id.Id Evergreen.V167.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V167.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V167.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V167.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V167.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V167.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V167.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.SecretId.SecretId Evergreen.V167.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V167.PersonName.PersonName Evergreen.V167.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V167.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V167.Slack.OAuthCode Evergreen.V167.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V167.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V167.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V167.Id.Id Evergreen.V167.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V167.EmailAddress.EmailAddress (Result Evergreen.V167.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V167.EmailAddress.EmailAddress (Result Evergreen.V167.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V167.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMaybeMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Result Evergreen.V167.Discord.HttpError Evergreen.V167.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V167.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Result Evergreen.V167.Discord.HttpError Evergreen.V167.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) (Result Evergreen.V167.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) (Result Evergreen.V167.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) (Result Evergreen.V167.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) (Result Evergreen.V167.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji (Result Evergreen.V167.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji (Result Evergreen.V167.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji (Result Evergreen.V167.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji (Result Evergreen.V167.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V167.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V167.Discord.HttpError (List ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId, Maybe Evergreen.V167.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V167.Slack.CurrentUser
            , team : Evergreen.V167.Slack.Team
            , users : List Evergreen.V167.Slack.User
            , channels : List ( Evergreen.V167.Slack.Channel, List Evergreen.V167.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Result Effect.Http.Error Evergreen.V167.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Discord.UserAuth (Result Evergreen.V167.Discord.HttpError Evergreen.V167.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Result Evergreen.V167.Discord.HttpError Evergreen.V167.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
        (Result
            Evergreen.V167.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId
                , members : List (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
                }
            , List
                ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId
                , { guild : Evergreen.V167.Discord.GatewayGuild
                  , channels : List Evergreen.V167.Discord.Channel
                  , icon : Maybe Evergreen.V167.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V167.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.AttachmentId, Evergreen.V167.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V167.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.AttachmentId, Evergreen.V167.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V167.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V167.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V167.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V167.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) (Result Evergreen.V167.Discord.HttpError (List Evergreen.V167.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Result Evergreen.V167.Discord.HttpError (List Evergreen.V167.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V167.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V167.DmChannel.DmChannelId Evergreen.V167.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V167.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V167.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V167.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
        (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V167.Discord.HttpError
            { guild : Evergreen.V167.Discord.GatewayGuild
            , channels : List Evergreen.V167.Discord.Channel
            , icon : Maybe Evergreen.V167.FileStatus.UploadResponse
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
    | AdminToFrontend Evergreen.V167.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V167.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V167.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V167.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V167.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V167.ImageEditor.ToFrontend
