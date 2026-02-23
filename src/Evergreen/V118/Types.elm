module Evergreen.V118.Types exposing (..)

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
import Evergreen.V118.AiChat
import Evergreen.V118.ChannelName
import Evergreen.V118.Coord
import Evergreen.V118.CssPixels
import Evergreen.V118.Discord
import Evergreen.V118.Discord.Id
import Evergreen.V118.DmChannel
import Evergreen.V118.Editable
import Evergreen.V118.EmailAddress
import Evergreen.V118.Emoji
import Evergreen.V118.FileStatus
import Evergreen.V118.GuildName
import Evergreen.V118.Id
import Evergreen.V118.ImageEditor
import Evergreen.V118.Local
import Evergreen.V118.LocalState
import Evergreen.V118.Log
import Evergreen.V118.LoginForm
import Evergreen.V118.Message
import Evergreen.V118.MessageInput
import Evergreen.V118.MessageView
import Evergreen.V118.NonemptyDict
import Evergreen.V118.NonemptySet
import Evergreen.V118.OneToOne
import Evergreen.V118.Pages.Admin
import Evergreen.V118.PersonName
import Evergreen.V118.Ports
import Evergreen.V118.Postmark
import Evergreen.V118.RichText
import Evergreen.V118.Route
import Evergreen.V118.SecretId
import Evergreen.V118.SessionIdHash
import Evergreen.V118.Slack
import Evergreen.V118.TextEditor
import Evergreen.V118.Touch
import Evergreen.V118.TwoFactorAuthentication
import Evergreen.V118.Ui.Anim
import Evergreen.V118.User
import Evergreen.V118.UserAgent
import Evergreen.V118.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V118.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V118.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) Evergreen.V118.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) Evergreen.V118.LocalState.DiscordFrontendGuild
    , user : Evergreen.V118.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V118.SessionIdHash.SessionIdHash Evergreen.V118.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V118.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V118.Route.Route
    , windowSize : Evergreen.V118.Coord.Coord Evergreen.V118.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V118.Ports.NotificationPermission
    , pwaStatus : Evergreen.V118.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V118.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V118.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V118.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))) Evergreen.V118.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V118.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))) Evergreen.V118.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) Evergreen.V118.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.UserSession.ToBeFilledInByBackend (Evergreen.V118.SecretId.SecretId Evergreen.V118.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V118.GuildName.GuildName (Evergreen.V118.UserSession.ToBeFilledInByBackend (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage Evergreen.V118.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage Evergreen.V118.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V118.Id.GuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))) (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V118.Id.DiscordGuildOrDmId_DmData (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V118.UserSession.SetViewing
    | Local_SetName Evergreen.V118.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V118.Id.GuildOrDmId (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V118.Id.GuildOrDmId (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V118.Id.DiscordGuildOrDmId (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V118.Id.DiscordGuildOrDmId (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V118.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V118.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V118.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Effect.Time.Posix Evergreen.V118.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))) Evergreen.V118.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V118.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))) Evergreen.V118.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) Evergreen.V118.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.SecretId.SecretId Evergreen.V118.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V118.LocalState.JoinGuildError
            { guildId : Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId
            , guild : Evergreen.V118.LocalState.FrontendGuild
            , owner : Evergreen.V118.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.Id.GuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage Evergreen.V118.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.Id.GuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage Evergreen.V118.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage Evergreen.V118.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage Evergreen.V118.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.Id.GuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))) (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V118.Id.DiscordGuildOrDmId_DmData (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V118.SessionIdHash.SessionIdHash Evergreen.V118.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V118.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V118.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V118.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.NonemptySet.NonemptySet (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) Evergreen.V118.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) Evergreen.V118.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)


type LocalMsg
    = LocalChange (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) Evergreen.V118.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V118.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V118.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V118.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V118.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V118.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V118.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V118.Coord.Coord Evergreen.V118.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V118.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V118.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V118.Editable.Model
    , slackClientSecret : Evergreen.V118.Editable.Model
    , publicVapidKey : Evergreen.V118.Editable.Model
    , privateVapidKey : Evergreen.V118.Editable.Model
    , openRouterKey : Evergreen.V118.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V118.Local.Local LocalMsg Evergreen.V118.LocalState.LocalState
    , admin : Maybe Evergreen.V118.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId, Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V118.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V118.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.NonemptyDict.NonemptyDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V118.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V118.TextEditor.Model
    , profilePictureEditor : Evergreen.V118.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V118.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V118.SecretId.SecretId Evergreen.V118.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V118.NonemptyDict.NonemptyDict Int Evergreen.V118.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V118.NonemptyDict.NonemptyDict Int Evergreen.V118.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V118.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V118.Coord.Coord Evergreen.V118.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V118.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V118.Ports.NotificationPermission
    , pwaStatus : Evergreen.V118.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V118.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V118.UserAgent.UserAgent
    , pageHasFocus : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V118.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V118.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V118.Coord.Coord Evergreen.V118.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V118.Discord.PartialUser
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V118.Discord.UserAuth
    , user : Evergreen.V118.Discord.User
    , connection : Evergreen.V118.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V118.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V118.Discord.User
    , linkedTo : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias BackendModel =
    { users : Evergreen.V118.NonemptyDict.NonemptyDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V118.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V118.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V118.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) Evergreen.V118.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V118.DmChannel.DmChannelId Evergreen.V118.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) Evergreen.V118.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V118.OneToOne.OneToOne (Evergreen.V118.Slack.Id Evergreen.V118.Slack.ChannelId) Evergreen.V118.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V118.OneToOne.OneToOne String (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId)
    , slackUsers : Evergreen.V118.OneToOne.OneToOne (Evergreen.V118.Slack.Id Evergreen.V118.Slack.UserId) (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    , slackServers : Evergreen.V118.OneToOne.OneToOne (Evergreen.V118.Slack.Id Evergreen.V118.Slack.TeamId) (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId)
    , slackToken : Maybe Evergreen.V118.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V118.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V118.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V118.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V118.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId, Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V118.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V118.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V118.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V118.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V118.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V118.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V118.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) Evergreen.V118.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) Evergreen.V118.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V118.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V118.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Coord.Coord Evergreen.V118.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V118.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V118.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V118.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V118.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V118.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V118.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V118.NonemptyDict.NonemptyDict Int Evergreen.V118.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V118.NonemptyDict.NonemptyDict Int Evergreen.V118.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V118.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V118.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V118.Editable.Msg Evergreen.V118.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V118.Editable.Msg (Maybe Evergreen.V118.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V118.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V118.Editable.Msg Evergreen.V118.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V118.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V118.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V118.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V118.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ) (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V118.Id.AnyGuildOrDmId Evergreen.V118.Id.ThreadRouteWithMessage Evergreen.V118.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V118.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V118.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V118.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V118.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId
        , otherUserId : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String
    | TypedDiscordLinkBookmarklet


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V118.Discord.UserAuth
    , user : Evergreen.V118.Discord.User
    , linkedTo : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V118.Discord.User
    , linkedTo : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId
    , guild : Evergreen.V118.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )) Int Evergreen.V118.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )) Int Evergreen.V118.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V118.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V118.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V118.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V118.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.SecretId.SecretId Evergreen.V118.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )) Evergreen.V118.PersonName.PersonName Evergreen.V118.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V118.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V118.Slack.OAuthCode Evergreen.V118.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V118.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V118.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V118.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V118.EmailAddress.EmailAddress (Result Evergreen.V118.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V118.EmailAddress.EmailAddress (Result Evergreen.V118.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V118.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Result Evergreen.V118.Discord.HttpError Evergreen.V118.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V118.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Result Evergreen.V118.Discord.HttpError Evergreen.V118.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) (Result Evergreen.V118.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) (Result Evergreen.V118.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) (Result Evergreen.V118.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) (Result Evergreen.V118.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji (Result Evergreen.V118.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji (Result Evergreen.V118.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji (Result Evergreen.V118.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji (Result Evergreen.V118.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V118.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V118.Discord.HttpError (List ( Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId, Maybe Evergreen.V118.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V118.Slack.CurrentUser
            , team : Evergreen.V118.Slack.Team
            , users : List Evergreen.V118.Slack.User
            , channels : List ( Evergreen.V118.Slack.Channel, List Evergreen.V118.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Result Effect.Http.Error Evergreen.V118.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.Discord.UserAuth (Result Evergreen.V118.Discord.HttpError Evergreen.V118.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Result Evergreen.V118.Discord.HttpError Evergreen.V118.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
        (Result
            Evergreen.V118.Discord.HttpError
            ( List ( Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId, Evergreen.V118.DmChannel.DiscordDmChannel, List Evergreen.V118.Discord.Message )
            , List
                ( Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId
                , { guild : Evergreen.V118.Discord.GatewayGuild
                  , channels : List ( Evergreen.V118.Discord.Channel, List Evergreen.V118.Discord.Message )
                  , icon : Maybe Evergreen.V118.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId, Evergreen.V118.Discord.Channel, List Evergreen.V118.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup


type ToFrontend
    = CheckLoginResponse (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | LoggedOutSession
    | AdminToFrontend Evergreen.V118.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V118.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V118.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V118.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V118.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V118.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) Evergreen.V118.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
