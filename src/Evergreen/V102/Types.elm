module Evergreen.V102.Types exposing (..)

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
import Evergreen.V102.AiChat
import Evergreen.V102.ChannelName
import Evergreen.V102.Coord
import Evergreen.V102.CssPixels
import Evergreen.V102.Discord
import Evergreen.V102.Discord.Id
import Evergreen.V102.DmChannel
import Evergreen.V102.Editable
import Evergreen.V102.EmailAddress
import Evergreen.V102.Emoji
import Evergreen.V102.FileStatus
import Evergreen.V102.GuildName
import Evergreen.V102.Id
import Evergreen.V102.Local
import Evergreen.V102.LocalState
import Evergreen.V102.Log
import Evergreen.V102.LoginForm
import Evergreen.V102.Message
import Evergreen.V102.MessageInput
import Evergreen.V102.MessageView
import Evergreen.V102.NonemptyDict
import Evergreen.V102.NonemptySet
import Evergreen.V102.OneToOne
import Evergreen.V102.Pages.Admin
import Evergreen.V102.PersonName
import Evergreen.V102.Ports
import Evergreen.V102.Postmark
import Evergreen.V102.RichText
import Evergreen.V102.Route
import Evergreen.V102.SecretId
import Evergreen.V102.SessionIdHash
import Evergreen.V102.Slack
import Evergreen.V102.Touch
import Evergreen.V102.TwoFactorAuthentication
import Evergreen.V102.Ui.Anim
import Evergreen.V102.User
import Evergreen.V102.UserAgent
import Evergreen.V102.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V102.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V102.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.DmChannel.FrontendDmChannel
    , user : Evergreen.V102.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V102.SessionIdHash.SessionIdHash Evergreen.V102.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V102.Route.Route
    , windowSize : Evergreen.V102.Coord.Coord Evergreen.V102.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V102.Ports.NotificationPermission
    , pwaStatus : Evergreen.V102.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V102.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V102.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V102.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V102.RichText.RichText) Evergreen.V102.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Evergreen.V102.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) Evergreen.V102.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.UserSession.ToBeFilledInByBackend (Evergreen.V102.SecretId.SecretId Evergreen.V102.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V102.GuildName.GuildName (Evergreen.V102.UserSession.ToBeFilledInByBackend (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V102.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage Evergreen.V102.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage Evergreen.V102.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V102.RichText.RichText) (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Evergreen.V102.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V102.UserSession.SetViewing
    | Local_SetName Evergreen.V102.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V102.Id.GuildOrDmIdNoThread (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Evergreen.V102.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Evergreen.V102.Message.Message Evergreen.V102.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V102.Id.GuildOrDmIdNoThread (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId) (Evergreen.V102.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId) (Evergreen.V102.Message.Message Evergreen.V102.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V102.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V102.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId
    , channelId : Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId
    , messageIndex : Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Effect.Time.Posix Evergreen.V102.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V102.RichText.RichText) Evergreen.V102.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Evergreen.V102.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) Evergreen.V102.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.SecretId.SecretId Evergreen.V102.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V102.LocalState.JoinGuildError
            { guildId : Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId
            , guild : Evergreen.V102.LocalState.FrontendGuild
            , owner : Evergreen.V102.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage Evergreen.V102.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage Evergreen.V102.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V102.RichText.RichText) (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Evergreen.V102.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (List.Nonempty.Nonempty Evergreen.V102.RichText.RichText) (Maybe (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V102.SessionIdHash.SessionIdHash Evergreen.V102.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V102.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V102.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) LocalChange
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
    { messageIndex : Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Evergreen.V102.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V102.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V102.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V102.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V102.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V102.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V102.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V102.Coord.Coord Evergreen.V102.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V102.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V102.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V102.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Evergreen.V102.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId) (Evergreen.V102.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V102.Editable.Model
    , botToken : Evergreen.V102.Editable.Model
    , slackClientSecret : Evergreen.V102.Editable.Model
    , publicVapidKey : Evergreen.V102.Editable.Model
    , privateVapidKey : Evergreen.V102.Editable.Model
    , openRouterKey : Evergreen.V102.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V102.Local.Local LocalMsg Evergreen.V102.LocalState.LocalState
    , admin : Maybe Evergreen.V102.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V102.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId, Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId, Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId, Evergreen.V102.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V102.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V102.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V102.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.NonemptyDict.NonemptyDict (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Evergreen.V102.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V102.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V102.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V102.SecretId.SecretId Evergreen.V102.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V102.NonemptyDict.NonemptyDict Int Evergreen.V102.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V102.NonemptyDict.NonemptyDict Int Evergreen.V102.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V102.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V102.Coord.Coord Evergreen.V102.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V102.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V102.Ports.NotificationPermission
    , pwaStatus : Evergreen.V102.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V102.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V102.UserAgent.UserAgent
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
    , userId : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V102.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V102.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V102.Coord.Coord Evergreen.V102.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V102.NonemptyDict.NonemptyDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V102.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V102.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V102.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.LocalState.BackendGuild
    , discordModel : Evergreen.V102.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V102.OneToOne.OneToOne (Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId)
    , discordUsers : Evergreen.V102.OneToOne.OneToOne (Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.UserId) (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
    , discordBotId : Maybe (Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V102.DmChannel.DmChannelId Evergreen.V102.DmChannel.DmChannel
    , discordDms : Evergreen.V102.OneToOne.OneToOne (Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.ChannelId) Evergreen.V102.DmChannel.DmChannelId
    , slackDms : Evergreen.V102.OneToOne.OneToOne (Evergreen.V102.Slack.Id Evergreen.V102.Slack.ChannelId) Evergreen.V102.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V102.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V102.OneToOne.OneToOne String (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId)
    , slackUsers : Evergreen.V102.OneToOne.OneToOne (Evergreen.V102.Slack.Id Evergreen.V102.Slack.UserId) (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
    , slackServers : Evergreen.V102.OneToOne.OneToOne (Evergreen.V102.Slack.Id Evergreen.V102.Slack.TeamId) (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId)
    , slackToken : Maybe Evergreen.V102.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V102.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V102.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V102.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V102.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V102.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V102.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V102.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V102.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V102.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V102.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) Evergreen.V102.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) Evergreen.V102.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V102.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V102.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V102.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage (Evergreen.V102.Coord.Coord Evergreen.V102.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V102.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V102.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V102.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V102.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V102.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V102.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V102.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V102.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V102.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V102.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V102.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V102.NonemptyDict.NonemptyDict Int Evergreen.V102.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V102.NonemptyDict.NonemptyDict Int Evergreen.V102.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V102.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V102.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V102.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V102.Editable.Msg Evergreen.V102.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V102.Editable.Msg (Maybe Evergreen.V102.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V102.Editable.Msg (Maybe Evergreen.V102.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V102.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V102.Editable.Msg Evergreen.V102.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V102.Editable.Msg (Maybe String))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V102.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V102.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V102.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V102.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V102.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V102.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V102.Id.GuildOrDmId (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V102.Id.GuildOrDmIdNoThread Evergreen.V102.Id.ThreadRouteWithMessage Evergreen.V102.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V102.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V102.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) Evergreen.V102.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V102.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float Float


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute )) Int Evergreen.V102.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute )) Int Evergreen.V102.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V102.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V102.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V102.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V102.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.SecretId.SecretId Evergreen.V102.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute )) Evergreen.V102.PersonName.PersonName Evergreen.V102.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V102.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V102.Slack.OAuthCode Evergreen.V102.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V102.EmailAddress.EmailAddress (Result Evergreen.V102.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V102.EmailAddress.EmailAddress (Result Evergreen.V102.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V102.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V102.LocalState.DiscordBotToken (Result Evergreen.V102.Discord.HttpError ( Evergreen.V102.Discord.User, List Evergreen.V102.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.UserId)
        (Result
            Evergreen.V102.Discord.HttpError
            (List
                ( Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.GuildId
                , { guild : Evergreen.V102.Discord.Guild
                  , members : List Evergreen.V102.Discord.GuildMember
                  , channels : List ( Evergreen.V102.Discord.Channel2, List Evergreen.V102.Discord.Message )
                  , icon : Maybe Evergreen.V102.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V102.Discord.Channel, List Evergreen.V102.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) Evergreen.V102.Id.ThreadRouteWithMessage (Result Evergreen.V102.Discord.HttpError Evergreen.V102.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V102.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V102.DmChannel.DmChannelId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Result Evergreen.V102.Discord.HttpError Evergreen.V102.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V102.Discord.HttpError (List ( Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.UserId, Maybe Evergreen.V102.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V102.Slack.CurrentUser
            , team : Evergreen.V102.Slack.Team
            , users : List Evergreen.V102.Slack.User
            , channels : List ( Evergreen.V102.Slack.Channel, List Evergreen.V102.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (Result Effect.Http.Error Evergreen.V102.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V102.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V102.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V102.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V102.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
