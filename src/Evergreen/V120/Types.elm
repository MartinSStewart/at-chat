module Evergreen.V120.Types exposing (..)

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
import Evergreen.V120.AiChat
import Evergreen.V120.ChannelName
import Evergreen.V120.Coord
import Evergreen.V120.CssPixels
import Evergreen.V120.Discord
import Evergreen.V120.Discord.Id
import Evergreen.V120.DmChannel
import Evergreen.V120.Editable
import Evergreen.V120.EmailAddress
import Evergreen.V120.Emoji
import Evergreen.V120.FileStatus
import Evergreen.V120.GuildName
import Evergreen.V120.Id
import Evergreen.V120.ImageEditor
import Evergreen.V120.Local
import Evergreen.V120.LocalState
import Evergreen.V120.Log
import Evergreen.V120.LoginForm
import Evergreen.V120.Message
import Evergreen.V120.MessageInput
import Evergreen.V120.MessageView
import Evergreen.V120.NonemptyDict
import Evergreen.V120.NonemptySet
import Evergreen.V120.OneToOne
import Evergreen.V120.Pages.Admin
import Evergreen.V120.PersonName
import Evergreen.V120.Ports
import Evergreen.V120.Postmark
import Evergreen.V120.RichText
import Evergreen.V120.Route
import Evergreen.V120.SecretId
import Evergreen.V120.SessionIdHash
import Evergreen.V120.Slack
import Evergreen.V120.TextEditor
import Evergreen.V120.Touch
import Evergreen.V120.TwoFactorAuthentication
import Evergreen.V120.Ui.Anim
import Evergreen.V120.User
import Evergreen.V120.UserAgent
import Evergreen.V120.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V120.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V120.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) Evergreen.V120.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) Evergreen.V120.LocalState.DiscordFrontendGuild
    , user : Evergreen.V120.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V120.SessionIdHash.SessionIdHash Evergreen.V120.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V120.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V120.Route.Route
    , windowSize : Evergreen.V120.Coord.Coord Evergreen.V120.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V120.Ports.NotificationPermission
    , pwaStatus : Evergreen.V120.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V120.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V120.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V120.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))) Evergreen.V120.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V120.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))) Evergreen.V120.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) Evergreen.V120.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.UserSession.ToBeFilledInByBackend (Evergreen.V120.SecretId.SecretId Evergreen.V120.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V120.GuildName.GuildName (Evergreen.V120.UserSession.ToBeFilledInByBackend (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage Evergreen.V120.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage Evergreen.V120.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V120.Id.GuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))) (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V120.Id.DiscordGuildOrDmId_DmData (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V120.UserSession.SetViewing
    | Local_SetName Evergreen.V120.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V120.Id.GuildOrDmId (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V120.Id.GuildOrDmId (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V120.Id.DiscordGuildOrDmId (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V120.Id.DiscordGuildOrDmId (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V120.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V120.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V120.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Effect.Time.Posix Evergreen.V120.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))) Evergreen.V120.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V120.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))) Evergreen.V120.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) Evergreen.V120.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.SecretId.SecretId Evergreen.V120.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V120.LocalState.JoinGuildError
            { guildId : Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId
            , guild : Evergreen.V120.LocalState.FrontendGuild
            , owner : Evergreen.V120.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.Id.GuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage Evergreen.V120.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.Id.GuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage Evergreen.V120.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage Evergreen.V120.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage Evergreen.V120.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.Id.GuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))) (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V120.Id.DiscordGuildOrDmId_DmData (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V120.SessionIdHash.SessionIdHash Evergreen.V120.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V120.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V120.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V120.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.NonemptySet.NonemptySet (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) Evergreen.V120.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) Evergreen.V120.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)


type LocalMsg
    = LocalChange (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) Evergreen.V120.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V120.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V120.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V120.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V120.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V120.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V120.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V120.Coord.Coord Evergreen.V120.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V120.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V120.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V120.Editable.Model
    , slackClientSecret : Evergreen.V120.Editable.Model
    , publicVapidKey : Evergreen.V120.Editable.Model
    , privateVapidKey : Evergreen.V120.Editable.Model
    , openRouterKey : Evergreen.V120.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V120.Local.Local LocalMsg Evergreen.V120.LocalState.LocalState
    , admin : Maybe Evergreen.V120.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId, Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V120.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V120.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.NonemptyDict.NonemptyDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V120.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V120.TextEditor.Model
    , profilePictureEditor : Evergreen.V120.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V120.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V120.SecretId.SecretId Evergreen.V120.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V120.NonemptyDict.NonemptyDict Int Evergreen.V120.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V120.NonemptyDict.NonemptyDict Int Evergreen.V120.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V120.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V120.Coord.Coord Evergreen.V120.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V120.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V120.Ports.NotificationPermission
    , pwaStatus : Evergreen.V120.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V120.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V120.UserAgent.UserAgent
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
    , userId : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V120.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V120.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V120.Coord.Coord Evergreen.V120.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V120.Discord.PartialUser
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V120.Discord.UserAuth
    , user : Evergreen.V120.Discord.User
    , connection : Evergreen.V120.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V120.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V120.Discord.User
    , linkedTo : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias BackendModel =
    { users : Evergreen.V120.NonemptyDict.NonemptyDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V120.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V120.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V120.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) Evergreen.V120.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V120.DmChannel.DmChannelId Evergreen.V120.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) Evergreen.V120.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V120.OneToOne.OneToOne (Evergreen.V120.Slack.Id Evergreen.V120.Slack.ChannelId) Evergreen.V120.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V120.OneToOne.OneToOne String (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId)
    , slackUsers : Evergreen.V120.OneToOne.OneToOne (Evergreen.V120.Slack.Id Evergreen.V120.Slack.UserId) (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    , slackServers : Evergreen.V120.OneToOne.OneToOne (Evergreen.V120.Slack.Id Evergreen.V120.Slack.TeamId) (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId)
    , slackToken : Maybe Evergreen.V120.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V120.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V120.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V120.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V120.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId, Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V120.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V120.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V120.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V120.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V120.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V120.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V120.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) Evergreen.V120.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) Evergreen.V120.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V120.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V120.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Coord.Coord Evergreen.V120.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V120.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V120.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V120.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V120.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V120.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V120.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V120.NonemptyDict.NonemptyDict Int Evergreen.V120.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V120.NonemptyDict.NonemptyDict Int Evergreen.V120.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V120.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V120.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V120.Editable.Msg Evergreen.V120.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V120.Editable.Msg (Maybe Evergreen.V120.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V120.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V120.Editable.Msg Evergreen.V120.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V120.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V120.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V120.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V120.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ) (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V120.Id.AnyGuildOrDmId Evergreen.V120.Id.ThreadRouteWithMessage Evergreen.V120.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V120.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V120.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V120.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V120.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId
        , otherUserId : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String
    | TypedDiscordLinkBookmarklet


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V120.Discord.UserAuth
    , user : Evergreen.V120.Discord.User
    , linkedTo : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V120.Discord.User
    , linkedTo : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId
    , guild : Evergreen.V120.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )) Int Evergreen.V120.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )) Int Evergreen.V120.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V120.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V120.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V120.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V120.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.SecretId.SecretId Evergreen.V120.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )) Evergreen.V120.PersonName.PersonName Evergreen.V120.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V120.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V120.Slack.OAuthCode Evergreen.V120.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V120.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V120.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V120.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V120.EmailAddress.EmailAddress (Result Evergreen.V120.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V120.EmailAddress.EmailAddress (Result Evergreen.V120.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V120.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Result Evergreen.V120.Discord.HttpError Evergreen.V120.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V120.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Result Evergreen.V120.Discord.HttpError Evergreen.V120.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) (Result Evergreen.V120.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) (Result Evergreen.V120.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) (Result Evergreen.V120.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) (Result Evergreen.V120.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji (Result Evergreen.V120.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji (Result Evergreen.V120.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji (Result Evergreen.V120.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji (Result Evergreen.V120.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V120.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V120.Discord.HttpError (List ( Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId, Maybe Evergreen.V120.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V120.Slack.CurrentUser
            , team : Evergreen.V120.Slack.Team
            , users : List Evergreen.V120.Slack.User
            , channels : List ( Evergreen.V120.Slack.Channel, List Evergreen.V120.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Result Effect.Http.Error Evergreen.V120.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.Discord.UserAuth (Result Evergreen.V120.Discord.HttpError Evergreen.V120.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Result Evergreen.V120.Discord.HttpError Evergreen.V120.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
        (Result
            Evergreen.V120.Discord.HttpError
            ( List ( Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId, Evergreen.V120.DmChannel.DiscordDmChannel, List Evergreen.V120.Discord.Message )
            , List
                ( Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId
                , { guild : Evergreen.V120.Discord.GatewayGuild
                  , channels : List ( Evergreen.V120.Discord.Channel, List Evergreen.V120.Discord.Message )
                  , icon : Maybe Evergreen.V120.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId, Evergreen.V120.Discord.Channel, List Evergreen.V120.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


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
    | AdminToFrontend Evergreen.V120.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V120.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V120.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V120.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V120.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V120.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) Evergreen.V120.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
