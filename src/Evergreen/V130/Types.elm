module Evergreen.V130.Types exposing (..)

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
import Evergreen.V130.AiChat
import Evergreen.V130.ChannelName
import Evergreen.V130.Coord
import Evergreen.V130.CssPixels
import Evergreen.V130.Discord
import Evergreen.V130.Discord.Id
import Evergreen.V130.DiscordAttachmentId
import Evergreen.V130.DmChannel
import Evergreen.V130.Editable
import Evergreen.V130.EmailAddress
import Evergreen.V130.Emoji
import Evergreen.V130.FileStatus
import Evergreen.V130.GuildName
import Evergreen.V130.Id
import Evergreen.V130.ImageEditor
import Evergreen.V130.Local
import Evergreen.V130.LocalState
import Evergreen.V130.Log
import Evergreen.V130.LoginForm
import Evergreen.V130.Message
import Evergreen.V130.MessageInput
import Evergreen.V130.MessageView
import Evergreen.V130.NonemptyDict
import Evergreen.V130.NonemptySet
import Evergreen.V130.OneToOne
import Evergreen.V130.Pages.Admin
import Evergreen.V130.PersonName
import Evergreen.V130.Ports
import Evergreen.V130.Postmark
import Evergreen.V130.RichText
import Evergreen.V130.Route
import Evergreen.V130.SecretId
import Evergreen.V130.SessionIdHash
import Evergreen.V130.Slack
import Evergreen.V130.TextEditor
import Evergreen.V130.Touch
import Evergreen.V130.TwoFactorAuthentication
import Evergreen.V130.Ui.Anim
import Evergreen.V130.User
import Evergreen.V130.UserAgent
import Evergreen.V130.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V130.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V130.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) Evergreen.V130.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) Evergreen.V130.LocalState.DiscordFrontendGuild
    , user : Evergreen.V130.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V130.SessionIdHash.SessionIdHash Evergreen.V130.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V130.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V130.Route.Route
    , windowSize : Evergreen.V130.Coord.Coord Evergreen.V130.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V130.Ports.NotificationPermission
    , pwaStatus : Evergreen.V130.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V130.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V130.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V130.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))) Evergreen.V130.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V130.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))) Evergreen.V130.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) Evergreen.V130.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.UserSession.ToBeFilledInByBackend (Evergreen.V130.SecretId.SecretId Evergreen.V130.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V130.GuildName.GuildName (Evergreen.V130.UserSession.ToBeFilledInByBackend (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage Evergreen.V130.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage Evergreen.V130.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V130.Id.GuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))) (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V130.Id.DiscordGuildOrDmId_DmData (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V130.UserSession.SetViewing
    | Local_SetName Evergreen.V130.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V130.Id.GuildOrDmId (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V130.Id.GuildOrDmId (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V130.Id.DiscordGuildOrDmId (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V130.Id.DiscordGuildOrDmId (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V130.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V130.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V130.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Effect.Time.Posix Evergreen.V130.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))) Evergreen.V130.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V130.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))) Evergreen.V130.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) Evergreen.V130.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.SecretId.SecretId Evergreen.V130.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V130.LocalState.JoinGuildError
            { guildId : Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId
            , guild : Evergreen.V130.LocalState.FrontendGuild
            , owner : Evergreen.V130.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.Id.GuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage Evergreen.V130.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.Id.GuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage Evergreen.V130.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage Evergreen.V130.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage Evergreen.V130.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.Id.GuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))) (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V130.Id.DiscordGuildOrDmId_DmData (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V130.SessionIdHash.SessionIdHash Evergreen.V130.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V130.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V130.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V130.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.NonemptySet.NonemptySet (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) Evergreen.V130.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) Evergreen.V130.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Maybe (Evergreen.V130.LocalState.LoadingDiscordChannel Int))


type LocalMsg
    = LocalChange (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) Evergreen.V130.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V130.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V130.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V130.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V130.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V130.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V130.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V130.Coord.Coord Evergreen.V130.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V130.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V130.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V130.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V130.Local.Local LocalMsg Evergreen.V130.LocalState.LocalState
    , admin : Maybe Evergreen.V130.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId, Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V130.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V130.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.NonemptyDict.NonemptyDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V130.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V130.TextEditor.Model
    , profilePictureEditor : Evergreen.V130.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V130.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V130.SecretId.SecretId Evergreen.V130.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V130.NonemptyDict.NonemptyDict Int Evergreen.V130.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V130.NonemptyDict.NonemptyDict Int Evergreen.V130.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V130.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V130.Coord.Coord Evergreen.V130.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V130.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V130.Ports.NotificationPermission
    , pwaStatus : Evergreen.V130.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V130.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V130.UserAgent.UserAgent
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
    , userId : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V130.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V130.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V130.Coord.Coord Evergreen.V130.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V130.Discord.PartialUser
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V130.Discord.UserAuth
    , user : Evergreen.V130.Discord.User
    , connection : Evergreen.V130.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V130.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V130.Discord.User
    , linkedTo : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V130.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V130.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V130.NonemptyDict.NonemptyDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V130.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V130.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V130.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) Evergreen.V130.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V130.DmChannel.DmChannelId Evergreen.V130.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) Evergreen.V130.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V130.OneToOne.OneToOne (Evergreen.V130.Slack.Id Evergreen.V130.Slack.ChannelId) Evergreen.V130.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V130.OneToOne.OneToOne String (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    , slackUsers : Evergreen.V130.OneToOne.OneToOne (Evergreen.V130.Slack.Id Evergreen.V130.Slack.UserId) (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
    , slackServers : Evergreen.V130.OneToOne.OneToOne (Evergreen.V130.Slack.Id Evergreen.V130.Slack.TeamId) (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    , slackToken : Maybe Evergreen.V130.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V130.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V130.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V130.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V130.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId, Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V130.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V130.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V130.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V130.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.LocalState.LoadingDiscordChannel (List Evergreen.V130.Discord.Message))
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V130.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V130.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V130.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V130.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) Evergreen.V130.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) Evergreen.V130.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V130.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V130.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Coord.Coord Evergreen.V130.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V130.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V130.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V130.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V130.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V130.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V130.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V130.NonemptyDict.NonemptyDict Int Evergreen.V130.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V130.NonemptyDict.NonemptyDict Int Evergreen.V130.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V130.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V130.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V130.Editable.Msg Evergreen.V130.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V130.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V130.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V130.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ) (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V130.Id.AnyGuildOrDmId Evergreen.V130.Id.ThreadRouteWithMessage Evergreen.V130.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V130.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V130.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V130.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V130.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId
        , otherUserId : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId)
    | TypedDiscordLinkBookmarklet


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )) Int Evergreen.V130.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )) Int Evergreen.V130.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V130.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V130.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V130.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V130.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.SecretId.SecretId Evergreen.V130.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )) Evergreen.V130.PersonName.PersonName Evergreen.V130.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V130.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V130.Slack.OAuthCode Evergreen.V130.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V130.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V130.ImageEditor.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V130.EmailAddress.EmailAddress (Result Evergreen.V130.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V130.EmailAddress.EmailAddress (Result Evergreen.V130.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V130.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMaybeMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Result Evergreen.V130.Discord.HttpError Evergreen.V130.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V130.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Result Evergreen.V130.Discord.HttpError Evergreen.V130.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) (Result Evergreen.V130.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) (Result Evergreen.V130.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) (Result Evergreen.V130.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) (Result Evergreen.V130.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji (Result Evergreen.V130.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji (Result Evergreen.V130.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji (Result Evergreen.V130.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji (Result Evergreen.V130.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V130.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V130.Discord.HttpError (List ( Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId, Maybe Evergreen.V130.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V130.Slack.CurrentUser
            , team : Evergreen.V130.Slack.Team
            , users : List Evergreen.V130.Slack.User
            , channels : List ( Evergreen.V130.Slack.Channel, List Evergreen.V130.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Result Effect.Http.Error Evergreen.V130.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.Discord.UserAuth (Result Evergreen.V130.Discord.HttpError Evergreen.V130.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Result Evergreen.V130.Discord.HttpError Evergreen.V130.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
        (Result
            Evergreen.V130.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId
                , { guild : Evergreen.V130.Discord.GatewayGuild
                  , channels : List Evergreen.V130.Discord.Channel
                  , icon : Maybe Evergreen.V130.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V130.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.AttachmentId, Evergreen.V130.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V130.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.AttachmentId, Evergreen.V130.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V130.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V130.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V130.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V130.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) (Result Evergreen.V130.Discord.HttpError (List Evergreen.V130.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Result Evergreen.V130.Discord.HttpError (List Evergreen.V130.Discord.Message))


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
    | AdminToFrontend Evergreen.V130.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V130.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V130.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V130.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V130.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V130.ImageEditor.ToFrontend
