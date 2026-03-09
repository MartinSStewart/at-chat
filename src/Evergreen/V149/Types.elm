module Evergreen.V149.Types exposing (..)

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
import Evergreen.V149.AiChat
import Evergreen.V149.ChannelName
import Evergreen.V149.Coord
import Evergreen.V149.CssPixels
import Evergreen.V149.Discord
import Evergreen.V149.DiscordAttachmentId
import Evergreen.V149.DiscordUserData
import Evergreen.V149.DmChannel
import Evergreen.V149.Editable
import Evergreen.V149.EmailAddress
import Evergreen.V149.Emoji
import Evergreen.V149.FileStatus
import Evergreen.V149.GuildName
import Evergreen.V149.Id
import Evergreen.V149.ImageEditor
import Evergreen.V149.Local
import Evergreen.V149.LocalState
import Evergreen.V149.Log
import Evergreen.V149.LoginForm
import Evergreen.V149.Message
import Evergreen.V149.MessageInput
import Evergreen.V149.MessageView
import Evergreen.V149.NonemptyDict
import Evergreen.V149.NonemptySet
import Evergreen.V149.OneToOne
import Evergreen.V149.Pages.Admin
import Evergreen.V149.Pagination
import Evergreen.V149.PersonName
import Evergreen.V149.Ports
import Evergreen.V149.Postmark
import Evergreen.V149.RichText
import Evergreen.V149.Route
import Evergreen.V149.SecretId
import Evergreen.V149.SessionIdHash
import Evergreen.V149.Slack
import Evergreen.V149.TextEditor
import Evergreen.V149.Touch
import Evergreen.V149.TwoFactorAuthentication
import Evergreen.V149.Ui.Anim
import Evergreen.V149.User
import Evergreen.V149.UserAgent
import Evergreen.V149.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V149.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V149.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) Evergreen.V149.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) Evergreen.V149.LocalState.DiscordFrontendGuild
    , user : Evergreen.V149.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V149.SessionIdHash.SessionIdHash Evergreen.V149.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V149.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V149.Route.Route
    , windowSize : Evergreen.V149.Coord.Coord Evergreen.V149.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V149.Ports.NotificationPermission
    , pwaStatus : Evergreen.V149.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V149.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V149.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V149.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))) Evergreen.V149.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V149.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))) Evergreen.V149.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) Evergreen.V149.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.UserSession.ToBeFilledInByBackend (Evergreen.V149.SecretId.SecretId Evergreen.V149.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V149.GuildName.GuildName (Evergreen.V149.UserSession.ToBeFilledInByBackend (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage Evergreen.V149.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage Evergreen.V149.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V149.Id.GuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))) (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V149.Id.DiscordGuildOrDmId_DmData (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V149.UserSession.SetViewing
    | Local_SetName Evergreen.V149.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V149.Id.GuildOrDmId (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V149.Id.GuildOrDmId (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V149.Id.DiscordGuildOrDmId (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V149.Id.DiscordGuildOrDmId (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) Evergreen.V149.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V149.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V149.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V149.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    | LinkDiscordAcknowledgementIsChecked Bool


type ServerChange
    = Server_SendMessage (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Effect.Time.Posix Evergreen.V149.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))) Evergreen.V149.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V149.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))) Evergreen.V149.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) Evergreen.V149.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.SecretId.SecretId Evergreen.V149.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V149.LocalState.JoinGuildError
            { guildId : Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId
            , guild : Evergreen.V149.LocalState.FrontendGuild
            , owner : Evergreen.V149.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.Id.GuildOrDmId Evergreen.V149.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.Id.GuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage Evergreen.V149.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.Id.GuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage Evergreen.V149.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage Evergreen.V149.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage Evergreen.V149.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.Id.GuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))) (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V149.Id.DiscordGuildOrDmId_DmData (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) Evergreen.V149.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V149.SessionIdHash.SessionIdHash Evergreen.V149.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V149.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V149.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V149.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.NonemptySet.NonemptySet (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) Evergreen.V149.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) Evergreen.V149.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Maybe (Evergreen.V149.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V149.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V149.Log.Log


type LocalMsg
    = LocalChange (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) Evergreen.V149.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V149.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V149.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V149.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V149.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V149.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V149.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V149.Coord.Coord Evergreen.V149.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V149.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V149.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V149.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V149.Local.Local LocalMsg Evergreen.V149.LocalState.LocalState
    , admin : Evergreen.V149.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId, Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V149.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V149.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.NonemptyDict.NonemptyDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V149.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V149.TextEditor.Model
    , profilePictureEditor : Evergreen.V149.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V149.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V149.SecretId.SecretId Evergreen.V149.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V149.NonemptyDict.NonemptyDict Int Evergreen.V149.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V149.NonemptyDict.NonemptyDict Int Evergreen.V149.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V149.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V149.Coord.Coord Evergreen.V149.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V149.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V149.Ports.NotificationPermission
    , pwaStatus : Evergreen.V149.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V149.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V149.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V149.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V149.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V149.Coord.Coord Evergreen.V149.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V149.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V149.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V149.NonemptyDict.NonemptyDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V149.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V149.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V149.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) Evergreen.V149.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V149.DmChannel.DmChannelId Evergreen.V149.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) Evergreen.V149.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V149.OneToOne.OneToOne (Evergreen.V149.Slack.Id Evergreen.V149.Slack.ChannelId) Evergreen.V149.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V149.OneToOne.OneToOne String (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    , slackUsers : Evergreen.V149.OneToOne.OneToOne (Evergreen.V149.Slack.Id Evergreen.V149.Slack.UserId) (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    , slackServers : Evergreen.V149.OneToOne.OneToOne (Evergreen.V149.Slack.Id Evergreen.V149.Slack.TeamId) (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    , slackToken : Maybe Evergreen.V149.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V149.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V149.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V149.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V149.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId, Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V149.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V149.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V149.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V149.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.LocalState.LoadingDiscordChannel (List Evergreen.V149.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V149.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V149.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V149.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V149.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) Evergreen.V149.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) Evergreen.V149.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V149.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V149.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Coord.Coord Evergreen.V149.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V149.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V149.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V149.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V149.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V149.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V149.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V149.NonemptyDict.NonemptyDict Int Evergreen.V149.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V149.NonemptyDict.NonemptyDict Int Evergreen.V149.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V149.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V149.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V149.Editable.Msg Evergreen.V149.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V149.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V149.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V149.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute ) (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRouteWithMessage Evergreen.V149.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V149.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V149.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) Evergreen.V149.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V149.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V149.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId
        , otherUserId : Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V149.Id.AnyGuildOrDmId Evergreen.V149.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V149.Id.Id Evergreen.V149.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V149.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V149.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V149.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V149.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V149.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V149.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.SecretId.SecretId Evergreen.V149.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V149.PersonName.PersonName Evergreen.V149.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V149.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V149.Slack.OAuthCode Evergreen.V149.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V149.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V149.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V149.Id.Id Evergreen.V149.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V149.EmailAddress.EmailAddress (Result Evergreen.V149.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V149.EmailAddress.EmailAddress (Result Evergreen.V149.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V149.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMaybeMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Result Evergreen.V149.Discord.HttpError Evergreen.V149.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V149.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Result Evergreen.V149.Discord.HttpError Evergreen.V149.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) (Result Evergreen.V149.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) (Result Evergreen.V149.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) (Result Evergreen.V149.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) (Result Evergreen.V149.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji (Result Evergreen.V149.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji (Result Evergreen.V149.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji (Result Evergreen.V149.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji (Result Evergreen.V149.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V149.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V149.Discord.HttpError (List ( Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId, Maybe Evergreen.V149.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V149.Slack.CurrentUser
            , team : Evergreen.V149.Slack.Team
            , users : List Evergreen.V149.Slack.User
            , channels : List ( Evergreen.V149.Slack.Channel, List Evergreen.V149.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Result Effect.Http.Error Evergreen.V149.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.Discord.UserAuth (Result Evergreen.V149.Discord.HttpError Evergreen.V149.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Result Evergreen.V149.Discord.HttpError Evergreen.V149.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
        (Result
            Evergreen.V149.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId
                , members : List (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
                }
            , List
                ( Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId
                , { guild : Evergreen.V149.Discord.GatewayGuild
                  , channels : List Evergreen.V149.Discord.Channel
                  , icon : Maybe Evergreen.V149.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V149.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V149.Discord.Id Evergreen.V149.Discord.AttachmentId, Evergreen.V149.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V149.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V149.Discord.Id Evergreen.V149.Discord.AttachmentId, Evergreen.V149.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V149.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V149.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V149.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V149.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) (Result Evergreen.V149.Discord.HttpError (List Evergreen.V149.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Result Evergreen.V149.Discord.HttpError (List Evergreen.V149.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix


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
    | AdminToFrontend Evergreen.V149.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V149.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V149.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V149.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V149.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V149.ImageEditor.ToFrontend
