module Evergreen.V147.Types exposing (..)

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
import Evergreen.V147.AiChat
import Evergreen.V147.ChannelName
import Evergreen.V147.Coord
import Evergreen.V147.CssPixels
import Evergreen.V147.Discord
import Evergreen.V147.DiscordAttachmentId
import Evergreen.V147.DiscordUserData
import Evergreen.V147.DmChannel
import Evergreen.V147.Editable
import Evergreen.V147.EmailAddress
import Evergreen.V147.Emoji
import Evergreen.V147.FileStatus
import Evergreen.V147.GuildName
import Evergreen.V147.Id
import Evergreen.V147.ImageEditor
import Evergreen.V147.Local
import Evergreen.V147.LocalState
import Evergreen.V147.Log
import Evergreen.V147.LoginForm
import Evergreen.V147.Message
import Evergreen.V147.MessageInput
import Evergreen.V147.MessageView
import Evergreen.V147.NonemptyDict
import Evergreen.V147.NonemptySet
import Evergreen.V147.OneToOne
import Evergreen.V147.Pages.Admin
import Evergreen.V147.Pagination
import Evergreen.V147.PersonName
import Evergreen.V147.Ports
import Evergreen.V147.Postmark
import Evergreen.V147.RichText
import Evergreen.V147.Route
import Evergreen.V147.SecretId
import Evergreen.V147.SessionIdHash
import Evergreen.V147.Slack
import Evergreen.V147.TextEditor
import Evergreen.V147.Touch
import Evergreen.V147.TwoFactorAuthentication
import Evergreen.V147.Ui.Anim
import Evergreen.V147.User
import Evergreen.V147.UserAgent
import Evergreen.V147.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V147.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V147.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) Evergreen.V147.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) Evergreen.V147.LocalState.DiscordFrontendGuild
    , user : Evergreen.V147.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V147.SessionIdHash.SessionIdHash Evergreen.V147.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V147.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V147.Route.Route
    , windowSize : Evergreen.V147.Coord.Coord Evergreen.V147.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V147.Ports.NotificationPermission
    , pwaStatus : Evergreen.V147.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V147.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V147.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V147.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))) Evergreen.V147.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V147.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))) Evergreen.V147.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) Evergreen.V147.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.UserSession.ToBeFilledInByBackend (Evergreen.V147.SecretId.SecretId Evergreen.V147.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V147.GuildName.GuildName (Evergreen.V147.UserSession.ToBeFilledInByBackend (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage Evergreen.V147.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage Evergreen.V147.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V147.Id.GuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))) (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V147.Id.DiscordGuildOrDmId_DmData (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V147.UserSession.SetViewing
    | Local_SetName Evergreen.V147.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V147.Id.GuildOrDmId (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V147.Id.GuildOrDmId (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V147.Id.DiscordGuildOrDmId (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V147.Id.DiscordGuildOrDmId (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V147.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V147.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V147.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Effect.Time.Posix Evergreen.V147.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))) Evergreen.V147.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V147.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))) Evergreen.V147.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) Evergreen.V147.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.SecretId.SecretId Evergreen.V147.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V147.LocalState.JoinGuildError
            { guildId : Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId
            , guild : Evergreen.V147.LocalState.FrontendGuild
            , owner : Evergreen.V147.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.Id.GuildOrDmId Evergreen.V147.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.Id.GuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage Evergreen.V147.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.Id.GuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage Evergreen.V147.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage Evergreen.V147.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage Evergreen.V147.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.Id.GuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))) (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V147.Id.DiscordGuildOrDmId_DmData (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V147.SessionIdHash.SessionIdHash Evergreen.V147.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V147.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V147.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V147.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.NonemptySet.NonemptySet (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) Evergreen.V147.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) Evergreen.V147.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Maybe (Evergreen.V147.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V147.Pages.Admin.InitAdminData


type LocalMsg
    = LocalChange (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) Evergreen.V147.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V147.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V147.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V147.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V147.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V147.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V147.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V147.Coord.Coord Evergreen.V147.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V147.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V147.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V147.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V147.Local.Local LocalMsg Evergreen.V147.LocalState.LocalState
    , admin : Evergreen.V147.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId, Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V147.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V147.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.NonemptyDict.NonemptyDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V147.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V147.TextEditor.Model
    , profilePictureEditor : Evergreen.V147.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V147.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V147.SecretId.SecretId Evergreen.V147.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V147.NonemptyDict.NonemptyDict Int Evergreen.V147.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V147.NonemptyDict.NonemptyDict Int Evergreen.V147.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V147.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V147.Coord.Coord Evergreen.V147.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V147.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V147.Ports.NotificationPermission
    , pwaStatus : Evergreen.V147.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V147.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V147.UserAgent.UserAgent
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
    , userId : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V147.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V147.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V147.Coord.Coord Evergreen.V147.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V147.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V147.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V147.NonemptyDict.NonemptyDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V147.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V147.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V147.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) Evergreen.V147.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V147.DmChannel.DmChannelId Evergreen.V147.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) Evergreen.V147.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V147.OneToOne.OneToOne (Evergreen.V147.Slack.Id Evergreen.V147.Slack.ChannelId) Evergreen.V147.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V147.OneToOne.OneToOne String (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    , slackUsers : Evergreen.V147.OneToOne.OneToOne (Evergreen.V147.Slack.Id Evergreen.V147.Slack.UserId) (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    , slackServers : Evergreen.V147.OneToOne.OneToOne (Evergreen.V147.Slack.Id Evergreen.V147.Slack.TeamId) (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    , slackToken : Maybe Evergreen.V147.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V147.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V147.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V147.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V147.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId, Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V147.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V147.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V147.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V147.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.LocalState.LoadingDiscordChannel (List Evergreen.V147.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V147.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V147.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V147.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V147.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) Evergreen.V147.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) Evergreen.V147.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V147.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V147.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Coord.Coord Evergreen.V147.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V147.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V147.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V147.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V147.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V147.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V147.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V147.NonemptyDict.NonemptyDict Int Evergreen.V147.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V147.NonemptyDict.NonemptyDict Int Evergreen.V147.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V147.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V147.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V147.Editable.Msg Evergreen.V147.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V147.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V147.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V147.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute ) (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRouteWithMessage Evergreen.V147.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V147.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V147.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V147.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V147.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId
        , otherUserId : Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V147.Id.AnyGuildOrDmId Evergreen.V147.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V147.Id.Id Evergreen.V147.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V147.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V147.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V147.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V147.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V147.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V147.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.SecretId.SecretId Evergreen.V147.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V147.PersonName.PersonName Evergreen.V147.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V147.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V147.Slack.OAuthCode Evergreen.V147.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V147.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V147.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V147.Id.Id Evergreen.V147.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V147.EmailAddress.EmailAddress (Result Evergreen.V147.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V147.EmailAddress.EmailAddress (Result Evergreen.V147.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V147.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMaybeMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Result Evergreen.V147.Discord.HttpError Evergreen.V147.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V147.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Result Evergreen.V147.Discord.HttpError Evergreen.V147.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) (Result Evergreen.V147.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) (Result Evergreen.V147.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) (Result Evergreen.V147.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) (Result Evergreen.V147.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji (Result Evergreen.V147.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji (Result Evergreen.V147.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji (Result Evergreen.V147.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji (Result Evergreen.V147.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V147.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V147.Discord.HttpError (List ( Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId, Maybe Evergreen.V147.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V147.Slack.CurrentUser
            , team : Evergreen.V147.Slack.Team
            , users : List Evergreen.V147.Slack.User
            , channels : List ( Evergreen.V147.Slack.Channel, List Evergreen.V147.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Result Effect.Http.Error Evergreen.V147.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.Discord.UserAuth (Result Evergreen.V147.Discord.HttpError Evergreen.V147.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Result Evergreen.V147.Discord.HttpError Evergreen.V147.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
        (Result
            Evergreen.V147.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId
                , members : List (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
                }
            , List
                ( Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId
                , { guild : Evergreen.V147.Discord.GatewayGuild
                  , channels : List Evergreen.V147.Discord.Channel
                  , icon : Maybe Evergreen.V147.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V147.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V147.Discord.Id Evergreen.V147.Discord.AttachmentId, Evergreen.V147.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V147.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V147.Discord.Id Evergreen.V147.Discord.AttachmentId, Evergreen.V147.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V147.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V147.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V147.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V147.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) (Result Evergreen.V147.Discord.HttpError (List Evergreen.V147.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Result Evergreen.V147.Discord.HttpError (List Evergreen.V147.Discord.Message))
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
    | AdminToFrontend Evergreen.V147.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V147.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V147.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V147.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V147.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V147.ImageEditor.ToFrontend
