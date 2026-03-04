module Evergreen.V128.Types exposing (..)

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
import Evergreen.V128.AiChat
import Evergreen.V128.ChannelName
import Evergreen.V128.Coord
import Evergreen.V128.CssPixels
import Evergreen.V128.Discord
import Evergreen.V128.Discord.Id
import Evergreen.V128.DiscordAttachmentId
import Evergreen.V128.DmChannel
import Evergreen.V128.Editable
import Evergreen.V128.EmailAddress
import Evergreen.V128.Emoji
import Evergreen.V128.FileStatus
import Evergreen.V128.GuildName
import Evergreen.V128.Id
import Evergreen.V128.ImageEditor
import Evergreen.V128.Local
import Evergreen.V128.LocalState
import Evergreen.V128.Log
import Evergreen.V128.LoginForm
import Evergreen.V128.Message
import Evergreen.V128.MessageInput
import Evergreen.V128.MessageView
import Evergreen.V128.NonemptyDict
import Evergreen.V128.NonemptySet
import Evergreen.V128.OneToOne
import Evergreen.V128.Pages.Admin
import Evergreen.V128.PersonName
import Evergreen.V128.Ports
import Evergreen.V128.Postmark
import Evergreen.V128.RichText
import Evergreen.V128.Route
import Evergreen.V128.SecretId
import Evergreen.V128.SessionIdHash
import Evergreen.V128.Slack
import Evergreen.V128.TextEditor
import Evergreen.V128.Touch
import Evergreen.V128.TwoFactorAuthentication
import Evergreen.V128.Ui.Anim
import Evergreen.V128.User
import Evergreen.V128.UserAgent
import Evergreen.V128.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V128.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V128.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) Evergreen.V128.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) Evergreen.V128.LocalState.DiscordFrontendGuild
    , user : Evergreen.V128.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V128.SessionIdHash.SessionIdHash Evergreen.V128.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V128.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V128.Route.Route
    , windowSize : Evergreen.V128.Coord.Coord Evergreen.V128.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V128.Ports.NotificationPermission
    , pwaStatus : Evergreen.V128.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V128.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V128.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V128.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))) Evergreen.V128.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V128.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))) Evergreen.V128.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) Evergreen.V128.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.UserSession.ToBeFilledInByBackend (Evergreen.V128.SecretId.SecretId Evergreen.V128.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V128.GuildName.GuildName (Evergreen.V128.UserSession.ToBeFilledInByBackend (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage Evergreen.V128.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage Evergreen.V128.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V128.Id.GuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))) (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V128.Id.DiscordGuildOrDmId_DmData (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V128.UserSession.SetViewing
    | Local_SetName Evergreen.V128.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V128.Id.GuildOrDmId (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V128.Id.GuildOrDmId (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V128.Id.DiscordGuildOrDmId (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V128.Id.DiscordGuildOrDmId (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V128.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V128.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V128.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Effect.Time.Posix Evergreen.V128.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))) Evergreen.V128.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V128.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))) Evergreen.V128.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) Evergreen.V128.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.SecretId.SecretId Evergreen.V128.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V128.LocalState.JoinGuildError
            { guildId : Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId
            , guild : Evergreen.V128.LocalState.FrontendGuild
            , owner : Evergreen.V128.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.Id.GuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage Evergreen.V128.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.Id.GuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage Evergreen.V128.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage Evergreen.V128.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage Evergreen.V128.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.Id.GuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))) (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V128.Id.DiscordGuildOrDmId_DmData (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V128.SessionIdHash.SessionIdHash Evergreen.V128.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V128.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V128.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V128.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.NonemptySet.NonemptySet (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) Evergreen.V128.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) Evergreen.V128.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Maybe (Evergreen.V128.LocalState.LoadingDiscordChannel Int))


type LocalMsg
    = LocalChange (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) Evergreen.V128.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V128.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V128.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V128.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V128.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V128.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V128.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V128.Coord.Coord Evergreen.V128.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V128.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V128.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V128.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V128.Local.Local LocalMsg Evergreen.V128.LocalState.LocalState
    , admin : Maybe Evergreen.V128.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId, Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V128.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V128.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.NonemptyDict.NonemptyDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V128.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V128.TextEditor.Model
    , profilePictureEditor : Evergreen.V128.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V128.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V128.SecretId.SecretId Evergreen.V128.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V128.NonemptyDict.NonemptyDict Int Evergreen.V128.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V128.NonemptyDict.NonemptyDict Int Evergreen.V128.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V128.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V128.Coord.Coord Evergreen.V128.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V128.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V128.Ports.NotificationPermission
    , pwaStatus : Evergreen.V128.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V128.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V128.UserAgent.UserAgent
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
    , userId : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V128.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V128.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V128.Coord.Coord Evergreen.V128.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V128.Discord.PartialUser
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V128.Discord.UserAuth
    , user : Evergreen.V128.Discord.User
    , connection : Evergreen.V128.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V128.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V128.Discord.User
    , linkedTo : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V128.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V128.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V128.NonemptyDict.NonemptyDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V128.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V128.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V128.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) Evergreen.V128.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V128.DmChannel.DmChannelId Evergreen.V128.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) Evergreen.V128.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V128.OneToOne.OneToOne (Evergreen.V128.Slack.Id Evergreen.V128.Slack.ChannelId) Evergreen.V128.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V128.OneToOne.OneToOne String (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    , slackUsers : Evergreen.V128.OneToOne.OneToOne (Evergreen.V128.Slack.Id Evergreen.V128.Slack.UserId) (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    , slackServers : Evergreen.V128.OneToOne.OneToOne (Evergreen.V128.Slack.Id Evergreen.V128.Slack.TeamId) (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    , slackToken : Maybe Evergreen.V128.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V128.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V128.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V128.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V128.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId, Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V128.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V128.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V128.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V128.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.LocalState.LoadingDiscordChannel (List Evergreen.V128.Discord.Message))
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V128.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V128.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V128.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V128.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) Evergreen.V128.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) Evergreen.V128.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V128.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V128.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Coord.Coord Evergreen.V128.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V128.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V128.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V128.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V128.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V128.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V128.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V128.NonemptyDict.NonemptyDict Int Evergreen.V128.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V128.NonemptyDict.NonemptyDict Int Evergreen.V128.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V128.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V128.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V128.Editable.Msg Evergreen.V128.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V128.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V128.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V128.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ) (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V128.Id.AnyGuildOrDmId Evergreen.V128.Id.ThreadRouteWithMessage Evergreen.V128.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V128.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V128.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V128.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V128.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId
        , otherUserId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String
    | TypedDiscordLinkBookmarklet


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V128.Discord.UserAuth
    , user : Evergreen.V128.Discord.User
    , linkedTo : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V128.Discord.User
    , linkedTo : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId
    , guild : Evergreen.V128.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )) Int Evergreen.V128.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )) Int Evergreen.V128.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V128.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V128.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V128.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V128.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.SecretId.SecretId Evergreen.V128.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )) Evergreen.V128.PersonName.PersonName Evergreen.V128.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V128.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V128.Slack.OAuthCode Evergreen.V128.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V128.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V128.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V128.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V128.EmailAddress.EmailAddress (Result Evergreen.V128.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V128.EmailAddress.EmailAddress (Result Evergreen.V128.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V128.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMaybeMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Result Evergreen.V128.Discord.HttpError Evergreen.V128.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V128.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Result Evergreen.V128.Discord.HttpError Evergreen.V128.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) (Result Evergreen.V128.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) (Result Evergreen.V128.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) (Result Evergreen.V128.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) (Result Evergreen.V128.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji (Result Evergreen.V128.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji (Result Evergreen.V128.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji (Result Evergreen.V128.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji (Result Evergreen.V128.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V128.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V128.Discord.HttpError (List ( Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId, Maybe Evergreen.V128.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V128.Slack.CurrentUser
            , team : Evergreen.V128.Slack.Team
            , users : List Evergreen.V128.Slack.User
            , channels : List ( Evergreen.V128.Slack.Channel, List Evergreen.V128.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Result Effect.Http.Error Evergreen.V128.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.Discord.UserAuth (Result Evergreen.V128.Discord.HttpError Evergreen.V128.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Result Evergreen.V128.Discord.HttpError Evergreen.V128.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
        (Result
            Evergreen.V128.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId
                , { guild : Evergreen.V128.Discord.GatewayGuild
                  , channels : List Evergreen.V128.Discord.Channel
                  , icon : Maybe Evergreen.V128.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V128.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.AttachmentId, Evergreen.V128.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V128.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.AttachmentId, Evergreen.V128.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V128.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V128.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V128.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V128.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) (Result Evergreen.V128.Discord.HttpError (List Evergreen.V128.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Result Evergreen.V128.Discord.HttpError (List Evergreen.V128.Discord.Message))


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
    | AdminToFrontend Evergreen.V128.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V128.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V128.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V128.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V128.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V128.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
