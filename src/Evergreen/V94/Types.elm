module Evergreen.V94.Types exposing (..)

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
import Evergreen.V94.AiChat
import Evergreen.V94.ChannelName
import Evergreen.V94.Coord
import Evergreen.V94.CssPixels
import Evergreen.V94.Discord
import Evergreen.V94.Discord.Id
import Evergreen.V94.DmChannel
import Evergreen.V94.Editable
import Evergreen.V94.EmailAddress
import Evergreen.V94.Emoji
import Evergreen.V94.FileStatus
import Evergreen.V94.GuildName
import Evergreen.V94.Id
import Evergreen.V94.Local
import Evergreen.V94.LocalState
import Evergreen.V94.Log
import Evergreen.V94.LoginForm
import Evergreen.V94.Message
import Evergreen.V94.MessageInput
import Evergreen.V94.MessageView
import Evergreen.V94.NonemptyDict
import Evergreen.V94.NonemptySet
import Evergreen.V94.OneToOne
import Evergreen.V94.Pages.Admin
import Evergreen.V94.PersonName
import Evergreen.V94.Ports
import Evergreen.V94.Postmark
import Evergreen.V94.RichText
import Evergreen.V94.Route
import Evergreen.V94.SecretId
import Evergreen.V94.SessionIdHash
import Evergreen.V94.Slack
import Evergreen.V94.Touch
import Evergreen.V94.TwoFactorAuthentication
import Evergreen.V94.Ui.Anim
import Evergreen.V94.User
import Evergreen.V94.UserAgent
import Evergreen.V94.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V94.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V94.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.DmChannel.FrontendDmChannel
    , user : Evergreen.V94.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V94.SessionIdHash.SessionIdHash Evergreen.V94.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V94.Route.Route
    , windowSize : Evergreen.V94.Coord.Coord Evergreen.V94.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V94.Ports.NotificationPermission
    , pwaStatus : Evergreen.V94.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V94.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V94.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V94.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V94.RichText.RichText) Evergreen.V94.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Evergreen.V94.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) Evergreen.V94.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.UserSession.ToBeFilledInByBackend (Evergreen.V94.SecretId.SecretId Evergreen.V94.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V94.GuildName.GuildName (Evergreen.V94.UserSession.ToBeFilledInByBackend (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V94.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage Evergreen.V94.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage Evergreen.V94.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V94.RichText.RichText) (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Evergreen.V94.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V94.UserSession.SetViewing
    | Local_SetName Evergreen.V94.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V94.Id.GuildOrDmIdNoThread (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Evergreen.V94.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Evergreen.V94.Message.Message Evergreen.V94.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V94.Id.GuildOrDmIdNoThread (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ThreadMessageId) (Evergreen.V94.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ThreadMessageId) (Evergreen.V94.Message.Message Evergreen.V94.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V94.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V94.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId
    , channelId : Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId
    , messageIndex : Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Effect.Time.Posix Evergreen.V94.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V94.RichText.RichText) Evergreen.V94.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Evergreen.V94.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) Evergreen.V94.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.SecretId.SecretId Evergreen.V94.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V94.LocalState.JoinGuildError
            { guildId : Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId
            , guild : Evergreen.V94.LocalState.FrontendGuild
            , owner : Evergreen.V94.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage Evergreen.V94.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage Evergreen.V94.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V94.RichText.RichText) (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Evergreen.V94.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (List.Nonempty.Nonempty Evergreen.V94.RichText.RichText) (Maybe (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V94.SessionIdHash.SessionIdHash Evergreen.V94.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V94.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V94.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V94.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V94.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V94.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V94.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V94.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V94.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V94.Coord.Coord Evergreen.V94.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V94.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V94.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Evergreen.V94.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V94.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Evergreen.V94.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ThreadMessageId) (Evergreen.V94.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V94.Editable.Model
    , botToken : Evergreen.V94.Editable.Model
    , slackClientSecret : Evergreen.V94.Editable.Model
    , publicVapidKey : Evergreen.V94.Editable.Model
    , privateVapidKey : Evergreen.V94.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V94.Local.Local LocalMsg Evergreen.V94.LocalState.LocalState
    , admin : Maybe Evergreen.V94.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V94.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId, Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId, Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId, Evergreen.V94.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V94.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V94.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V94.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.NonemptyDict.NonemptyDict (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Evergreen.V94.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V94.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V94.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V94.SecretId.SecretId Evergreen.V94.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V94.NonemptyDict.NonemptyDict Int Evergreen.V94.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V94.NonemptyDict.NonemptyDict Int Evergreen.V94.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V94.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V94.Coord.Coord Evergreen.V94.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V94.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V94.Ports.NotificationPermission
    , pwaStatus : Evergreen.V94.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V94.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V94.UserAgent.UserAgent
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
    , userId : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V94.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V94.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V94.Coord.Coord Evergreen.V94.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V94.NonemptyDict.NonemptyDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V94.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V94.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V94.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.LocalState.BackendGuild
    , discordModel : Evergreen.V94.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V94.OneToOne.OneToOne (Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId)
    , discordUsers : Evergreen.V94.OneToOne.OneToOne (Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.UserId) (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
    , discordBotId : Maybe (Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V94.DmChannel.DmChannelId Evergreen.V94.DmChannel.DmChannel
    , discordDms : Evergreen.V94.OneToOne.OneToOne (Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.ChannelId) Evergreen.V94.DmChannel.DmChannelId
    , slackDms : Evergreen.V94.OneToOne.OneToOne (Evergreen.V94.Slack.Id Evergreen.V94.Slack.ChannelId) Evergreen.V94.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V94.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V94.OneToOne.OneToOne String (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId)
    , slackUsers : Evergreen.V94.OneToOne.OneToOne (Evergreen.V94.Slack.Id Evergreen.V94.Slack.UserId) (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
    , slackServers : Evergreen.V94.OneToOne.OneToOne (Evergreen.V94.Slack.Id Evergreen.V94.Slack.TeamId) (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId)
    , slackToken : Maybe Evergreen.V94.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V94.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V94.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V94.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V94.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V94.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V94.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V94.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V94.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V94.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V94.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) Evergreen.V94.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) Evergreen.V94.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V94.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V94.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V94.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage (Evergreen.V94.Coord.Coord Evergreen.V94.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V94.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V94.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V94.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V94.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V94.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V94.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V94.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V94.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V94.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V94.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V94.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V94.NonemptyDict.NonemptyDict Int Evergreen.V94.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V94.NonemptyDict.NonemptyDict Int Evergreen.V94.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V94.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V94.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V94.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V94.Editable.Msg Evergreen.V94.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V94.Editable.Msg (Maybe Evergreen.V94.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V94.Editable.Msg (Maybe Evergreen.V94.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V94.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V94.Editable.Msg Evergreen.V94.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V94.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V94.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V94.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V94.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V94.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V94.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V94.Id.GuildOrDmId (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V94.Id.GuildOrDmIdNoThread Evergreen.V94.Id.ThreadRouteWithMessage Evergreen.V94.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V94.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V94.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) Evergreen.V94.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V94.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute )) Int Evergreen.V94.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute )) Int Evergreen.V94.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V94.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V94.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V94.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V94.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.SecretId.SecretId Evergreen.V94.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute )) Evergreen.V94.PersonName.PersonName Evergreen.V94.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V94.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V94.Slack.OAuthCode Evergreen.V94.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V94.EmailAddress.EmailAddress (Result Evergreen.V94.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V94.EmailAddress.EmailAddress (Result Evergreen.V94.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V94.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V94.LocalState.DiscordBotToken (Result Evergreen.V94.Discord.HttpError ( Evergreen.V94.Discord.User, List Evergreen.V94.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.UserId)
        (Result
            Evergreen.V94.Discord.HttpError
            (List
                ( Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.GuildId
                , { guild : Evergreen.V94.Discord.Guild
                  , members : List Evergreen.V94.Discord.GuildMember
                  , channels : List ( Evergreen.V94.Discord.Channel2, List Evergreen.V94.Discord.Message )
                  , icon : Maybe Evergreen.V94.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V94.Discord.Channel, List Evergreen.V94.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) Evergreen.V94.Id.ThreadRouteWithMessage (Result Evergreen.V94.Discord.HttpError Evergreen.V94.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V94.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V94.DmChannel.DmChannelId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Result Evergreen.V94.Discord.HttpError Evergreen.V94.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V94.Discord.HttpError (List ( Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.UserId, Maybe Evergreen.V94.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V94.Slack.CurrentUser
            , team : Evergreen.V94.Slack.Team
            , users : List Evergreen.V94.Slack.User
            , channels : List ( Evergreen.V94.Slack.Channel, List Evergreen.V94.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (Result Effect.Http.Error Evergreen.V94.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V94.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V94.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V94.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V94.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
