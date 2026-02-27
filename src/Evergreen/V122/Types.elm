module Evergreen.V122.Types exposing (..)

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
import Evergreen.V122.AiChat
import Evergreen.V122.ChannelName
import Evergreen.V122.Coord
import Evergreen.V122.CssPixels
import Evergreen.V122.Discord
import Evergreen.V122.Discord.Id
import Evergreen.V122.DmChannel
import Evergreen.V122.Editable
import Evergreen.V122.EmailAddress
import Evergreen.V122.Emoji
import Evergreen.V122.FileStatus
import Evergreen.V122.GuildName
import Evergreen.V122.Id
import Evergreen.V122.ImageEditor
import Evergreen.V122.Local
import Evergreen.V122.LocalState
import Evergreen.V122.Log
import Evergreen.V122.LoginForm
import Evergreen.V122.Message
import Evergreen.V122.MessageInput
import Evergreen.V122.MessageView
import Evergreen.V122.NonemptyDict
import Evergreen.V122.NonemptySet
import Evergreen.V122.OneToOne
import Evergreen.V122.Pages.Admin
import Evergreen.V122.PersonName
import Evergreen.V122.Ports
import Evergreen.V122.Postmark
import Evergreen.V122.RichText
import Evergreen.V122.Route
import Evergreen.V122.SecretId
import Evergreen.V122.SessionIdHash
import Evergreen.V122.Slack
import Evergreen.V122.TextEditor
import Evergreen.V122.Touch
import Evergreen.V122.TwoFactorAuthentication
import Evergreen.V122.Ui.Anim
import Evergreen.V122.User
import Evergreen.V122.UserAgent
import Evergreen.V122.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V122.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V122.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) Evergreen.V122.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) Evergreen.V122.LocalState.DiscordFrontendGuild
    , user : Evergreen.V122.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V122.SessionIdHash.SessionIdHash Evergreen.V122.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V122.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V122.Route.Route
    , windowSize : Evergreen.V122.Coord.Coord Evergreen.V122.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V122.Ports.NotificationPermission
    , pwaStatus : Evergreen.V122.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V122.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V122.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V122.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))) Evergreen.V122.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V122.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))) Evergreen.V122.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) Evergreen.V122.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.UserSession.ToBeFilledInByBackend (Evergreen.V122.SecretId.SecretId Evergreen.V122.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V122.GuildName.GuildName (Evergreen.V122.UserSession.ToBeFilledInByBackend (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage Evergreen.V122.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage Evergreen.V122.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V122.Id.GuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))) (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V122.Id.DiscordGuildOrDmId_DmData (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V122.UserSession.SetViewing
    | Local_SetName Evergreen.V122.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V122.Id.GuildOrDmId (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V122.Id.GuildOrDmId (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V122.Id.DiscordGuildOrDmId (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V122.Id.DiscordGuildOrDmId (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V122.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V122.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V122.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Effect.Time.Posix Evergreen.V122.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))) Evergreen.V122.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V122.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))) Evergreen.V122.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) Evergreen.V122.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.SecretId.SecretId Evergreen.V122.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V122.LocalState.JoinGuildError
            { guildId : Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId
            , guild : Evergreen.V122.LocalState.FrontendGuild
            , owner : Evergreen.V122.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.Id.GuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage Evergreen.V122.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.Id.GuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage Evergreen.V122.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage Evergreen.V122.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage Evergreen.V122.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.Id.GuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))) (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V122.Id.DiscordGuildOrDmId_DmData (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V122.SessionIdHash.SessionIdHash Evergreen.V122.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V122.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V122.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V122.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.NonemptySet.NonemptySet (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) Evergreen.V122.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) Evergreen.V122.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)


type LocalMsg
    = LocalChange (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) Evergreen.V122.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V122.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V122.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V122.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V122.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V122.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V122.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V122.Coord.Coord Evergreen.V122.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V122.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V122.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V122.Editable.Model
    , slackClientSecret : Evergreen.V122.Editable.Model
    , publicVapidKey : Evergreen.V122.Editable.Model
    , privateVapidKey : Evergreen.V122.Editable.Model
    , openRouterKey : Evergreen.V122.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V122.Local.Local LocalMsg Evergreen.V122.LocalState.LocalState
    , admin : Maybe Evergreen.V122.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId, Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V122.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V122.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.NonemptyDict.NonemptyDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V122.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V122.TextEditor.Model
    , profilePictureEditor : Evergreen.V122.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V122.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V122.SecretId.SecretId Evergreen.V122.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V122.NonemptyDict.NonemptyDict Int Evergreen.V122.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V122.NonemptyDict.NonemptyDict Int Evergreen.V122.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V122.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V122.Coord.Coord Evergreen.V122.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V122.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V122.Ports.NotificationPermission
    , pwaStatus : Evergreen.V122.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V122.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V122.UserAgent.UserAgent
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
    , userId : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V122.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V122.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V122.Coord.Coord Evergreen.V122.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V122.Discord.PartialUser
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V122.Discord.UserAuth
    , user : Evergreen.V122.Discord.User
    , connection : Evergreen.V122.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V122.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V122.Discord.User
    , linkedTo : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V122.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V122.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V122.NonemptyDict.NonemptyDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V122.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V122.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V122.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) Evergreen.V122.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V122.DmChannel.DmChannelId Evergreen.V122.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) Evergreen.V122.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V122.OneToOne.OneToOne (Evergreen.V122.Slack.Id Evergreen.V122.Slack.ChannelId) Evergreen.V122.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V122.OneToOne.OneToOne String (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId)
    , slackUsers : Evergreen.V122.OneToOne.OneToOne (Evergreen.V122.Slack.Id Evergreen.V122.Slack.UserId) (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    , slackServers : Evergreen.V122.OneToOne.OneToOne (Evergreen.V122.Slack.Id Evergreen.V122.Slack.TeamId) (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId)
    , slackToken : Maybe Evergreen.V122.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V122.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V122.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V122.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V122.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId, Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V122.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V122.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V122.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict String DiscordAttachmentData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V122.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V122.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V122.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V122.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) Evergreen.V122.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) Evergreen.V122.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V122.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V122.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Coord.Coord Evergreen.V122.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V122.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V122.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V122.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V122.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V122.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V122.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V122.NonemptyDict.NonemptyDict Int Evergreen.V122.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V122.NonemptyDict.NonemptyDict Int Evergreen.V122.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V122.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V122.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V122.Editable.Msg Evergreen.V122.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V122.Editable.Msg (Maybe Evergreen.V122.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V122.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V122.Editable.Msg Evergreen.V122.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V122.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V122.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V122.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V122.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ) (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V122.Id.AnyGuildOrDmId Evergreen.V122.Id.ThreadRouteWithMessage Evergreen.V122.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V122.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V122.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V122.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V122.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
        , otherUserId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String
    | TypedDiscordLinkBookmarklet


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V122.Discord.UserAuth
    , user : Evergreen.V122.Discord.User
    , linkedTo : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V122.Discord.User
    , linkedTo : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId
    , guild : Evergreen.V122.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )) Int Evergreen.V122.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )) Int Evergreen.V122.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V122.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V122.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V122.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V122.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.SecretId.SecretId Evergreen.V122.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )) Evergreen.V122.PersonName.PersonName Evergreen.V122.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V122.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V122.Slack.OAuthCode Evergreen.V122.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V122.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V122.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V122.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type alias DiscordDmChannelReadyData =
    { dmChannelId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId
    , dmChannel : Evergreen.V122.DmChannel.DiscordDmChannel
    , messages : List Evergreen.V122.Discord.Message
    , uploadResponses : List (Result Effect.Http.Error ( String, Evergreen.V122.FileStatus.UploadResponse ))
    }


type alias DiscordThreadReadyData =
    { channelId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId
    , channel : Evergreen.V122.Discord.Channel
    , messages : List Evergreen.V122.Discord.Message
    , uploadResponses : List (Result Effect.Http.Error ( String, Evergreen.V122.FileStatus.UploadResponse ))
    }


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V122.EmailAddress.EmailAddress (Result Evergreen.V122.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V122.EmailAddress.EmailAddress (Result Evergreen.V122.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V122.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMaybeMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Result Evergreen.V122.Discord.HttpError Evergreen.V122.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V122.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Result Evergreen.V122.Discord.HttpError Evergreen.V122.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) (Result Evergreen.V122.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) (Result Evergreen.V122.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) (Result Evergreen.V122.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) (Result Evergreen.V122.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji (Result Evergreen.V122.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji (Result Evergreen.V122.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji (Result Evergreen.V122.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji (Result Evergreen.V122.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V122.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V122.Discord.HttpError (List ( Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId, Maybe Evergreen.V122.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V122.Slack.CurrentUser
            , team : Evergreen.V122.Slack.Team
            , users : List Evergreen.V122.Slack.User
            , channels : List ( Evergreen.V122.Slack.Channel, List Evergreen.V122.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Result Effect.Http.Error Evergreen.V122.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.Discord.UserAuth (Result Evergreen.V122.Discord.HttpError Evergreen.V122.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Result Evergreen.V122.Discord.HttpError Evergreen.V122.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
        (Result
            Evergreen.V122.Discord.HttpError
            ( List DiscordDmChannelReadyData
            , List
                ( Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId
                , { guild : Evergreen.V122.Discord.GatewayGuild
                  , channels : List ( Evergreen.V122.Discord.Channel, List Evergreen.V122.Discord.Message, List (Result Effect.Http.Error ( String, Evergreen.V122.FileStatus.UploadResponse )) )
                  , icon : Maybe Evergreen.V122.FileStatus.UploadResponse
                  , threads : List DiscordThreadReadyData
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V122.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.AttachmentId, Evergreen.V122.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V122.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.AttachmentId, Evergreen.V122.FileStatus.UploadResponse )))


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
    | AdminToFrontend Evergreen.V122.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V122.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V122.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V122.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V122.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V122.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) Evergreen.V122.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
