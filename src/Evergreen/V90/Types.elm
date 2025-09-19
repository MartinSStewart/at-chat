module Evergreen.V90.Types exposing (..)

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
import Evergreen.V90.AiChat
import Evergreen.V90.ChannelName
import Evergreen.V90.Coord
import Evergreen.V90.CssPixels
import Evergreen.V90.Discord
import Evergreen.V90.Discord.Id
import Evergreen.V90.DmChannel
import Evergreen.V90.Editable
import Evergreen.V90.EmailAddress
import Evergreen.V90.Emoji
import Evergreen.V90.FileStatus
import Evergreen.V90.GuildName
import Evergreen.V90.Id
import Evergreen.V90.Local
import Evergreen.V90.LocalState
import Evergreen.V90.Log
import Evergreen.V90.LoginForm
import Evergreen.V90.Message
import Evergreen.V90.MessageInput
import Evergreen.V90.MessageView
import Evergreen.V90.NonemptyDict
import Evergreen.V90.NonemptySet
import Evergreen.V90.OneToOne
import Evergreen.V90.Pages.Admin
import Evergreen.V90.PersonName
import Evergreen.V90.Ports
import Evergreen.V90.Postmark
import Evergreen.V90.RichText
import Evergreen.V90.Route
import Evergreen.V90.SecretId
import Evergreen.V90.Slack
import Evergreen.V90.Touch
import Evergreen.V90.TwoFactorAuthentication
import Evergreen.V90.Ui.Anim
import Evergreen.V90.User
import Evergreen.V90.UserAgent
import Evergreen.V90.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V90.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V90.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.DmChannel.FrontendDmChannel
    , user : Evergreen.V90.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , otherSessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V90.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V90.Route.Route
    , windowSize : Evergreen.V90.Coord.Coord Evergreen.V90.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V90.Ports.NotificationPermission
    , pwaStatus : Evergreen.V90.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V90.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V90.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V90.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V90.RichText.RichText) Evergreen.V90.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Evergreen.V90.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) Evergreen.V90.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.UserSession.ToBeFilledInByBackend (Evergreen.V90.SecretId.SecretId Evergreen.V90.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V90.GuildName.GuildName (Evergreen.V90.UserSession.ToBeFilledInByBackend (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V90.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage Evergreen.V90.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage Evergreen.V90.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V90.RichText.RichText) (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Evergreen.V90.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V90.UserSession.SetViewing
    | Local_SetName Evergreen.V90.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V90.Id.GuildOrDmIdNoThread (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Evergreen.V90.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Evergreen.V90.Message.Message Evergreen.V90.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V90.Id.GuildOrDmIdNoThread (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ThreadMessageId) (Evergreen.V90.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ThreadMessageId) (Evergreen.V90.Message.Message Evergreen.V90.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V90.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V90.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId
    , channelId : Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId
    , messageIndex : Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Effect.Time.Posix Evergreen.V90.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V90.RichText.RichText) Evergreen.V90.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Evergreen.V90.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) Evergreen.V90.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.SecretId.SecretId Evergreen.V90.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V90.LocalState.JoinGuildError
            { guildId : Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId
            , guild : Evergreen.V90.LocalState.FrontendGuild
            , owner : Evergreen.V90.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage Evergreen.V90.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage Evergreen.V90.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V90.RichText.RichText) (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Evergreen.V90.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (List.Nonempty.Nonempty Evergreen.V90.RichText.RichText) (Maybe (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Effect.Lamdera.SessionId Evergreen.V90.UserSession.FrontendUserSession
    | Server_LoggedOut Effect.Lamdera.SessionId
    | Server_CurrentlyViewing (Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V90.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V90.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V90.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V90.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V90.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V90.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V90.Coord.Coord Evergreen.V90.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V90.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V90.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Evergreen.V90.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V90.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Evergreen.V90.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ThreadMessageId) (Evergreen.V90.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V90.Editable.Model
    , botToken : Evergreen.V90.Editable.Model
    , slackClientSecret : Evergreen.V90.Editable.Model
    , publicVapidKey : Evergreen.V90.Editable.Model
    , privateVapidKey : Evergreen.V90.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V90.Local.Local LocalMsg Evergreen.V90.LocalState.LocalState
    , admin : Maybe Evergreen.V90.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V90.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId, Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId, Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId, Evergreen.V90.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V90.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V90.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V90.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.NonemptyDict.NonemptyDict (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Evergreen.V90.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V90.FileStatus.FileDataWithImage
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V90.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V90.SecretId.SecretId Evergreen.V90.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V90.NonemptyDict.NonemptyDict Int Evergreen.V90.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V90.NonemptyDict.NonemptyDict Int Evergreen.V90.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V90.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V90.Coord.Coord Evergreen.V90.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V90.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V90.Ports.NotificationPermission
    , pwaStatus : Evergreen.V90.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V90.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V90.UserAgent.UserAgent
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V90.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V90.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V90.Coord.Coord Evergreen.V90.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V90.NonemptyDict.NonemptyDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V90.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V90.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V90.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.LocalState.BackendGuild
    , discordModel : Evergreen.V90.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V90.OneToOne.OneToOne (Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId)
    , discordUsers : Evergreen.V90.OneToOne.OneToOne (Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.UserId) (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
    , discordBotId : Maybe (Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V90.DmChannel.DmChannelId Evergreen.V90.DmChannel.DmChannel
    , discordDms : Evergreen.V90.OneToOne.OneToOne (Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.ChannelId) Evergreen.V90.DmChannel.DmChannelId
    , slackDms : Evergreen.V90.OneToOne.OneToOne (Evergreen.V90.Slack.Id Evergreen.V90.Slack.ChannelId) Evergreen.V90.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V90.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V90.OneToOne.OneToOne String (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId)
    , slackUsers : Evergreen.V90.OneToOne.OneToOne (Evergreen.V90.Slack.Id Evergreen.V90.Slack.UserId) (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
    , slackServers : Evergreen.V90.OneToOne.OneToOne (Evergreen.V90.Slack.Id Evergreen.V90.Slack.TeamId) (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId)
    , slackToken : Maybe Evergreen.V90.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V90.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V90.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V90.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V90.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V90.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V90.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V90.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V90.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V90.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V90.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) Evergreen.V90.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) Evergreen.V90.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V90.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V90.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V90.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage (Evergreen.V90.Coord.Coord Evergreen.V90.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V90.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V90.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V90.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V90.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V90.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V90.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V90.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V90.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V90.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V90.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V90.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V90.NonemptyDict.NonemptyDict Int Evergreen.V90.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V90.NonemptyDict.NonemptyDict Int Evergreen.V90.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V90.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V90.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V90.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V90.Editable.Msg Evergreen.V90.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V90.Editable.Msg (Maybe Evergreen.V90.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V90.Editable.Msg (Maybe Evergreen.V90.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V90.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V90.Editable.Msg Evergreen.V90.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V90.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V90.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V90.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V90.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V90.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V90.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V90.Id.GuildOrDmId (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V90.Id.GuildOrDmIdNoThread Evergreen.V90.Id.ThreadRouteWithMessage Evergreen.V90.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V90.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V90.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) Evergreen.V90.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V90.UserAgent.UserAgent


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute )) Int Evergreen.V90.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute )) Int Evergreen.V90.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V90.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V90.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V90.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V90.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.SecretId.SecretId Evergreen.V90.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute )) Evergreen.V90.PersonName.PersonName Evergreen.V90.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V90.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V90.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V90.EmailAddress.EmailAddress (Result Evergreen.V90.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V90.EmailAddress.EmailAddress (Result Evergreen.V90.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V90.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V90.LocalState.DiscordBotToken (Result Evergreen.V90.Discord.HttpError ( Evergreen.V90.Discord.User, List Evergreen.V90.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.UserId)
        (Result
            Evergreen.V90.Discord.HttpError
            (List
                ( Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.GuildId
                , { guild : Evergreen.V90.Discord.Guild
                  , members : List Evergreen.V90.Discord.GuildMember
                  , channels : List ( Evergreen.V90.Discord.Channel2, List Evergreen.V90.Discord.Message )
                  , icon : Maybe Evergreen.V90.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V90.Discord.Channel, List Evergreen.V90.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) Evergreen.V90.Id.ThreadRouteWithMessage (Result Evergreen.V90.Discord.HttpError Evergreen.V90.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V90.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V90.DmChannel.DmChannelId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Result Evergreen.V90.Discord.HttpError Evergreen.V90.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V90.Discord.HttpError (List ( Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.UserId, Maybe Evergreen.V90.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V90.Slack.CurrentUser
            , team : Evergreen.V90.Slack.Team
            , users : List Evergreen.V90.Slack.User
            , channels : List ( Evergreen.V90.Slack.Channel, List Evergreen.V90.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (Result Effect.Http.Error Evergreen.V90.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V90.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V90.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V90.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V90.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
