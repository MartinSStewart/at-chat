module Evergreen.V109.Types exposing (..)

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
import Evergreen.V109.AiChat
import Evergreen.V109.ChannelName
import Evergreen.V109.Coord
import Evergreen.V109.CssPixels
import Evergreen.V109.Discord
import Evergreen.V109.Discord.Id
import Evergreen.V109.DmChannel
import Evergreen.V109.Editable
import Evergreen.V109.EmailAddress
import Evergreen.V109.Emoji
import Evergreen.V109.FileStatus
import Evergreen.V109.GuildName
import Evergreen.V109.Id
import Evergreen.V109.Local
import Evergreen.V109.LocalState
import Evergreen.V109.Log
import Evergreen.V109.LoginForm
import Evergreen.V109.Message
import Evergreen.V109.MessageInput
import Evergreen.V109.MessageView
import Evergreen.V109.NonemptyDict
import Evergreen.V109.NonemptySet
import Evergreen.V109.OneToOne
import Evergreen.V109.Pages.Admin
import Evergreen.V109.PersonName
import Evergreen.V109.Ports
import Evergreen.V109.Postmark
import Evergreen.V109.RichText
import Evergreen.V109.Route
import Evergreen.V109.SecretId
import Evergreen.V109.SessionIdHash
import Evergreen.V109.Slack
import Evergreen.V109.TextEditor
import Evergreen.V109.Touch
import Evergreen.V109.TwoFactorAuthentication
import Evergreen.V109.Ui.Anim
import Evergreen.V109.User
import Evergreen.V109.UserAgent
import Evergreen.V109.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V109.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V109.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.DmChannel.FrontendDmChannel
    , user : Evergreen.V109.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V109.SessionIdHash.SessionIdHash Evergreen.V109.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V109.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V109.Route.Route
    , windowSize : Evergreen.V109.Coord.Coord Evergreen.V109.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V109.Ports.NotificationPermission
    , pwaStatus : Evergreen.V109.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V109.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V109.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V109.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V109.RichText.RichText) Evergreen.V109.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Evergreen.V109.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) Evergreen.V109.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.UserSession.ToBeFilledInByBackend (Evergreen.V109.SecretId.SecretId Evergreen.V109.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V109.GuildName.GuildName (Evergreen.V109.UserSession.ToBeFilledInByBackend (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V109.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage Evergreen.V109.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage Evergreen.V109.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V109.RichText.RichText) (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Evergreen.V109.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V109.UserSession.SetViewing
    | Local_SetName Evergreen.V109.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V109.Id.GuildOrDmIdNoThread (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Evergreen.V109.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Evergreen.V109.Message.Message Evergreen.V109.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V109.Id.GuildOrDmIdNoThread (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId) (Evergreen.V109.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId) (Evergreen.V109.Message.Message Evergreen.V109.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V109.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V109.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V109.TextEditor.LocalChange


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId
    , channelId : Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId
    , messageIndex : Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Effect.Time.Posix Evergreen.V109.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V109.RichText.RichText) Evergreen.V109.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Evergreen.V109.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) Evergreen.V109.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.SecretId.SecretId Evergreen.V109.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V109.LocalState.JoinGuildError
            { guildId : Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId
            , guild : Evergreen.V109.LocalState.FrontendGuild
            , owner : Evergreen.V109.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage Evergreen.V109.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage Evergreen.V109.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V109.RichText.RichText) (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Evergreen.V109.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (List.Nonempty.Nonempty Evergreen.V109.RichText.RichText) (Maybe (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V109.SessionIdHash.SessionIdHash Evergreen.V109.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V109.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V109.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V109.TextEditor.ServerChange


type LocalMsg
    = LocalChange (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) LocalChange
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
    { messageIndex : Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Evergreen.V109.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V109.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V109.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V109.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V109.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V109.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V109.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V109.Coord.Coord Evergreen.V109.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V109.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V109.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V109.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Evergreen.V109.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId) (Evergreen.V109.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V109.Editable.Model
    , botToken : Evergreen.V109.Editable.Model
    , slackClientSecret : Evergreen.V109.Editable.Model
    , publicVapidKey : Evergreen.V109.Editable.Model
    , privateVapidKey : Evergreen.V109.Editable.Model
    , openRouterKey : Evergreen.V109.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V109.Local.Local LocalMsg Evergreen.V109.LocalState.LocalState
    , admin : Maybe Evergreen.V109.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V109.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId, Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId, Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId, Evergreen.V109.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V109.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V109.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V109.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.NonemptyDict.NonemptyDict (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Evergreen.V109.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V109.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V109.TextEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V109.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V109.SecretId.SecretId Evergreen.V109.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V109.NonemptyDict.NonemptyDict Int Evergreen.V109.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V109.NonemptyDict.NonemptyDict Int Evergreen.V109.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V109.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V109.Coord.Coord Evergreen.V109.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V109.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V109.Ports.NotificationPermission
    , pwaStatus : Evergreen.V109.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V109.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V109.UserAgent.UserAgent
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
    , userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V109.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V109.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V109.Coord.Coord Evergreen.V109.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V109.NonemptyDict.NonemptyDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V109.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V109.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V109.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.LocalState.BackendGuild
    , discordModel : Evergreen.V109.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V109.OneToOne.OneToOne (Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId)
    , discordUsers : Evergreen.V109.OneToOne.OneToOne (Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    , discordBotId : Maybe (Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V109.DmChannel.DmChannelId Evergreen.V109.DmChannel.DmChannel
    , discordDms : Evergreen.V109.OneToOne.OneToOne (Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.ChannelId) Evergreen.V109.DmChannel.DmChannelId
    , slackDms : Evergreen.V109.OneToOne.OneToOne (Evergreen.V109.Slack.Id Evergreen.V109.Slack.ChannelId) Evergreen.V109.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V109.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V109.OneToOne.OneToOne String (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId)
    , slackUsers : Evergreen.V109.OneToOne.OneToOne (Evergreen.V109.Slack.Id Evergreen.V109.Slack.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    , slackServers : Evergreen.V109.OneToOne.OneToOne (Evergreen.V109.Slack.Id Evergreen.V109.Slack.TeamId) (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId)
    , slackToken : Maybe Evergreen.V109.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V109.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V109.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V109.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V109.TextEditor.LocalState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V109.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V109.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V109.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V109.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V109.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V109.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V109.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) Evergreen.V109.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) Evergreen.V109.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V109.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V109.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V109.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage (Evergreen.V109.Coord.Coord Evergreen.V109.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V109.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V109.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V109.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V109.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V109.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V109.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V109.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V109.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V109.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V109.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V109.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V109.NonemptyDict.NonemptyDict Int Evergreen.V109.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V109.NonemptyDict.NonemptyDict Int Evergreen.V109.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V109.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V109.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V109.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V109.Editable.Msg Evergreen.V109.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V109.Editable.Msg (Maybe Evergreen.V109.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V109.Editable.Msg (Maybe Evergreen.V109.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V109.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V109.Editable.Msg Evergreen.V109.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V109.Editable.Msg (Maybe String))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V109.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V109.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V109.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V109.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V109.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V109.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V109.Id.GuildOrDmId (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V109.Id.GuildOrDmIdNoThread Evergreen.V109.Id.ThreadRouteWithMessage Evergreen.V109.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V109.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V109.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) Evergreen.V109.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V109.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V109.TextEditor.Msg


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute )) Int Evergreen.V109.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute )) Int Evergreen.V109.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V109.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V109.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V109.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V109.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.SecretId.SecretId Evergreen.V109.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute )) Evergreen.V109.PersonName.PersonName Evergreen.V109.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V109.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V109.Slack.OAuthCode Evergreen.V109.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V109.EmailAddress.EmailAddress (Result Evergreen.V109.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V109.EmailAddress.EmailAddress (Result Evergreen.V109.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V109.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V109.LocalState.DiscordBotToken (Result Evergreen.V109.Discord.HttpError ( Evergreen.V109.Discord.User, List Evergreen.V109.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.UserId)
        (Result
            Evergreen.V109.Discord.HttpError
            (List
                ( Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.GuildId
                , { guild : Evergreen.V109.Discord.Guild
                  , members : List Evergreen.V109.Discord.GuildMember
                  , channels : List ( Evergreen.V109.Discord.Channel2, List Evergreen.V109.Discord.Message )
                  , icon : Maybe Evergreen.V109.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V109.Discord.Channel, List Evergreen.V109.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) Evergreen.V109.Id.ThreadRouteWithMessage (Result Evergreen.V109.Discord.HttpError Evergreen.V109.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V109.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V109.DmChannel.DmChannelId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Result Evergreen.V109.Discord.HttpError Evergreen.V109.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V109.Discord.HttpError (List ( Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.UserId, Maybe Evergreen.V109.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V109.Slack.CurrentUser
            , team : Evergreen.V109.Slack.Team
            , users : List Evergreen.V109.Slack.User
            , channels : List ( Evergreen.V109.Slack.Channel, List Evergreen.V109.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Result Effect.Http.Error Evergreen.V109.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V109.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V109.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V109.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V109.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
