module Evergreen.V108.Types exposing (..)

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
import Evergreen.V108.AiChat
import Evergreen.V108.ChannelName
import Evergreen.V108.Coord
import Evergreen.V108.CssPixels
import Evergreen.V108.Discord
import Evergreen.V108.Discord.Id
import Evergreen.V108.DmChannel
import Evergreen.V108.Editable
import Evergreen.V108.EmailAddress
import Evergreen.V108.Emoji
import Evergreen.V108.FileStatus
import Evergreen.V108.GuildName
import Evergreen.V108.Id
import Evergreen.V108.Local
import Evergreen.V108.LocalState
import Evergreen.V108.Log
import Evergreen.V108.LoginForm
import Evergreen.V108.Message
import Evergreen.V108.MessageInput
import Evergreen.V108.MessageView
import Evergreen.V108.NonemptyDict
import Evergreen.V108.NonemptySet
import Evergreen.V108.OneToOne
import Evergreen.V108.Pages.Admin
import Evergreen.V108.PersonName
import Evergreen.V108.Ports
import Evergreen.V108.Postmark
import Evergreen.V108.RichText
import Evergreen.V108.Route
import Evergreen.V108.SecretId
import Evergreen.V108.SessionIdHash
import Evergreen.V108.Slack
import Evergreen.V108.Touch
import Evergreen.V108.TwoFactorAuthentication
import Evergreen.V108.Ui.Anim
import Evergreen.V108.User
import Evergreen.V108.UserAgent
import Evergreen.V108.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V108.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V108.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.DmChannel.FrontendDmChannel
    , user : Evergreen.V108.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V108.SessionIdHash.SessionIdHash Evergreen.V108.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V108.Route.Route
    , windowSize : Evergreen.V108.Coord.Coord Evergreen.V108.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V108.Ports.NotificationPermission
    , pwaStatus : Evergreen.V108.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V108.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V108.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V108.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V108.RichText.RichText) Evergreen.V108.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Evergreen.V108.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) Evergreen.V108.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.UserSession.ToBeFilledInByBackend (Evergreen.V108.SecretId.SecretId Evergreen.V108.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V108.GuildName.GuildName (Evergreen.V108.UserSession.ToBeFilledInByBackend (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V108.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage Evergreen.V108.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage Evergreen.V108.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V108.RichText.RichText) (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Evergreen.V108.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V108.UserSession.SetViewing
    | Local_SetName Evergreen.V108.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V108.Id.GuildOrDmIdNoThread (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Evergreen.V108.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Evergreen.V108.Message.Message Evergreen.V108.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V108.Id.GuildOrDmIdNoThread (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId) (Evergreen.V108.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId) (Evergreen.V108.Message.Message Evergreen.V108.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V108.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V108.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId
    , channelId : Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId
    , messageIndex : Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Effect.Time.Posix Evergreen.V108.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V108.RichText.RichText) Evergreen.V108.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Evergreen.V108.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) Evergreen.V108.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.SecretId.SecretId Evergreen.V108.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V108.LocalState.JoinGuildError
            { guildId : Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId
            , guild : Evergreen.V108.LocalState.FrontendGuild
            , owner : Evergreen.V108.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage Evergreen.V108.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage Evergreen.V108.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V108.RichText.RichText) (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Evergreen.V108.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (List.Nonempty.Nonempty Evergreen.V108.RichText.RichText) (Maybe (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V108.SessionIdHash.SessionIdHash Evergreen.V108.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V108.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V108.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) LocalChange
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
    { messageIndex : Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Evergreen.V108.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V108.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V108.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V108.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V108.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V108.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V108.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V108.Coord.Coord Evergreen.V108.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V108.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V108.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V108.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Evergreen.V108.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId) (Evergreen.V108.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V108.Editable.Model
    , botToken : Evergreen.V108.Editable.Model
    , slackClientSecret : Evergreen.V108.Editable.Model
    , publicVapidKey : Evergreen.V108.Editable.Model
    , privateVapidKey : Evergreen.V108.Editable.Model
    , openRouterKey : Evergreen.V108.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V108.Local.Local LocalMsg Evergreen.V108.LocalState.LocalState
    , admin : Maybe Evergreen.V108.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V108.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId, Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId, Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId, Evergreen.V108.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V108.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V108.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V108.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.NonemptyDict.NonemptyDict (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Evergreen.V108.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V108.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V108.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V108.SecretId.SecretId Evergreen.V108.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V108.NonemptyDict.NonemptyDict Int Evergreen.V108.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V108.NonemptyDict.NonemptyDict Int Evergreen.V108.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V108.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V108.Coord.Coord Evergreen.V108.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V108.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V108.Ports.NotificationPermission
    , pwaStatus : Evergreen.V108.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V108.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V108.UserAgent.UserAgent
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
    , userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V108.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V108.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V108.Coord.Coord Evergreen.V108.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V108.NonemptyDict.NonemptyDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V108.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V108.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V108.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.LocalState.BackendGuild
    , discordModel : Evergreen.V108.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V108.OneToOne.OneToOne (Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId)
    , discordUsers : Evergreen.V108.OneToOne.OneToOne (Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    , discordBotId : Maybe (Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V108.DmChannel.DmChannelId Evergreen.V108.DmChannel.DmChannel
    , discordDms : Evergreen.V108.OneToOne.OneToOne (Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.ChannelId) Evergreen.V108.DmChannel.DmChannelId
    , slackDms : Evergreen.V108.OneToOne.OneToOne (Evergreen.V108.Slack.Id Evergreen.V108.Slack.ChannelId) Evergreen.V108.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V108.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V108.OneToOne.OneToOne String (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId)
    , slackUsers : Evergreen.V108.OneToOne.OneToOne (Evergreen.V108.Slack.Id Evergreen.V108.Slack.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    , slackServers : Evergreen.V108.OneToOne.OneToOne (Evergreen.V108.Slack.Id Evergreen.V108.Slack.TeamId) (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId)
    , slackToken : Maybe Evergreen.V108.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V108.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V108.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V108.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V108.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V108.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V108.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V108.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V108.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V108.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V108.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) Evergreen.V108.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) Evergreen.V108.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V108.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V108.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V108.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage (Evergreen.V108.Coord.Coord Evergreen.V108.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V108.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V108.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V108.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V108.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V108.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V108.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V108.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V108.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V108.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V108.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V108.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V108.NonemptyDict.NonemptyDict Int Evergreen.V108.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V108.NonemptyDict.NonemptyDict Int Evergreen.V108.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V108.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V108.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V108.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V108.Editable.Msg Evergreen.V108.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V108.Editable.Msg (Maybe Evergreen.V108.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V108.Editable.Msg (Maybe Evergreen.V108.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V108.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V108.Editable.Msg Evergreen.V108.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V108.Editable.Msg (Maybe String))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V108.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V108.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V108.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V108.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V108.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V108.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V108.Id.GuildOrDmId (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V108.Id.GuildOrDmIdNoThread Evergreen.V108.Id.ThreadRouteWithMessage Evergreen.V108.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V108.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V108.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) Evergreen.V108.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V108.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute )) Int Evergreen.V108.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute )) Int Evergreen.V108.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V108.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V108.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V108.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V108.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.SecretId.SecretId Evergreen.V108.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute )) Evergreen.V108.PersonName.PersonName Evergreen.V108.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V108.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V108.Slack.OAuthCode Evergreen.V108.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V108.EmailAddress.EmailAddress (Result Evergreen.V108.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V108.EmailAddress.EmailAddress (Result Evergreen.V108.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V108.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V108.LocalState.DiscordBotToken (Result Evergreen.V108.Discord.HttpError ( Evergreen.V108.Discord.User, List Evergreen.V108.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.UserId)
        (Result
            Evergreen.V108.Discord.HttpError
            (List
                ( Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.GuildId
                , { guild : Evergreen.V108.Discord.Guild
                  , members : List Evergreen.V108.Discord.GuildMember
                  , channels : List ( Evergreen.V108.Discord.Channel2, List Evergreen.V108.Discord.Message )
                  , icon : Maybe Evergreen.V108.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V108.Discord.Channel, List Evergreen.V108.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) Evergreen.V108.Id.ThreadRouteWithMessage (Result Evergreen.V108.Discord.HttpError Evergreen.V108.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V108.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V108.DmChannel.DmChannelId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Result Evergreen.V108.Discord.HttpError Evergreen.V108.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V108.Discord.HttpError (List ( Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.UserId, Maybe Evergreen.V108.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V108.Slack.CurrentUser
            , team : Evergreen.V108.Slack.Team
            , users : List Evergreen.V108.Slack.User
            , channels : List ( Evergreen.V108.Slack.Channel, List Evergreen.V108.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Result Effect.Http.Error Evergreen.V108.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V108.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V108.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V108.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V108.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
