module Evergreen.V97.Types exposing (..)

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
import Evergreen.V97.AiChat
import Evergreen.V97.ChannelName
import Evergreen.V97.Coord
import Evergreen.V97.CssPixels
import Evergreen.V97.Discord
import Evergreen.V97.Discord.Id
import Evergreen.V97.DmChannel
import Evergreen.V97.Editable
import Evergreen.V97.EmailAddress
import Evergreen.V97.Emoji
import Evergreen.V97.FileStatus
import Evergreen.V97.GuildName
import Evergreen.V97.Id
import Evergreen.V97.Local
import Evergreen.V97.LocalState
import Evergreen.V97.Log
import Evergreen.V97.LoginForm
import Evergreen.V97.Message
import Evergreen.V97.MessageInput
import Evergreen.V97.MessageView
import Evergreen.V97.NonemptyDict
import Evergreen.V97.NonemptySet
import Evergreen.V97.OneToOne
import Evergreen.V97.Pages.Admin
import Evergreen.V97.PersonName
import Evergreen.V97.Ports
import Evergreen.V97.Postmark
import Evergreen.V97.RichText
import Evergreen.V97.Route
import Evergreen.V97.SecretId
import Evergreen.V97.SessionIdHash
import Evergreen.V97.Slack
import Evergreen.V97.Touch
import Evergreen.V97.TwoFactorAuthentication
import Evergreen.V97.Ui.Anim
import Evergreen.V97.User
import Evergreen.V97.UserAgent
import Evergreen.V97.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V97.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V97.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.DmChannel.FrontendDmChannel
    , user : Evergreen.V97.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V97.SessionIdHash.SessionIdHash Evergreen.V97.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V97.Route.Route
    , windowSize : Evergreen.V97.Coord.Coord Evergreen.V97.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V97.Ports.NotificationPermission
    , pwaStatus : Evergreen.V97.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V97.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V97.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V97.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V97.RichText.RichText) Evergreen.V97.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Evergreen.V97.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) Evergreen.V97.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.UserSession.ToBeFilledInByBackend (Evergreen.V97.SecretId.SecretId Evergreen.V97.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V97.GuildName.GuildName (Evergreen.V97.UserSession.ToBeFilledInByBackend (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V97.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage Evergreen.V97.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage Evergreen.V97.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V97.RichText.RichText) (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Evergreen.V97.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V97.UserSession.SetViewing
    | Local_SetName Evergreen.V97.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V97.Id.GuildOrDmIdNoThread (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Evergreen.V97.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Evergreen.V97.Message.Message Evergreen.V97.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V97.Id.GuildOrDmIdNoThread (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId) (Evergreen.V97.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId) (Evergreen.V97.Message.Message Evergreen.V97.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V97.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V97.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId
    , channelId : Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId
    , messageIndex : Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Effect.Time.Posix Evergreen.V97.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V97.RichText.RichText) Evergreen.V97.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Evergreen.V97.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) Evergreen.V97.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.SecretId.SecretId Evergreen.V97.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V97.LocalState.JoinGuildError
            { guildId : Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId
            , guild : Evergreen.V97.LocalState.FrontendGuild
            , owner : Evergreen.V97.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage Evergreen.V97.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage Evergreen.V97.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V97.RichText.RichText) (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Evergreen.V97.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (List.Nonempty.Nonempty Evergreen.V97.RichText.RichText) (Maybe (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V97.SessionIdHash.SessionIdHash Evergreen.V97.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V97.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V97.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias EditMessage =
    { messageIndex : Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Evergreen.V97.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V97.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V97.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V97.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V97.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V97.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V97.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V97.Coord.Coord Evergreen.V97.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V97.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V97.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V97.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Evergreen.V97.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId) (Evergreen.V97.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V97.Editable.Model
    , botToken : Evergreen.V97.Editable.Model
    , slackClientSecret : Evergreen.V97.Editable.Model
    , publicVapidKey : Evergreen.V97.Editable.Model
    , privateVapidKey : Evergreen.V97.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V97.Local.Local LocalMsg Evergreen.V97.LocalState.LocalState
    , admin : Maybe Evergreen.V97.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V97.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId, Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId, Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId, Evergreen.V97.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V97.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V97.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V97.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.NonemptyDict.NonemptyDict (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Evergreen.V97.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V97.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V97.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V97.SecretId.SecretId Evergreen.V97.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V97.NonemptyDict.NonemptyDict Int Evergreen.V97.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V97.NonemptyDict.NonemptyDict Int Evergreen.V97.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V97.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V97.Coord.Coord Evergreen.V97.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V97.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V97.Ports.NotificationPermission
    , pwaStatus : Evergreen.V97.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V97.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V97.UserAgent.UserAgent
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
    , userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V97.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V97.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V97.Coord.Coord Evergreen.V97.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V97.NonemptyDict.NonemptyDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V97.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V97.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V97.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.LocalState.BackendGuild
    , discordModel : Evergreen.V97.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V97.OneToOne.OneToOne (Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId)
    , discordUsers : Evergreen.V97.OneToOne.OneToOne (Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    , discordBotId : Maybe (Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V97.DmChannel.DmChannelId Evergreen.V97.DmChannel.DmChannel
    , discordDms : Evergreen.V97.OneToOne.OneToOne (Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.ChannelId) Evergreen.V97.DmChannel.DmChannelId
    , slackDms : Evergreen.V97.OneToOne.OneToOne (Evergreen.V97.Slack.Id Evergreen.V97.Slack.ChannelId) Evergreen.V97.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V97.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V97.OneToOne.OneToOne String (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId)
    , slackUsers : Evergreen.V97.OneToOne.OneToOne (Evergreen.V97.Slack.Id Evergreen.V97.Slack.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    , slackServers : Evergreen.V97.OneToOne.OneToOne (Evergreen.V97.Slack.Id Evergreen.V97.Slack.TeamId) (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId)
    , slackToken : Maybe Evergreen.V97.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V97.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V97.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V97.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V97.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V97.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V97.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V97.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V97.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V97.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V97.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) Evergreen.V97.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) Evergreen.V97.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V97.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V97.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V97.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage (Evergreen.V97.Coord.Coord Evergreen.V97.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V97.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V97.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V97.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V97.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V97.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V97.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V97.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V97.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V97.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V97.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V97.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V97.NonemptyDict.NonemptyDict Int Evergreen.V97.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V97.NonemptyDict.NonemptyDict Int Evergreen.V97.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V97.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V97.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V97.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V97.Editable.Msg Evergreen.V97.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V97.Editable.Msg (Maybe Evergreen.V97.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V97.Editable.Msg (Maybe Evergreen.V97.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V97.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V97.Editable.Msg Evergreen.V97.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V97.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V97.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V97.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V97.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V97.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V97.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V97.Id.GuildOrDmId (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V97.Id.GuildOrDmIdNoThread Evergreen.V97.Id.ThreadRouteWithMessage Evergreen.V97.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V97.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V97.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) Evergreen.V97.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V97.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute )) Int Evergreen.V97.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute )) Int Evergreen.V97.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V97.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V97.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V97.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V97.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.SecretId.SecretId Evergreen.V97.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute )) Evergreen.V97.PersonName.PersonName Evergreen.V97.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V97.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V97.Slack.OAuthCode Evergreen.V97.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V97.EmailAddress.EmailAddress (Result Evergreen.V97.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V97.EmailAddress.EmailAddress (Result Evergreen.V97.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V97.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V97.LocalState.DiscordBotToken (Result Evergreen.V97.Discord.HttpError ( Evergreen.V97.Discord.User, List Evergreen.V97.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.UserId)
        (Result
            Evergreen.V97.Discord.HttpError
            (List
                ( Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.GuildId
                , { guild : Evergreen.V97.Discord.Guild
                  , members : List Evergreen.V97.Discord.GuildMember
                  , channels : List ( Evergreen.V97.Discord.Channel2, List Evergreen.V97.Discord.Message )
                  , icon : Maybe Evergreen.V97.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V97.Discord.Channel, List Evergreen.V97.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) Evergreen.V97.Id.ThreadRouteWithMessage (Result Evergreen.V97.Discord.HttpError Evergreen.V97.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V97.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V97.DmChannel.DmChannelId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Result Evergreen.V97.Discord.HttpError Evergreen.V97.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V97.Discord.HttpError (List ( Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.UserId, Maybe Evergreen.V97.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V97.Slack.CurrentUser
            , team : Evergreen.V97.Slack.Team
            , users : List Evergreen.V97.Slack.User
            , channels : List ( Evergreen.V97.Slack.Channel, List Evergreen.V97.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Result Effect.Http.Error Evergreen.V97.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V97.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V97.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V97.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V97.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
