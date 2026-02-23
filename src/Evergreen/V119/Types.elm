module Evergreen.V119.Types exposing (..)

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
import Evergreen.V119.AiChat
import Evergreen.V119.ChannelName
import Evergreen.V119.Coord
import Evergreen.V119.CssPixels
import Evergreen.V119.Discord
import Evergreen.V119.Discord.Id
import Evergreen.V119.DmChannel
import Evergreen.V119.Editable
import Evergreen.V119.EmailAddress
import Evergreen.V119.Emoji
import Evergreen.V119.FileStatus
import Evergreen.V119.GuildName
import Evergreen.V119.Id
import Evergreen.V119.ImageEditor
import Evergreen.V119.Local
import Evergreen.V119.LocalState
import Evergreen.V119.Log
import Evergreen.V119.LoginForm
import Evergreen.V119.Message
import Evergreen.V119.MessageInput
import Evergreen.V119.MessageView
import Evergreen.V119.NonemptyDict
import Evergreen.V119.NonemptySet
import Evergreen.V119.OneToOne
import Evergreen.V119.Pages.Admin
import Evergreen.V119.PersonName
import Evergreen.V119.Ports
import Evergreen.V119.Postmark
import Evergreen.V119.RichText
import Evergreen.V119.Route
import Evergreen.V119.SecretId
import Evergreen.V119.SessionIdHash
import Evergreen.V119.Slack
import Evergreen.V119.TextEditor
import Evergreen.V119.Touch
import Evergreen.V119.TwoFactorAuthentication
import Evergreen.V119.Ui.Anim
import Evergreen.V119.User
import Evergreen.V119.UserAgent
import Evergreen.V119.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V119.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V119.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) Evergreen.V119.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) Evergreen.V119.LocalState.DiscordFrontendGuild
    , user : Evergreen.V119.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V119.SessionIdHash.SessionIdHash Evergreen.V119.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V119.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V119.Route.Route
    , windowSize : Evergreen.V119.Coord.Coord Evergreen.V119.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V119.Ports.NotificationPermission
    , pwaStatus : Evergreen.V119.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V119.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V119.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V119.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))) Evergreen.V119.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V119.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))) Evergreen.V119.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) Evergreen.V119.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.UserSession.ToBeFilledInByBackend (Evergreen.V119.SecretId.SecretId Evergreen.V119.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V119.GuildName.GuildName (Evergreen.V119.UserSession.ToBeFilledInByBackend (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage Evergreen.V119.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage Evergreen.V119.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V119.Id.GuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))) (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V119.Id.DiscordGuildOrDmId_DmData (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V119.UserSession.SetViewing
    | Local_SetName Evergreen.V119.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V119.Id.GuildOrDmId (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V119.Id.GuildOrDmId (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V119.Id.DiscordGuildOrDmId (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V119.Id.DiscordGuildOrDmId (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V119.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V119.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V119.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Effect.Time.Posix Evergreen.V119.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))) Evergreen.V119.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V119.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))) Evergreen.V119.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) Evergreen.V119.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.SecretId.SecretId Evergreen.V119.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V119.LocalState.JoinGuildError
            { guildId : Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId
            , guild : Evergreen.V119.LocalState.FrontendGuild
            , owner : Evergreen.V119.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.Id.GuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage Evergreen.V119.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.Id.GuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage Evergreen.V119.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage Evergreen.V119.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage Evergreen.V119.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.Id.GuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))) (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V119.Id.DiscordGuildOrDmId_DmData (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V119.SessionIdHash.SessionIdHash Evergreen.V119.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V119.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V119.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V119.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.NonemptySet.NonemptySet (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) Evergreen.V119.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) Evergreen.V119.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)


type LocalMsg
    = LocalChange (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) Evergreen.V119.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V119.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V119.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V119.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V119.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V119.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V119.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V119.Coord.Coord Evergreen.V119.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V119.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V119.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V119.Editable.Model
    , slackClientSecret : Evergreen.V119.Editable.Model
    , publicVapidKey : Evergreen.V119.Editable.Model
    , privateVapidKey : Evergreen.V119.Editable.Model
    , openRouterKey : Evergreen.V119.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V119.Local.Local LocalMsg Evergreen.V119.LocalState.LocalState
    , admin : Maybe Evergreen.V119.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId, Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V119.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V119.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.NonemptyDict.NonemptyDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V119.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V119.TextEditor.Model
    , profilePictureEditor : Evergreen.V119.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V119.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V119.SecretId.SecretId Evergreen.V119.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V119.NonemptyDict.NonemptyDict Int Evergreen.V119.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V119.NonemptyDict.NonemptyDict Int Evergreen.V119.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V119.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V119.Coord.Coord Evergreen.V119.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V119.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V119.Ports.NotificationPermission
    , pwaStatus : Evergreen.V119.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V119.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V119.UserAgent.UserAgent
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
    , userId : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V119.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V119.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V119.Coord.Coord Evergreen.V119.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V119.Discord.PartialUser
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V119.Discord.UserAuth
    , user : Evergreen.V119.Discord.User
    , connection : Evergreen.V119.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V119.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V119.Discord.User
    , linkedTo : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias BackendModel =
    { users : Evergreen.V119.NonemptyDict.NonemptyDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V119.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V119.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V119.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) Evergreen.V119.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V119.DmChannel.DmChannelId Evergreen.V119.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) Evergreen.V119.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V119.OneToOne.OneToOne (Evergreen.V119.Slack.Id Evergreen.V119.Slack.ChannelId) Evergreen.V119.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V119.OneToOne.OneToOne String (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId)
    , slackUsers : Evergreen.V119.OneToOne.OneToOne (Evergreen.V119.Slack.Id Evergreen.V119.Slack.UserId) (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    , slackServers : Evergreen.V119.OneToOne.OneToOne (Evergreen.V119.Slack.Id Evergreen.V119.Slack.TeamId) (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId)
    , slackToken : Maybe Evergreen.V119.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V119.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V119.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V119.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V119.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId, Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V119.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V119.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V119.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V119.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V119.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V119.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V119.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) Evergreen.V119.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) Evergreen.V119.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V119.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V119.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Coord.Coord Evergreen.V119.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V119.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V119.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V119.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V119.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V119.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V119.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V119.NonemptyDict.NonemptyDict Int Evergreen.V119.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V119.NonemptyDict.NonemptyDict Int Evergreen.V119.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V119.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V119.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V119.Editable.Msg Evergreen.V119.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V119.Editable.Msg (Maybe Evergreen.V119.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V119.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V119.Editable.Msg Evergreen.V119.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V119.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V119.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V119.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V119.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ) (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V119.Id.AnyGuildOrDmId Evergreen.V119.Id.ThreadRouteWithMessage Evergreen.V119.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V119.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V119.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V119.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V119.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId
        , otherUserId : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String
    | TypedDiscordLinkBookmarklet


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V119.Discord.UserAuth
    , user : Evergreen.V119.Discord.User
    , linkedTo : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V119.Discord.User
    , linkedTo : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId
    , guild : Evergreen.V119.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )) Int Evergreen.V119.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )) Int Evergreen.V119.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V119.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V119.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V119.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V119.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.SecretId.SecretId Evergreen.V119.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )) Evergreen.V119.PersonName.PersonName Evergreen.V119.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V119.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V119.Slack.OAuthCode Evergreen.V119.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V119.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V119.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V119.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V119.EmailAddress.EmailAddress (Result Evergreen.V119.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V119.EmailAddress.EmailAddress (Result Evergreen.V119.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V119.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Result Evergreen.V119.Discord.HttpError Evergreen.V119.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V119.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Result Evergreen.V119.Discord.HttpError Evergreen.V119.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) (Result Evergreen.V119.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) (Result Evergreen.V119.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) (Result Evergreen.V119.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) (Result Evergreen.V119.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji (Result Evergreen.V119.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji (Result Evergreen.V119.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji (Result Evergreen.V119.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji (Result Evergreen.V119.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V119.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V119.Discord.HttpError (List ( Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId, Maybe Evergreen.V119.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V119.Slack.CurrentUser
            , team : Evergreen.V119.Slack.Team
            , users : List Evergreen.V119.Slack.User
            , channels : List ( Evergreen.V119.Slack.Channel, List Evergreen.V119.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Result Effect.Http.Error Evergreen.V119.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.Discord.UserAuth (Result Evergreen.V119.Discord.HttpError Evergreen.V119.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Result Evergreen.V119.Discord.HttpError Evergreen.V119.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
        (Result
            Evergreen.V119.Discord.HttpError
            ( List ( Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId, Evergreen.V119.DmChannel.DiscordDmChannel, List Evergreen.V119.Discord.Message )
            , List
                ( Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId
                , { guild : Evergreen.V119.Discord.GatewayGuild
                  , channels : List ( Evergreen.V119.Discord.Channel, List Evergreen.V119.Discord.Message )
                  , icon : Maybe Evergreen.V119.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId, Evergreen.V119.Discord.Channel, List Evergreen.V119.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


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
    | AdminToFrontend Evergreen.V119.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V119.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V119.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V119.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V119.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V119.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) Evergreen.V119.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
