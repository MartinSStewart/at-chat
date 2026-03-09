module Evergreen.V148.Types exposing (..)

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
import Evergreen.V148.AiChat
import Evergreen.V148.ChannelName
import Evergreen.V148.Coord
import Evergreen.V148.CssPixels
import Evergreen.V148.Discord
import Evergreen.V148.DiscordAttachmentId
import Evergreen.V148.DiscordUserData
import Evergreen.V148.DmChannel
import Evergreen.V148.Editable
import Evergreen.V148.EmailAddress
import Evergreen.V148.Emoji
import Evergreen.V148.FileStatus
import Evergreen.V148.GuildName
import Evergreen.V148.Id
import Evergreen.V148.ImageEditor
import Evergreen.V148.Local
import Evergreen.V148.LocalState
import Evergreen.V148.Log
import Evergreen.V148.LoginForm
import Evergreen.V148.Message
import Evergreen.V148.MessageInput
import Evergreen.V148.MessageView
import Evergreen.V148.NonemptyDict
import Evergreen.V148.NonemptySet
import Evergreen.V148.OneToOne
import Evergreen.V148.Pages.Admin
import Evergreen.V148.Pagination
import Evergreen.V148.PersonName
import Evergreen.V148.Ports
import Evergreen.V148.Postmark
import Evergreen.V148.RichText
import Evergreen.V148.Route
import Evergreen.V148.SecretId
import Evergreen.V148.SessionIdHash
import Evergreen.V148.Slack
import Evergreen.V148.TextEditor
import Evergreen.V148.Touch
import Evergreen.V148.TwoFactorAuthentication
import Evergreen.V148.Ui.Anim
import Evergreen.V148.User
import Evergreen.V148.UserAgent
import Evergreen.V148.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V148.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V148.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) Evergreen.V148.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) Evergreen.V148.LocalState.DiscordFrontendGuild
    , user : Evergreen.V148.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V148.SessionIdHash.SessionIdHash Evergreen.V148.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V148.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V148.Route.Route
    , windowSize : Evergreen.V148.Coord.Coord Evergreen.V148.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V148.Ports.NotificationPermission
    , pwaStatus : Evergreen.V148.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V148.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V148.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V148.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))) Evergreen.V148.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V148.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))) Evergreen.V148.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) Evergreen.V148.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.UserSession.ToBeFilledInByBackend (Evergreen.V148.SecretId.SecretId Evergreen.V148.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V148.GuildName.GuildName (Evergreen.V148.UserSession.ToBeFilledInByBackend (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage Evergreen.V148.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage Evergreen.V148.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V148.Id.GuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))) (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V148.Id.DiscordGuildOrDmId_DmData (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V148.UserSession.SetViewing
    | Local_SetName Evergreen.V148.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V148.Id.GuildOrDmId (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V148.Id.GuildOrDmId (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V148.Id.DiscordGuildOrDmId (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V148.Id.DiscordGuildOrDmId (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V148.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V148.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V148.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    | LinkDiscordAcknowledgementIsChecked Bool


type ServerChange
    = Server_SendMessage (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Effect.Time.Posix Evergreen.V148.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))) Evergreen.V148.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V148.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))) Evergreen.V148.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) Evergreen.V148.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.SecretId.SecretId Evergreen.V148.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V148.LocalState.JoinGuildError
            { guildId : Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId
            , guild : Evergreen.V148.LocalState.FrontendGuild
            , owner : Evergreen.V148.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.Id.GuildOrDmId Evergreen.V148.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.Id.GuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage Evergreen.V148.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.Id.GuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage Evergreen.V148.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage Evergreen.V148.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage Evergreen.V148.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.Id.GuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))) (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V148.Id.DiscordGuildOrDmId_DmData (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V148.SessionIdHash.SessionIdHash Evergreen.V148.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V148.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V148.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V148.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.NonemptySet.NonemptySet (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) Evergreen.V148.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) Evergreen.V148.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Maybe (Evergreen.V148.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V148.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V148.Log.Log


type LocalMsg
    = LocalChange (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) Evergreen.V148.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V148.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V148.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V148.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V148.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V148.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V148.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V148.Coord.Coord Evergreen.V148.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V148.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V148.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V148.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V148.Local.Local LocalMsg Evergreen.V148.LocalState.LocalState
    , admin : Evergreen.V148.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId, Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V148.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V148.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.NonemptyDict.NonemptyDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V148.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V148.TextEditor.Model
    , profilePictureEditor : Evergreen.V148.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V148.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V148.SecretId.SecretId Evergreen.V148.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V148.NonemptyDict.NonemptyDict Int Evergreen.V148.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V148.NonemptyDict.NonemptyDict Int Evergreen.V148.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V148.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V148.Coord.Coord Evergreen.V148.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V148.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V148.Ports.NotificationPermission
    , pwaStatus : Evergreen.V148.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V148.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V148.UserAgent.UserAgent
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
    , userId : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V148.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V148.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V148.Coord.Coord Evergreen.V148.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V148.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V148.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V148.NonemptyDict.NonemptyDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V148.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V148.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V148.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) Evergreen.V148.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V148.DmChannel.DmChannelId Evergreen.V148.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) Evergreen.V148.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V148.OneToOne.OneToOne (Evergreen.V148.Slack.Id Evergreen.V148.Slack.ChannelId) Evergreen.V148.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V148.OneToOne.OneToOne String (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    , slackUsers : Evergreen.V148.OneToOne.OneToOne (Evergreen.V148.Slack.Id Evergreen.V148.Slack.UserId) (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    , slackServers : Evergreen.V148.OneToOne.OneToOne (Evergreen.V148.Slack.Id Evergreen.V148.Slack.TeamId) (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    , slackToken : Maybe Evergreen.V148.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V148.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V148.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V148.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V148.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId, Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V148.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V148.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V148.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V148.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.LocalState.LoadingDiscordChannel (List Evergreen.V148.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V148.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V148.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V148.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V148.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) Evergreen.V148.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) Evergreen.V148.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V148.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V148.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Coord.Coord Evergreen.V148.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V148.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V148.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V148.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V148.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V148.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V148.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V148.NonemptyDict.NonemptyDict Int Evergreen.V148.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V148.NonemptyDict.NonemptyDict Int Evergreen.V148.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V148.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V148.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V148.Editable.Msg Evergreen.V148.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V148.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V148.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V148.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute ) (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRouteWithMessage Evergreen.V148.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V148.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V148.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V148.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V148.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId
        , otherUserId : Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V148.Id.AnyGuildOrDmId Evergreen.V148.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V148.Id.Id Evergreen.V148.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V148.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V148.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V148.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V148.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V148.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V148.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.SecretId.SecretId Evergreen.V148.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V148.PersonName.PersonName Evergreen.V148.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V148.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V148.Slack.OAuthCode Evergreen.V148.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V148.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V148.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V148.Id.Id Evergreen.V148.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V148.EmailAddress.EmailAddress (Result Evergreen.V148.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V148.EmailAddress.EmailAddress (Result Evergreen.V148.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V148.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMaybeMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Result Evergreen.V148.Discord.HttpError Evergreen.V148.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V148.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Result Evergreen.V148.Discord.HttpError Evergreen.V148.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) (Result Evergreen.V148.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) (Result Evergreen.V148.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) (Result Evergreen.V148.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) (Result Evergreen.V148.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji (Result Evergreen.V148.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji (Result Evergreen.V148.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji (Result Evergreen.V148.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji (Result Evergreen.V148.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V148.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V148.Discord.HttpError (List ( Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId, Maybe Evergreen.V148.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V148.Slack.CurrentUser
            , team : Evergreen.V148.Slack.Team
            , users : List Evergreen.V148.Slack.User
            , channels : List ( Evergreen.V148.Slack.Channel, List Evergreen.V148.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Result Effect.Http.Error Evergreen.V148.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.Discord.UserAuth (Result Evergreen.V148.Discord.HttpError Evergreen.V148.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Result Evergreen.V148.Discord.HttpError Evergreen.V148.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
        (Result
            Evergreen.V148.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId
                , members : List (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
                }
            , List
                ( Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId
                , { guild : Evergreen.V148.Discord.GatewayGuild
                  , channels : List Evergreen.V148.Discord.Channel
                  , icon : Maybe Evergreen.V148.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V148.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V148.Discord.Id Evergreen.V148.Discord.AttachmentId, Evergreen.V148.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V148.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V148.Discord.Id Evergreen.V148.Discord.AttachmentId, Evergreen.V148.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V148.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V148.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V148.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V148.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) (Result Evergreen.V148.Discord.HttpError (List Evergreen.V148.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Result Evergreen.V148.Discord.HttpError (List Evergreen.V148.Discord.Message))
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
    | AdminToFrontend Evergreen.V148.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V148.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V148.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V148.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V148.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V148.ImageEditor.ToFrontend
