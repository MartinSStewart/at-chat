module Evergreen.V144.Types exposing (..)

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
import Evergreen.V144.AiChat
import Evergreen.V144.ChannelName
import Evergreen.V144.Coord
import Evergreen.V144.CssPixels
import Evergreen.V144.Discord
import Evergreen.V144.DiscordAttachmentId
import Evergreen.V144.DmChannel
import Evergreen.V144.Editable
import Evergreen.V144.EmailAddress
import Evergreen.V144.Emoji
import Evergreen.V144.FileStatus
import Evergreen.V144.GuildName
import Evergreen.V144.Id
import Evergreen.V144.ImageEditor
import Evergreen.V144.Local
import Evergreen.V144.LocalState
import Evergreen.V144.Log
import Evergreen.V144.LoginForm
import Evergreen.V144.Message
import Evergreen.V144.MessageInput
import Evergreen.V144.MessageView
import Evergreen.V144.NonemptyDict
import Evergreen.V144.NonemptySet
import Evergreen.V144.OneToOne
import Evergreen.V144.Pages.Admin
import Evergreen.V144.PersonName
import Evergreen.V144.Ports
import Evergreen.V144.Postmark
import Evergreen.V144.RichText
import Evergreen.V144.Route
import Evergreen.V144.SecretId
import Evergreen.V144.SessionIdHash
import Evergreen.V144.Slack
import Evergreen.V144.TextEditor
import Evergreen.V144.Touch
import Evergreen.V144.TwoFactorAuthentication
import Evergreen.V144.Ui.Anim
import Evergreen.V144.User
import Evergreen.V144.UserAgent
import Evergreen.V144.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V144.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V144.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) Evergreen.V144.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) Evergreen.V144.LocalState.DiscordFrontendGuild
    , user : Evergreen.V144.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V144.SessionIdHash.SessionIdHash Evergreen.V144.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V144.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V144.Route.Route
    , windowSize : Evergreen.V144.Coord.Coord Evergreen.V144.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V144.Ports.NotificationPermission
    , pwaStatus : Evergreen.V144.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V144.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V144.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V144.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))) Evergreen.V144.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V144.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))) Evergreen.V144.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) Evergreen.V144.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.UserSession.ToBeFilledInByBackend (Evergreen.V144.SecretId.SecretId Evergreen.V144.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V144.GuildName.GuildName (Evergreen.V144.UserSession.ToBeFilledInByBackend (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage Evergreen.V144.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage Evergreen.V144.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V144.Id.GuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))) (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V144.Id.DiscordGuildOrDmId_DmData (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V144.UserSession.SetViewing
    | Local_SetName Evergreen.V144.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V144.Id.GuildOrDmId (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V144.Id.GuildOrDmId (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V144.Id.DiscordGuildOrDmId (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V144.Id.DiscordGuildOrDmId (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V144.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V144.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V144.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Effect.Time.Posix Evergreen.V144.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))) Evergreen.V144.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V144.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))) Evergreen.V144.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) Evergreen.V144.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.SecretId.SecretId Evergreen.V144.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V144.LocalState.JoinGuildError
            { guildId : Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId
            , guild : Evergreen.V144.LocalState.FrontendGuild
            , owner : Evergreen.V144.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.Id.GuildOrDmId Evergreen.V144.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.Id.GuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage Evergreen.V144.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.Id.GuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage Evergreen.V144.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage Evergreen.V144.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage Evergreen.V144.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.Id.GuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))) (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V144.Id.DiscordGuildOrDmId_DmData (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V144.SessionIdHash.SessionIdHash Evergreen.V144.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V144.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V144.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V144.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.NonemptySet.NonemptySet (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) Evergreen.V144.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) Evergreen.V144.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Maybe (Evergreen.V144.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V144.Pages.Admin.InitAdminData


type LocalMsg
    = LocalChange (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) Evergreen.V144.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V144.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V144.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V144.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V144.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V144.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V144.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V144.Coord.Coord Evergreen.V144.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V144.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V144.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V144.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V144.Local.Local LocalMsg Evergreen.V144.LocalState.LocalState
    , admin : Evergreen.V144.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId, Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V144.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V144.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.NonemptyDict.NonemptyDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V144.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V144.TextEditor.Model
    , profilePictureEditor : Evergreen.V144.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V144.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V144.SecretId.SecretId Evergreen.V144.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V144.NonemptyDict.NonemptyDict Int Evergreen.V144.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V144.NonemptyDict.NonemptyDict Int Evergreen.V144.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V144.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V144.Coord.Coord Evergreen.V144.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V144.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V144.Ports.NotificationPermission
    , pwaStatus : Evergreen.V144.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V144.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V144.UserAgent.UserAgent
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
    , userId : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V144.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V144.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V144.Coord.Coord Evergreen.V144.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V144.Discord.PartialUser
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V144.Discord.UserAuth
    , user : Evergreen.V144.Discord.User
    , connection : Evergreen.V144.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V144.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V144.Discord.User
    , linkedTo : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V144.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V144.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V144.NonemptyDict.NonemptyDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V144.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V144.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V144.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) Evergreen.V144.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V144.DmChannel.DmChannelId Evergreen.V144.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) Evergreen.V144.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V144.OneToOne.OneToOne (Evergreen.V144.Slack.Id Evergreen.V144.Slack.ChannelId) Evergreen.V144.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V144.OneToOne.OneToOne String (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    , slackUsers : Evergreen.V144.OneToOne.OneToOne (Evergreen.V144.Slack.Id Evergreen.V144.Slack.UserId) (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    , slackServers : Evergreen.V144.OneToOne.OneToOne (Evergreen.V144.Slack.Id Evergreen.V144.Slack.TeamId) (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    , slackToken : Maybe Evergreen.V144.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V144.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V144.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V144.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V144.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId, Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V144.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V144.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V144.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V144.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.LocalState.LoadingDiscordChannel (List Evergreen.V144.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V144.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V144.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V144.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V144.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) Evergreen.V144.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) Evergreen.V144.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V144.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V144.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Coord.Coord Evergreen.V144.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V144.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V144.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V144.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V144.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V144.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V144.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V144.NonemptyDict.NonemptyDict Int Evergreen.V144.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V144.NonemptyDict.NonemptyDict Int Evergreen.V144.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V144.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V144.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V144.Editable.Msg Evergreen.V144.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V144.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V144.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V144.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute ) (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRouteWithMessage Evergreen.V144.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V144.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V144.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V144.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V144.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId
        , otherUserId : Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V144.Id.AnyGuildOrDmId Evergreen.V144.Id.ThreadRoute
    | InitialLoadRequested_Admin
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V144.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V144.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V144.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V144.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V144.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V144.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.SecretId.SecretId Evergreen.V144.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V144.PersonName.PersonName Evergreen.V144.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V144.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V144.Slack.OAuthCode Evergreen.V144.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V144.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V144.ImageEditor.ToBackend
    | AdminDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V144.EmailAddress.EmailAddress (Result Evergreen.V144.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V144.EmailAddress.EmailAddress (Result Evergreen.V144.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V144.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMaybeMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Result Evergreen.V144.Discord.HttpError Evergreen.V144.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V144.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Result Evergreen.V144.Discord.HttpError Evergreen.V144.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) (Result Evergreen.V144.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) (Result Evergreen.V144.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) (Result Evergreen.V144.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) (Result Evergreen.V144.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji (Result Evergreen.V144.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji (Result Evergreen.V144.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji (Result Evergreen.V144.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji (Result Evergreen.V144.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V144.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V144.Discord.HttpError (List ( Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId, Maybe Evergreen.V144.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V144.Slack.CurrentUser
            , team : Evergreen.V144.Slack.Team
            , users : List Evergreen.V144.Slack.User
            , channels : List ( Evergreen.V144.Slack.Channel, List Evergreen.V144.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Result Effect.Http.Error Evergreen.V144.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.Discord.UserAuth (Result Evergreen.V144.Discord.HttpError Evergreen.V144.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Result Evergreen.V144.Discord.HttpError Evergreen.V144.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
        (Result
            Evergreen.V144.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId
                , members : List (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
                }
            , List
                ( Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId
                , { guild : Evergreen.V144.Discord.GatewayGuild
                  , channels : List Evergreen.V144.Discord.Channel
                  , icon : Maybe Evergreen.V144.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V144.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V144.Discord.Id Evergreen.V144.Discord.AttachmentId, Evergreen.V144.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V144.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V144.Discord.Id Evergreen.V144.Discord.AttachmentId, Evergreen.V144.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V144.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V144.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V144.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V144.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) (Result Evergreen.V144.Discord.HttpError (List Evergreen.V144.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Result Evergreen.V144.Discord.HttpError (List Evergreen.V144.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket String Effect.Time.Posix


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
    | AdminToFrontend Evergreen.V144.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V144.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V144.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V144.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V144.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V144.ImageEditor.ToFrontend
