module Evergreen.V104.Types exposing (..)

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
import Evergreen.V104.AiChat
import Evergreen.V104.ChannelName
import Evergreen.V104.Coord
import Evergreen.V104.CssPixels
import Evergreen.V104.Discord
import Evergreen.V104.Discord.Id
import Evergreen.V104.DmChannel
import Evergreen.V104.Editable
import Evergreen.V104.EmailAddress
import Evergreen.V104.Emoji
import Evergreen.V104.FileStatus
import Evergreen.V104.GuildName
import Evergreen.V104.Id
import Evergreen.V104.Local
import Evergreen.V104.LocalState
import Evergreen.V104.Log
import Evergreen.V104.LoginForm
import Evergreen.V104.Message
import Evergreen.V104.MessageInput
import Evergreen.V104.MessageView
import Evergreen.V104.NonemptyDict
import Evergreen.V104.NonemptySet
import Evergreen.V104.OneToOne
import Evergreen.V104.Pages.Admin
import Evergreen.V104.PersonName
import Evergreen.V104.Ports
import Evergreen.V104.Postmark
import Evergreen.V104.RichText
import Evergreen.V104.Route
import Evergreen.V104.SecretId
import Evergreen.V104.SessionIdHash
import Evergreen.V104.Slack
import Evergreen.V104.Touch
import Evergreen.V104.TwoFactorAuthentication
import Evergreen.V104.Ui.Anim
import Evergreen.V104.User
import Evergreen.V104.UserAgent
import Evergreen.V104.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V104.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V104.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.DmChannel.FrontendDmChannel
    , user : Evergreen.V104.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V104.SessionIdHash.SessionIdHash Evergreen.V104.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V104.Route.Route
    , windowSize : Evergreen.V104.Coord.Coord Evergreen.V104.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V104.Ports.NotificationPermission
    , pwaStatus : Evergreen.V104.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V104.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V104.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V104.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V104.RichText.RichText) Evergreen.V104.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Evergreen.V104.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) Evergreen.V104.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.UserSession.ToBeFilledInByBackend (Evergreen.V104.SecretId.SecretId Evergreen.V104.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V104.GuildName.GuildName (Evergreen.V104.UserSession.ToBeFilledInByBackend (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V104.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage Evergreen.V104.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage Evergreen.V104.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V104.RichText.RichText) (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Evergreen.V104.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V104.UserSession.SetViewing
    | Local_SetName Evergreen.V104.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V104.Id.GuildOrDmIdNoThread (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Evergreen.V104.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Evergreen.V104.Message.Message Evergreen.V104.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V104.Id.GuildOrDmIdNoThread (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ThreadMessageId) (Evergreen.V104.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ThreadMessageId) (Evergreen.V104.Message.Message Evergreen.V104.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V104.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V104.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId
    , channelId : Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId
    , messageIndex : Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Effect.Time.Posix Evergreen.V104.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V104.RichText.RichText) Evergreen.V104.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Evergreen.V104.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) Evergreen.V104.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.SecretId.SecretId Evergreen.V104.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V104.LocalState.JoinGuildError
            { guildId : Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId
            , guild : Evergreen.V104.LocalState.FrontendGuild
            , owner : Evergreen.V104.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage Evergreen.V104.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage Evergreen.V104.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V104.RichText.RichText) (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Evergreen.V104.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (List.Nonempty.Nonempty Evergreen.V104.RichText.RichText) (Maybe (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V104.SessionIdHash.SessionIdHash Evergreen.V104.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V104.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V104.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) LocalChange
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
    { messageIndex : Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Evergreen.V104.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V104.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V104.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V104.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V104.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V104.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V104.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V104.Coord.Coord Evergreen.V104.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V104.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V104.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V104.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Evergreen.V104.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ThreadMessageId) (Evergreen.V104.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V104.Editable.Model
    , botToken : Evergreen.V104.Editable.Model
    , slackClientSecret : Evergreen.V104.Editable.Model
    , publicVapidKey : Evergreen.V104.Editable.Model
    , privateVapidKey : Evergreen.V104.Editable.Model
    , openRouterKey : Evergreen.V104.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V104.Local.Local LocalMsg Evergreen.V104.LocalState.LocalState
    , admin : Maybe Evergreen.V104.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V104.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId, Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId, Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId, Evergreen.V104.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V104.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V104.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V104.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.NonemptyDict.NonemptyDict (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Evergreen.V104.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V104.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V104.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V104.SecretId.SecretId Evergreen.V104.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V104.NonemptyDict.NonemptyDict Int Evergreen.V104.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V104.NonemptyDict.NonemptyDict Int Evergreen.V104.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V104.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V104.Coord.Coord Evergreen.V104.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V104.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V104.Ports.NotificationPermission
    , pwaStatus : Evergreen.V104.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V104.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V104.UserAgent.UserAgent
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
    , userId : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V104.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V104.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V104.Coord.Coord Evergreen.V104.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V104.NonemptyDict.NonemptyDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V104.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V104.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V104.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.LocalState.BackendGuild
    , discordModel : Evergreen.V104.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V104.OneToOne.OneToOne (Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId)
    , discordUsers : Evergreen.V104.OneToOne.OneToOne (Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.UserId) (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
    , discordBotId : Maybe (Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V104.DmChannel.DmChannelId Evergreen.V104.DmChannel.DmChannel
    , discordDms : Evergreen.V104.OneToOne.OneToOne (Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.ChannelId) Evergreen.V104.DmChannel.DmChannelId
    , slackDms : Evergreen.V104.OneToOne.OneToOne (Evergreen.V104.Slack.Id Evergreen.V104.Slack.ChannelId) Evergreen.V104.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V104.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V104.OneToOne.OneToOne String (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId)
    , slackUsers : Evergreen.V104.OneToOne.OneToOne (Evergreen.V104.Slack.Id Evergreen.V104.Slack.UserId) (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
    , slackServers : Evergreen.V104.OneToOne.OneToOne (Evergreen.V104.Slack.Id Evergreen.V104.Slack.TeamId) (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId)
    , slackToken : Maybe Evergreen.V104.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V104.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V104.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V104.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V104.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V104.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V104.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V104.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V104.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V104.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V104.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) Evergreen.V104.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) Evergreen.V104.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V104.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V104.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V104.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage (Evergreen.V104.Coord.Coord Evergreen.V104.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V104.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V104.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V104.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V104.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V104.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V104.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V104.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V104.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V104.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V104.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V104.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V104.NonemptyDict.NonemptyDict Int Evergreen.V104.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V104.NonemptyDict.NonemptyDict Int Evergreen.V104.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V104.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V104.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V104.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V104.Editable.Msg Evergreen.V104.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V104.Editable.Msg (Maybe Evergreen.V104.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V104.Editable.Msg (Maybe Evergreen.V104.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V104.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V104.Editable.Msg Evergreen.V104.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V104.Editable.Msg (Maybe String))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V104.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V104.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V104.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V104.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V104.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V104.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V104.Id.GuildOrDmId (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V104.Id.GuildOrDmIdNoThread Evergreen.V104.Id.ThreadRouteWithMessage Evergreen.V104.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V104.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V104.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) Evergreen.V104.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V104.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute )) Int Evergreen.V104.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute )) Int Evergreen.V104.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V104.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V104.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V104.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V104.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.SecretId.SecretId Evergreen.V104.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute )) Evergreen.V104.PersonName.PersonName Evergreen.V104.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V104.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V104.Slack.OAuthCode Evergreen.V104.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V104.EmailAddress.EmailAddress (Result Evergreen.V104.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V104.EmailAddress.EmailAddress (Result Evergreen.V104.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V104.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V104.LocalState.DiscordBotToken (Result Evergreen.V104.Discord.HttpError ( Evergreen.V104.Discord.User, List Evergreen.V104.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.UserId)
        (Result
            Evergreen.V104.Discord.HttpError
            (List
                ( Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.GuildId
                , { guild : Evergreen.V104.Discord.Guild
                  , members : List Evergreen.V104.Discord.GuildMember
                  , channels : List ( Evergreen.V104.Discord.Channel2, List Evergreen.V104.Discord.Message )
                  , icon : Maybe Evergreen.V104.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V104.Discord.Channel, List Evergreen.V104.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) Evergreen.V104.Id.ThreadRouteWithMessage (Result Evergreen.V104.Discord.HttpError Evergreen.V104.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V104.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V104.DmChannel.DmChannelId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Result Evergreen.V104.Discord.HttpError Evergreen.V104.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V104.Discord.HttpError (List ( Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.UserId, Maybe Evergreen.V104.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V104.Slack.CurrentUser
            , team : Evergreen.V104.Slack.Team
            , users : List Evergreen.V104.Slack.User
            , channels : List ( Evergreen.V104.Slack.Channel, List Evergreen.V104.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (Result Effect.Http.Error Evergreen.V104.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V104.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V104.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V104.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V104.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
