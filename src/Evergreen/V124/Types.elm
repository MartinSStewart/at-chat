module Evergreen.V124.Types exposing (..)

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
import Evergreen.V124.AiChat
import Evergreen.V124.ChannelName
import Evergreen.V124.Coord
import Evergreen.V124.CssPixels
import Evergreen.V124.Discord
import Evergreen.V124.Discord.Id
import Evergreen.V124.DmChannel
import Evergreen.V124.Editable
import Evergreen.V124.EmailAddress
import Evergreen.V124.Emoji
import Evergreen.V124.FileStatus
import Evergreen.V124.GuildName
import Evergreen.V124.Id
import Evergreen.V124.ImageEditor
import Evergreen.V124.Local
import Evergreen.V124.LocalState
import Evergreen.V124.Log
import Evergreen.V124.LoginForm
import Evergreen.V124.Message
import Evergreen.V124.MessageInput
import Evergreen.V124.MessageView
import Evergreen.V124.NonemptyDict
import Evergreen.V124.NonemptySet
import Evergreen.V124.OneToOne
import Evergreen.V124.Pages.Admin
import Evergreen.V124.PersonName
import Evergreen.V124.Ports
import Evergreen.V124.Postmark
import Evergreen.V124.RichText
import Evergreen.V124.Route
import Evergreen.V124.SecretId
import Evergreen.V124.SessionIdHash
import Evergreen.V124.Slack
import Evergreen.V124.TextEditor
import Evergreen.V124.Touch
import Evergreen.V124.TwoFactorAuthentication
import Evergreen.V124.Ui.Anim
import Evergreen.V124.User
import Evergreen.V124.UserAgent
import Evergreen.V124.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V124.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V124.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) Evergreen.V124.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) Evergreen.V124.LocalState.DiscordFrontendGuild
    , user : Evergreen.V124.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V124.SessionIdHash.SessionIdHash Evergreen.V124.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V124.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V124.Route.Route
    , windowSize : Evergreen.V124.Coord.Coord Evergreen.V124.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V124.Ports.NotificationPermission
    , pwaStatus : Evergreen.V124.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V124.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V124.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V124.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))) Evergreen.V124.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V124.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))) Evergreen.V124.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) Evergreen.V124.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.UserSession.ToBeFilledInByBackend (Evergreen.V124.SecretId.SecretId Evergreen.V124.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V124.GuildName.GuildName (Evergreen.V124.UserSession.ToBeFilledInByBackend (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage Evergreen.V124.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage Evergreen.V124.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V124.Id.GuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))) (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V124.Id.DiscordGuildOrDmId_DmData (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V124.UserSession.SetViewing
    | Local_SetName Evergreen.V124.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V124.Id.GuildOrDmId (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V124.Id.GuildOrDmId (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V124.Id.DiscordGuildOrDmId (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V124.Id.DiscordGuildOrDmId (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V124.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V124.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V124.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Effect.Time.Posix Evergreen.V124.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))) Evergreen.V124.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V124.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))) Evergreen.V124.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) Evergreen.V124.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.SecretId.SecretId Evergreen.V124.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V124.LocalState.JoinGuildError
            { guildId : Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId
            , guild : Evergreen.V124.LocalState.FrontendGuild
            , owner : Evergreen.V124.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Id.GuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage Evergreen.V124.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Id.GuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage Evergreen.V124.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage Evergreen.V124.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage Evergreen.V124.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Id.GuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))) (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V124.Id.DiscordGuildOrDmId_DmData (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V124.SessionIdHash.SessionIdHash Evergreen.V124.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V124.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V124.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V124.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.NonemptySet.NonemptySet (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) Evergreen.V124.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) Evergreen.V124.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)


type LocalMsg
    = LocalChange (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) Evergreen.V124.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V124.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V124.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V124.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V124.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V124.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V124.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V124.Coord.Coord Evergreen.V124.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V124.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V124.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V124.Editable.Model
    , slackClientSecret : Evergreen.V124.Editable.Model
    , publicVapidKey : Evergreen.V124.Editable.Model
    , privateVapidKey : Evergreen.V124.Editable.Model
    , openRouterKey : Evergreen.V124.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V124.Local.Local LocalMsg Evergreen.V124.LocalState.LocalState
    , admin : Maybe Evergreen.V124.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId, Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V124.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V124.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.NonemptyDict.NonemptyDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V124.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V124.TextEditor.Model
    , profilePictureEditor : Evergreen.V124.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V124.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V124.SecretId.SecretId Evergreen.V124.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V124.NonemptyDict.NonemptyDict Int Evergreen.V124.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V124.NonemptyDict.NonemptyDict Int Evergreen.V124.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V124.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V124.Coord.Coord Evergreen.V124.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V124.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V124.Ports.NotificationPermission
    , pwaStatus : Evergreen.V124.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V124.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V124.UserAgent.UserAgent
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
    , userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V124.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V124.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V124.Coord.Coord Evergreen.V124.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V124.Discord.PartialUser
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V124.Discord.UserAuth
    , user : Evergreen.V124.Discord.User
    , connection : Evergreen.V124.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V124.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V124.Discord.User
    , linkedTo : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V124.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V124.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V124.NonemptyDict.NonemptyDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V124.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V124.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V124.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) Evergreen.V124.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V124.DmChannel.DmChannelId Evergreen.V124.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) Evergreen.V124.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V124.OneToOne.OneToOne (Evergreen.V124.Slack.Id Evergreen.V124.Slack.ChannelId) Evergreen.V124.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V124.OneToOne.OneToOne String (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
    , slackUsers : Evergreen.V124.OneToOne.OneToOne (Evergreen.V124.Slack.Id Evergreen.V124.Slack.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    , slackServers : Evergreen.V124.OneToOne.OneToOne (Evergreen.V124.Slack.Id Evergreen.V124.Slack.TeamId) (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
    , slackToken : Maybe Evergreen.V124.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V124.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V124.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V124.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V124.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId, Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V124.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V124.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V124.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict String DiscordAttachmentData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V124.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V124.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V124.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V124.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) Evergreen.V124.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) Evergreen.V124.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V124.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V124.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Coord.Coord Evergreen.V124.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V124.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V124.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V124.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V124.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V124.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V124.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V124.NonemptyDict.NonemptyDict Int Evergreen.V124.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V124.NonemptyDict.NonemptyDict Int Evergreen.V124.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V124.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V124.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V124.Editable.Msg Evergreen.V124.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V124.Editable.Msg (Maybe Evergreen.V124.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V124.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V124.Editable.Msg Evergreen.V124.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V124.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V124.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V124.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V124.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ) (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V124.Id.AnyGuildOrDmId Evergreen.V124.Id.ThreadRouteWithMessage Evergreen.V124.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V124.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V124.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V124.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V124.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
        , otherUserId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String
    | TypedDiscordLinkBookmarklet


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V124.Discord.UserAuth
    , user : Evergreen.V124.Discord.User
    , linkedTo : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V124.Discord.User
    , linkedTo : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId
    , guild : Evergreen.V124.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )) Int Evergreen.V124.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )) Int Evergreen.V124.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V124.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V124.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V124.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V124.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.SecretId.SecretId Evergreen.V124.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )) Evergreen.V124.PersonName.PersonName Evergreen.V124.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V124.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V124.Slack.OAuthCode Evergreen.V124.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V124.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V124.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V124.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type alias DiscordDmChannelReadyData =
    { dmChannelId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId
    , dmChannel : Evergreen.V124.DmChannel.DiscordDmChannel
    , messages : List Evergreen.V124.Discord.Message
    , uploadResponses : List (Result Effect.Http.Error ( String, Evergreen.V124.FileStatus.UploadResponse ))
    }


type alias DiscordThreadReadyData =
    { channelId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId
    , channel : Evergreen.V124.Discord.Channel
    , messages : List Evergreen.V124.Discord.Message
    , uploadResponses : List (Result Effect.Http.Error ( String, Evergreen.V124.FileStatus.UploadResponse ))
    }


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V124.EmailAddress.EmailAddress (Result Evergreen.V124.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V124.EmailAddress.EmailAddress (Result Evergreen.V124.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V124.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMaybeMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Result Evergreen.V124.Discord.HttpError Evergreen.V124.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V124.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Result Evergreen.V124.Discord.HttpError Evergreen.V124.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) (Result Evergreen.V124.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) (Result Evergreen.V124.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) (Result Evergreen.V124.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) (Result Evergreen.V124.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji (Result Evergreen.V124.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji (Result Evergreen.V124.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji (Result Evergreen.V124.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji (Result Evergreen.V124.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V124.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V124.Discord.HttpError (List ( Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId, Maybe Evergreen.V124.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V124.Slack.CurrentUser
            , team : Evergreen.V124.Slack.Team
            , users : List Evergreen.V124.Slack.User
            , channels : List ( Evergreen.V124.Slack.Channel, List Evergreen.V124.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Result Effect.Http.Error Evergreen.V124.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Discord.UserAuth (Result Evergreen.V124.Discord.HttpError Evergreen.V124.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Result Evergreen.V124.Discord.HttpError Evergreen.V124.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
        (Result
            Evergreen.V124.Discord.HttpError
            ( List DiscordDmChannelReadyData
            , List
                ( Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId
                , { guild : Evergreen.V124.Discord.GatewayGuild
                  , channels : List ( Evergreen.V124.Discord.Channel, List Evergreen.V124.Discord.Message, List (Result Effect.Http.Error ( String, Evergreen.V124.FileStatus.UploadResponse )) )
                  , icon : Maybe Evergreen.V124.FileStatus.UploadResponse
                  , threads : List DiscordThreadReadyData
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V124.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.AttachmentId, Evergreen.V124.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V124.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.AttachmentId, Evergreen.V124.FileStatus.UploadResponse )))


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
    | AdminToFrontend Evergreen.V124.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V124.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V124.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V124.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V124.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V124.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) Evergreen.V124.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
