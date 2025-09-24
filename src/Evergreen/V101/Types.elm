module Evergreen.V101.Types exposing (..)

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
import Evergreen.V101.AiChat
import Evergreen.V101.ChannelName
import Evergreen.V101.Coord
import Evergreen.V101.CssPixels
import Evergreen.V101.Discord
import Evergreen.V101.Discord.Id
import Evergreen.V101.DmChannel
import Evergreen.V101.Editable
import Evergreen.V101.EmailAddress
import Evergreen.V101.Emoji
import Evergreen.V101.FileStatus
import Evergreen.V101.GuildName
import Evergreen.V101.Id
import Evergreen.V101.Local
import Evergreen.V101.LocalState
import Evergreen.V101.Log
import Evergreen.V101.LoginForm
import Evergreen.V101.Message
import Evergreen.V101.MessageInput
import Evergreen.V101.MessageView
import Evergreen.V101.NonemptyDict
import Evergreen.V101.NonemptySet
import Evergreen.V101.OneToOne
import Evergreen.V101.Pages.Admin
import Evergreen.V101.PersonName
import Evergreen.V101.Ports
import Evergreen.V101.Postmark
import Evergreen.V101.RichText
import Evergreen.V101.Route
import Evergreen.V101.SecretId
import Evergreen.V101.SessionIdHash
import Evergreen.V101.Slack
import Evergreen.V101.Touch
import Evergreen.V101.TwoFactorAuthentication
import Evergreen.V101.Ui.Anim
import Evergreen.V101.User
import Evergreen.V101.UserAgent
import Evergreen.V101.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V101.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V101.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.DmChannel.FrontendDmChannel
    , user : Evergreen.V101.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V101.SessionIdHash.SessionIdHash Evergreen.V101.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V101.Route.Route
    , windowSize : Evergreen.V101.Coord.Coord Evergreen.V101.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V101.Ports.NotificationPermission
    , pwaStatus : Evergreen.V101.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V101.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V101.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V101.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V101.RichText.RichText) Evergreen.V101.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Evergreen.V101.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) Evergreen.V101.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.UserSession.ToBeFilledInByBackend (Evergreen.V101.SecretId.SecretId Evergreen.V101.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V101.GuildName.GuildName (Evergreen.V101.UserSession.ToBeFilledInByBackend (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V101.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage Evergreen.V101.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage Evergreen.V101.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V101.RichText.RichText) (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Evergreen.V101.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V101.UserSession.SetViewing
    | Local_SetName Evergreen.V101.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V101.Id.GuildOrDmIdNoThread (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Evergreen.V101.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Evergreen.V101.Message.Message Evergreen.V101.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V101.Id.GuildOrDmIdNoThread (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId) (Evergreen.V101.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId) (Evergreen.V101.Message.Message Evergreen.V101.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V101.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V101.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId
    , channelId : Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId
    , messageIndex : Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Effect.Time.Posix Evergreen.V101.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V101.RichText.RichText) Evergreen.V101.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Evergreen.V101.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) Evergreen.V101.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.SecretId.SecretId Evergreen.V101.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V101.LocalState.JoinGuildError
            { guildId : Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId
            , guild : Evergreen.V101.LocalState.FrontendGuild
            , owner : Evergreen.V101.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage Evergreen.V101.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage Evergreen.V101.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V101.RichText.RichText) (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Evergreen.V101.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (List.Nonempty.Nonempty Evergreen.V101.RichText.RichText) (Maybe (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V101.SessionIdHash.SessionIdHash Evergreen.V101.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V101.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V101.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) LocalChange
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
    { messageIndex : Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Evergreen.V101.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V101.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V101.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V101.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V101.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V101.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V101.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V101.Coord.Coord Evergreen.V101.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V101.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V101.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V101.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Evergreen.V101.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId) (Evergreen.V101.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V101.Editable.Model
    , botToken : Evergreen.V101.Editable.Model
    , slackClientSecret : Evergreen.V101.Editable.Model
    , publicVapidKey : Evergreen.V101.Editable.Model
    , privateVapidKey : Evergreen.V101.Editable.Model
    , openRouterKey : Evergreen.V101.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V101.Local.Local LocalMsg Evergreen.V101.LocalState.LocalState
    , admin : Maybe Evergreen.V101.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V101.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId, Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId, Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId, Evergreen.V101.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V101.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V101.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V101.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.NonemptyDict.NonemptyDict (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Evergreen.V101.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V101.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V101.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V101.SecretId.SecretId Evergreen.V101.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V101.NonemptyDict.NonemptyDict Int Evergreen.V101.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V101.NonemptyDict.NonemptyDict Int Evergreen.V101.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V101.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V101.Coord.Coord Evergreen.V101.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V101.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V101.Ports.NotificationPermission
    , pwaStatus : Evergreen.V101.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V101.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V101.UserAgent.UserAgent
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
    , userId : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V101.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V101.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V101.Coord.Coord Evergreen.V101.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V101.NonemptyDict.NonemptyDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V101.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V101.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V101.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.LocalState.BackendGuild
    , discordModel : Evergreen.V101.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V101.OneToOne.OneToOne (Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId)
    , discordUsers : Evergreen.V101.OneToOne.OneToOne (Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.UserId) (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
    , discordBotId : Maybe (Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V101.DmChannel.DmChannelId Evergreen.V101.DmChannel.DmChannel
    , discordDms : Evergreen.V101.OneToOne.OneToOne (Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.ChannelId) Evergreen.V101.DmChannel.DmChannelId
    , slackDms : Evergreen.V101.OneToOne.OneToOne (Evergreen.V101.Slack.Id Evergreen.V101.Slack.ChannelId) Evergreen.V101.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V101.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V101.OneToOne.OneToOne String (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId)
    , slackUsers : Evergreen.V101.OneToOne.OneToOne (Evergreen.V101.Slack.Id Evergreen.V101.Slack.UserId) (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
    , slackServers : Evergreen.V101.OneToOne.OneToOne (Evergreen.V101.Slack.Id Evergreen.V101.Slack.TeamId) (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId)
    , slackToken : Maybe Evergreen.V101.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V101.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V101.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V101.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V101.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V101.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V101.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V101.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V101.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V101.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V101.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) Evergreen.V101.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) Evergreen.V101.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V101.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V101.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V101.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage (Evergreen.V101.Coord.Coord Evergreen.V101.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V101.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V101.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V101.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V101.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V101.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V101.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V101.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V101.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V101.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V101.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V101.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V101.NonemptyDict.NonemptyDict Int Evergreen.V101.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V101.NonemptyDict.NonemptyDict Int Evergreen.V101.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V101.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V101.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V101.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V101.Editable.Msg Evergreen.V101.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V101.Editable.Msg (Maybe Evergreen.V101.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V101.Editable.Msg (Maybe Evergreen.V101.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V101.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V101.Editable.Msg Evergreen.V101.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V101.Editable.Msg (Maybe String))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V101.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V101.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V101.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V101.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V101.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V101.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V101.Id.GuildOrDmId (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V101.Id.GuildOrDmIdNoThread Evergreen.V101.Id.ThreadRouteWithMessage Evergreen.V101.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V101.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V101.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) Evergreen.V101.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V101.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute )) Int Evergreen.V101.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute )) Int Evergreen.V101.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V101.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V101.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V101.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V101.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.SecretId.SecretId Evergreen.V101.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute )) Evergreen.V101.PersonName.PersonName Evergreen.V101.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V101.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V101.Slack.OAuthCode Evergreen.V101.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V101.EmailAddress.EmailAddress (Result Evergreen.V101.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V101.EmailAddress.EmailAddress (Result Evergreen.V101.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V101.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V101.LocalState.DiscordBotToken (Result Evergreen.V101.Discord.HttpError ( Evergreen.V101.Discord.User, List Evergreen.V101.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.UserId)
        (Result
            Evergreen.V101.Discord.HttpError
            (List
                ( Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.GuildId
                , { guild : Evergreen.V101.Discord.Guild
                  , members : List Evergreen.V101.Discord.GuildMember
                  , channels : List ( Evergreen.V101.Discord.Channel2, List Evergreen.V101.Discord.Message )
                  , icon : Maybe Evergreen.V101.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V101.Discord.Channel, List Evergreen.V101.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) Evergreen.V101.Id.ThreadRouteWithMessage (Result Evergreen.V101.Discord.HttpError Evergreen.V101.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V101.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V101.DmChannel.DmChannelId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Result Evergreen.V101.Discord.HttpError Evergreen.V101.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V101.Discord.HttpError (List ( Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.UserId, Maybe Evergreen.V101.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V101.Slack.CurrentUser
            , team : Evergreen.V101.Slack.Team
            , users : List Evergreen.V101.Slack.User
            , channels : List ( Evergreen.V101.Slack.Channel, List Evergreen.V101.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (Result Effect.Http.Error Evergreen.V101.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V101.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V101.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V101.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V101.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
