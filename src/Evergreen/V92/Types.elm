module Evergreen.V92.Types exposing (..)

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
import Evergreen.V92.AiChat
import Evergreen.V92.ChannelName
import Evergreen.V92.Coord
import Evergreen.V92.CssPixels
import Evergreen.V92.Discord
import Evergreen.V92.Discord.Id
import Evergreen.V92.DmChannel
import Evergreen.V92.Editable
import Evergreen.V92.EmailAddress
import Evergreen.V92.Emoji
import Evergreen.V92.FileStatus
import Evergreen.V92.GuildName
import Evergreen.V92.Id
import Evergreen.V92.Local
import Evergreen.V92.LocalState
import Evergreen.V92.Log
import Evergreen.V92.LoginForm
import Evergreen.V92.Message
import Evergreen.V92.MessageInput
import Evergreen.V92.MessageView
import Evergreen.V92.NonemptyDict
import Evergreen.V92.NonemptySet
import Evergreen.V92.OneToOne
import Evergreen.V92.Pages.Admin
import Evergreen.V92.PersonName
import Evergreen.V92.Ports
import Evergreen.V92.Postmark
import Evergreen.V92.RichText
import Evergreen.V92.Route
import Evergreen.V92.SecretId
import Evergreen.V92.SessionIdHash
import Evergreen.V92.Slack
import Evergreen.V92.Touch
import Evergreen.V92.TwoFactorAuthentication
import Evergreen.V92.Ui.Anim
import Evergreen.V92.User
import Evergreen.V92.UserAgent
import Evergreen.V92.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V92.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V92.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.DmChannel.FrontendDmChannel
    , user : Evergreen.V92.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V92.SessionIdHash.SessionIdHash Evergreen.V92.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V92.Route.Route
    , windowSize : Evergreen.V92.Coord.Coord Evergreen.V92.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V92.Ports.NotificationPermission
    , pwaStatus : Evergreen.V92.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V92.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V92.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V92.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V92.RichText.RichText) Evergreen.V92.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Evergreen.V92.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) Evergreen.V92.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.UserSession.ToBeFilledInByBackend (Evergreen.V92.SecretId.SecretId Evergreen.V92.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V92.GuildName.GuildName (Evergreen.V92.UserSession.ToBeFilledInByBackend (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V92.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage Evergreen.V92.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage Evergreen.V92.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V92.RichText.RichText) (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Evergreen.V92.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V92.UserSession.SetViewing
    | Local_SetName Evergreen.V92.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V92.Id.GuildOrDmIdNoThread (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Evergreen.V92.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Evergreen.V92.Message.Message Evergreen.V92.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V92.Id.GuildOrDmIdNoThread (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId) (Evergreen.V92.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId) (Evergreen.V92.Message.Message Evergreen.V92.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V92.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V92.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId
    , channelId : Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId
    , messageIndex : Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Effect.Time.Posix Evergreen.V92.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V92.RichText.RichText) Evergreen.V92.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Evergreen.V92.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) Evergreen.V92.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.SecretId.SecretId Evergreen.V92.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V92.LocalState.JoinGuildError
            { guildId : Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId
            , guild : Evergreen.V92.LocalState.FrontendGuild
            , owner : Evergreen.V92.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage Evergreen.V92.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage Evergreen.V92.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V92.RichText.RichText) (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Evergreen.V92.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (List.Nonempty.Nonempty Evergreen.V92.RichText.RichText) (Maybe (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V92.SessionIdHash.SessionIdHash Evergreen.V92.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V92.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing (Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V92.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V92.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V92.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V92.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V92.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V92.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V92.Coord.Coord Evergreen.V92.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V92.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V92.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Evergreen.V92.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V92.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Evergreen.V92.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId) (Evergreen.V92.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V92.Editable.Model
    , botToken : Evergreen.V92.Editable.Model
    , slackClientSecret : Evergreen.V92.Editable.Model
    , publicVapidKey : Evergreen.V92.Editable.Model
    , privateVapidKey : Evergreen.V92.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V92.Local.Local LocalMsg Evergreen.V92.LocalState.LocalState
    , admin : Maybe Evergreen.V92.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V92.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId, Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId, Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId, Evergreen.V92.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V92.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V92.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V92.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.NonemptyDict.NonemptyDict (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Evergreen.V92.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V92.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V92.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V92.SecretId.SecretId Evergreen.V92.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V92.NonemptyDict.NonemptyDict Int Evergreen.V92.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V92.NonemptyDict.NonemptyDict Int Evergreen.V92.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V92.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V92.Coord.Coord Evergreen.V92.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V92.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V92.Ports.NotificationPermission
    , pwaStatus : Evergreen.V92.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V92.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V92.UserAgent.UserAgent
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V92.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V92.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V92.Coord.Coord Evergreen.V92.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V92.NonemptyDict.NonemptyDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V92.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V92.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V92.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.LocalState.BackendGuild
    , discordModel : Evergreen.V92.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V92.OneToOne.OneToOne (Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId)
    , discordUsers : Evergreen.V92.OneToOne.OneToOne (Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.UserId) (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
    , discordBotId : Maybe (Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V92.DmChannel.DmChannelId Evergreen.V92.DmChannel.DmChannel
    , discordDms : Evergreen.V92.OneToOne.OneToOne (Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.ChannelId) Evergreen.V92.DmChannel.DmChannelId
    , slackDms : Evergreen.V92.OneToOne.OneToOne (Evergreen.V92.Slack.Id Evergreen.V92.Slack.ChannelId) Evergreen.V92.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V92.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V92.OneToOne.OneToOne String (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId)
    , slackUsers : Evergreen.V92.OneToOne.OneToOne (Evergreen.V92.Slack.Id Evergreen.V92.Slack.UserId) (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
    , slackServers : Evergreen.V92.OneToOne.OneToOne (Evergreen.V92.Slack.Id Evergreen.V92.Slack.TeamId) (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId)
    , slackToken : Maybe Evergreen.V92.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V92.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V92.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V92.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V92.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V92.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V92.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V92.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V92.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V92.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V92.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) Evergreen.V92.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) Evergreen.V92.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V92.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V92.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V92.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage (Evergreen.V92.Coord.Coord Evergreen.V92.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V92.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V92.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V92.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V92.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V92.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V92.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V92.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V92.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V92.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V92.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V92.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V92.NonemptyDict.NonemptyDict Int Evergreen.V92.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V92.NonemptyDict.NonemptyDict Int Evergreen.V92.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V92.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V92.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V92.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V92.Editable.Msg Evergreen.V92.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V92.Editable.Msg (Maybe Evergreen.V92.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V92.Editable.Msg (Maybe Evergreen.V92.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V92.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V92.Editable.Msg Evergreen.V92.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V92.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V92.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V92.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V92.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V92.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V92.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V92.Id.GuildOrDmId (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V92.Id.GuildOrDmIdNoThread Evergreen.V92.Id.ThreadRouteWithMessage Evergreen.V92.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V92.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V92.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) Evergreen.V92.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V92.UserAgent.UserAgent
    | WindowHasFocusChanged Bool


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute )) Int Evergreen.V92.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute )) Int Evergreen.V92.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V92.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V92.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V92.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V92.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.SecretId.SecretId Evergreen.V92.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute )) Evergreen.V92.PersonName.PersonName Evergreen.V92.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V92.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V92.Slack.OAuthCode Evergreen.V92.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V92.EmailAddress.EmailAddress (Result Evergreen.V92.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V92.EmailAddress.EmailAddress (Result Evergreen.V92.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V92.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V92.LocalState.DiscordBotToken (Result Evergreen.V92.Discord.HttpError ( Evergreen.V92.Discord.User, List Evergreen.V92.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.UserId)
        (Result
            Evergreen.V92.Discord.HttpError
            (List
                ( Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.GuildId
                , { guild : Evergreen.V92.Discord.Guild
                  , members : List Evergreen.V92.Discord.GuildMember
                  , channels : List ( Evergreen.V92.Discord.Channel2, List Evergreen.V92.Discord.Message )
                  , icon : Maybe Evergreen.V92.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V92.Discord.Channel, List Evergreen.V92.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) Evergreen.V92.Id.ThreadRouteWithMessage (Result Evergreen.V92.Discord.HttpError Evergreen.V92.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V92.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V92.DmChannel.DmChannelId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Result Evergreen.V92.Discord.HttpError Evergreen.V92.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V92.Discord.HttpError (List ( Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.UserId, Maybe Evergreen.V92.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V92.Slack.CurrentUser
            , team : Evergreen.V92.Slack.Team
            , users : List Evergreen.V92.Slack.User
            , channels : List ( Evergreen.V92.Slack.Channel, List Evergreen.V92.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (Result Effect.Http.Error Evergreen.V92.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V92.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V92.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V92.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V92.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
