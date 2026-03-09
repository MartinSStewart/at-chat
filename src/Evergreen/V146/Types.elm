module Evergreen.V146.Types exposing (..)

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
import Evergreen.V146.AiChat
import Evergreen.V146.ChannelName
import Evergreen.V146.Coord
import Evergreen.V146.CssPixels
import Evergreen.V146.Discord
import Evergreen.V146.DiscordAttachmentId
import Evergreen.V146.DiscordUserData
import Evergreen.V146.DmChannel
import Evergreen.V146.Editable
import Evergreen.V146.EmailAddress
import Evergreen.V146.Emoji
import Evergreen.V146.FileStatus
import Evergreen.V146.GuildName
import Evergreen.V146.Id
import Evergreen.V146.ImageEditor
import Evergreen.V146.Local
import Evergreen.V146.LocalState
import Evergreen.V146.Log
import Evergreen.V146.LoginForm
import Evergreen.V146.Message
import Evergreen.V146.MessageInput
import Evergreen.V146.MessageView
import Evergreen.V146.NonemptyDict
import Evergreen.V146.NonemptySet
import Evergreen.V146.OneToOne
import Evergreen.V146.Pages.Admin
import Evergreen.V146.PersonName
import Evergreen.V146.Ports
import Evergreen.V146.Postmark
import Evergreen.V146.RichText
import Evergreen.V146.Route
import Evergreen.V146.SecretId
import Evergreen.V146.SessionIdHash
import Evergreen.V146.Slack
import Evergreen.V146.TextEditor
import Evergreen.V146.Touch
import Evergreen.V146.TwoFactorAuthentication
import Evergreen.V146.Ui.Anim
import Evergreen.V146.User
import Evergreen.V146.UserAgent
import Evergreen.V146.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V146.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V146.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) Evergreen.V146.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) Evergreen.V146.LocalState.DiscordFrontendGuild
    , user : Evergreen.V146.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V146.SessionIdHash.SessionIdHash Evergreen.V146.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V146.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V146.Route.Route
    , windowSize : Evergreen.V146.Coord.Coord Evergreen.V146.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V146.Ports.NotificationPermission
    , pwaStatus : Evergreen.V146.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V146.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V146.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V146.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))) Evergreen.V146.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V146.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))) Evergreen.V146.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) Evergreen.V146.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.UserSession.ToBeFilledInByBackend (Evergreen.V146.SecretId.SecretId Evergreen.V146.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V146.GuildName.GuildName (Evergreen.V146.UserSession.ToBeFilledInByBackend (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage Evergreen.V146.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage Evergreen.V146.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V146.Id.GuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))) (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V146.Id.DiscordGuildOrDmId_DmData (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V146.UserSession.SetViewing
    | Local_SetName Evergreen.V146.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V146.Id.GuildOrDmId (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V146.Id.GuildOrDmId (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V146.Id.DiscordGuildOrDmId (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V146.Id.DiscordGuildOrDmId (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V146.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V146.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V146.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Effect.Time.Posix Evergreen.V146.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))) Evergreen.V146.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V146.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))) Evergreen.V146.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) Evergreen.V146.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.SecretId.SecretId Evergreen.V146.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V146.LocalState.JoinGuildError
            { guildId : Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId
            , guild : Evergreen.V146.LocalState.FrontendGuild
            , owner : Evergreen.V146.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.Id.GuildOrDmId Evergreen.V146.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.Id.GuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage Evergreen.V146.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.Id.GuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage Evergreen.V146.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage Evergreen.V146.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage Evergreen.V146.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.Id.GuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))) (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V146.Id.DiscordGuildOrDmId_DmData (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V146.SessionIdHash.SessionIdHash Evergreen.V146.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V146.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V146.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V146.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.NonemptySet.NonemptySet (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) Evergreen.V146.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) Evergreen.V146.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Maybe (Evergreen.V146.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V146.Pages.Admin.InitAdminData


type LocalMsg
    = LocalChange (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) Evergreen.V146.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V146.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V146.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V146.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V146.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V146.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V146.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V146.Coord.Coord Evergreen.V146.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V146.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V146.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V146.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V146.Local.Local LocalMsg Evergreen.V146.LocalState.LocalState
    , admin : Evergreen.V146.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId, Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V146.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V146.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.NonemptyDict.NonemptyDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V146.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V146.TextEditor.Model
    , profilePictureEditor : Evergreen.V146.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V146.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V146.SecretId.SecretId Evergreen.V146.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V146.NonemptyDict.NonemptyDict Int Evergreen.V146.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V146.NonemptyDict.NonemptyDict Int Evergreen.V146.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V146.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V146.Coord.Coord Evergreen.V146.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V146.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V146.Ports.NotificationPermission
    , pwaStatus : Evergreen.V146.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V146.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V146.UserAgent.UserAgent
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
    , userId : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V146.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V146.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V146.Coord.Coord Evergreen.V146.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V146.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V146.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V146.NonemptyDict.NonemptyDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V146.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V146.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V146.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) Evergreen.V146.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V146.DmChannel.DmChannelId Evergreen.V146.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) Evergreen.V146.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V146.OneToOne.OneToOne (Evergreen.V146.Slack.Id Evergreen.V146.Slack.ChannelId) Evergreen.V146.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V146.OneToOne.OneToOne String (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    , slackUsers : Evergreen.V146.OneToOne.OneToOne (Evergreen.V146.Slack.Id Evergreen.V146.Slack.UserId) (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
    , slackServers : Evergreen.V146.OneToOne.OneToOne (Evergreen.V146.Slack.Id Evergreen.V146.Slack.TeamId) (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    , slackToken : Maybe Evergreen.V146.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V146.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V146.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V146.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V146.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId, Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V146.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V146.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V146.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V146.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.LocalState.LoadingDiscordChannel (List Evergreen.V146.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V146.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V146.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V146.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V146.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) Evergreen.V146.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) Evergreen.V146.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V146.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V146.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Coord.Coord Evergreen.V146.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V146.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V146.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V146.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V146.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V146.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V146.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V146.NonemptyDict.NonemptyDict Int Evergreen.V146.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V146.NonemptyDict.NonemptyDict Int Evergreen.V146.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V146.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V146.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V146.Editable.Msg Evergreen.V146.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V146.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V146.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V146.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute ) (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRouteWithMessage Evergreen.V146.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V146.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V146.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V146.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V146.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId
        , otherUserId : Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V146.Id.AnyGuildOrDmId Evergreen.V146.Id.ThreadRoute
    | InitialLoadRequested_Admin
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V146.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V146.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V146.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V146.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V146.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V146.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.SecretId.SecretId Evergreen.V146.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V146.PersonName.PersonName Evergreen.V146.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V146.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V146.Slack.OAuthCode Evergreen.V146.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V146.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V146.ImageEditor.ToBackend
    | AdminDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V146.EmailAddress.EmailAddress (Result Evergreen.V146.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V146.EmailAddress.EmailAddress (Result Evergreen.V146.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V146.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMaybeMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Result Evergreen.V146.Discord.HttpError Evergreen.V146.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V146.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Result Evergreen.V146.Discord.HttpError Evergreen.V146.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) (Result Evergreen.V146.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) (Result Evergreen.V146.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) (Result Evergreen.V146.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) (Result Evergreen.V146.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji (Result Evergreen.V146.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji (Result Evergreen.V146.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji (Result Evergreen.V146.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji (Result Evergreen.V146.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V146.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V146.Discord.HttpError (List ( Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId, Maybe Evergreen.V146.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V146.Slack.CurrentUser
            , team : Evergreen.V146.Slack.Team
            , users : List Evergreen.V146.Slack.User
            , channels : List ( Evergreen.V146.Slack.Channel, List Evergreen.V146.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Result Effect.Http.Error Evergreen.V146.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.Discord.UserAuth (Result Evergreen.V146.Discord.HttpError Evergreen.V146.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Result Evergreen.V146.Discord.HttpError Evergreen.V146.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
        (Result
            Evergreen.V146.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId
                , members : List (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
                }
            , List
                ( Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId
                , { guild : Evergreen.V146.Discord.GatewayGuild
                  , channels : List Evergreen.V146.Discord.Channel
                  , icon : Maybe Evergreen.V146.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V146.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V146.Discord.Id Evergreen.V146.Discord.AttachmentId, Evergreen.V146.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V146.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V146.Discord.Id Evergreen.V146.Discord.AttachmentId, Evergreen.V146.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V146.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V146.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V146.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V146.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) (Result Evergreen.V146.Discord.HttpError (List Evergreen.V146.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Result Evergreen.V146.Discord.HttpError (List Evergreen.V146.Discord.Message))
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
    | AdminToFrontend Evergreen.V146.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V146.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V146.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V146.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V146.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V146.ImageEditor.ToFrontend
