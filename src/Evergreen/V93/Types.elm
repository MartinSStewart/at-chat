module Evergreen.V93.Types exposing (..)

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
import Evergreen.V93.AiChat
import Evergreen.V93.ChannelName
import Evergreen.V93.Coord
import Evergreen.V93.CssPixels
import Evergreen.V93.Discord
import Evergreen.V93.Discord.Id
import Evergreen.V93.DmChannel
import Evergreen.V93.Editable
import Evergreen.V93.EmailAddress
import Evergreen.V93.Emoji
import Evergreen.V93.FileStatus
import Evergreen.V93.GuildName
import Evergreen.V93.Id
import Evergreen.V93.Local
import Evergreen.V93.LocalState
import Evergreen.V93.Log
import Evergreen.V93.LoginForm
import Evergreen.V93.Message
import Evergreen.V93.MessageInput
import Evergreen.V93.MessageView
import Evergreen.V93.NonemptyDict
import Evergreen.V93.NonemptySet
import Evergreen.V93.OneToOne
import Evergreen.V93.Pages.Admin
import Evergreen.V93.PersonName
import Evergreen.V93.Ports
import Evergreen.V93.Postmark
import Evergreen.V93.RichText
import Evergreen.V93.Route
import Evergreen.V93.SecretId
import Evergreen.V93.SessionIdHash
import Evergreen.V93.Slack
import Evergreen.V93.Touch
import Evergreen.V93.TwoFactorAuthentication
import Evergreen.V93.Ui.Anim
import Evergreen.V93.User
import Evergreen.V93.UserAgent
import Evergreen.V93.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V93.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V93.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.DmChannel.FrontendDmChannel
    , user : Evergreen.V93.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.User.FrontendUser
    , otherSessions : SeqDict.SeqDict Evergreen.V93.SessionIdHash.SessionIdHash Evergreen.V93.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V93.Route.Route
    , windowSize : Evergreen.V93.Coord.Coord Evergreen.V93.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V93.Ports.NotificationPermission
    , pwaStatus : Evergreen.V93.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V93.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V93.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V93.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V93.RichText.RichText) Evergreen.V93.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Evergreen.V93.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) Evergreen.V93.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.UserSession.ToBeFilledInByBackend (Evergreen.V93.SecretId.SecretId Evergreen.V93.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V93.GuildName.GuildName (Evergreen.V93.UserSession.ToBeFilledInByBackend (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V93.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage Evergreen.V93.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage Evergreen.V93.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V93.RichText.RichText) (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Evergreen.V93.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V93.UserSession.SetViewing
    | Local_SetName Evergreen.V93.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V93.Id.GuildOrDmIdNoThread (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Evergreen.V93.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Evergreen.V93.Message.Message Evergreen.V93.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V93.Id.GuildOrDmIdNoThread (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ThreadMessageId) (Evergreen.V93.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ThreadMessageId) (Evergreen.V93.Message.Message Evergreen.V93.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V93.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V93.UserSession.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId
    , channelId : Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId
    , messageIndex : Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Effect.Time.Posix Evergreen.V93.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V93.RichText.RichText) Evergreen.V93.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Evergreen.V93.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) Evergreen.V93.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.SecretId.SecretId Evergreen.V93.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V93.LocalState.JoinGuildError
            { guildId : Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId
            , guild : Evergreen.V93.LocalState.FrontendGuild
            , owner : Evergreen.V93.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage Evergreen.V93.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage Evergreen.V93.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V93.RichText.RichText) (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Evergreen.V93.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (List.Nonempty.Nonempty Evergreen.V93.RichText.RichText) (Maybe (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V93.SessionIdHash.SessionIdHash Evergreen.V93.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V93.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing (Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute ))


type LocalMsg
    = LocalChange (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V93.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V93.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V93.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V93.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V93.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V93.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V93.Coord.Coord Evergreen.V93.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V93.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V93.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Evergreen.V93.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V93.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Evergreen.V93.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ThreadMessageId) (Evergreen.V93.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V93.Editable.Model
    , botToken : Evergreen.V93.Editable.Model
    , slackClientSecret : Evergreen.V93.Editable.Model
    , publicVapidKey : Evergreen.V93.Editable.Model
    , privateVapidKey : Evergreen.V93.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V93.Local.Local LocalMsg Evergreen.V93.LocalState.LocalState
    , admin : Maybe Evergreen.V93.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V93.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId, Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId, Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId, Evergreen.V93.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V93.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V93.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V93.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.NonemptyDict.NonemptyDict (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Evergreen.V93.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V93.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V93.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V93.SecretId.SecretId Evergreen.V93.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V93.NonemptyDict.NonemptyDict Int Evergreen.V93.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V93.NonemptyDict.NonemptyDict Int Evergreen.V93.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V93.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V93.Coord.Coord Evergreen.V93.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V93.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V93.Ports.NotificationPermission
    , pwaStatus : Evergreen.V93.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V93.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V93.UserAgent.UserAgent
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V93.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V93.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V93.Coord.Coord Evergreen.V93.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V93.NonemptyDict.NonemptyDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V93.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V93.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V93.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.LocalState.BackendGuild
    , discordModel : Evergreen.V93.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V93.OneToOne.OneToOne (Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId)
    , discordUsers : Evergreen.V93.OneToOne.OneToOne (Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    , discordBotId : Maybe (Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V93.DmChannel.DmChannelId Evergreen.V93.DmChannel.DmChannel
    , discordDms : Evergreen.V93.OneToOne.OneToOne (Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.ChannelId) Evergreen.V93.DmChannel.DmChannelId
    , slackDms : Evergreen.V93.OneToOne.OneToOne (Evergreen.V93.Slack.Id Evergreen.V93.Slack.ChannelId) Evergreen.V93.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V93.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V93.OneToOne.OneToOne String (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId)
    , slackUsers : Evergreen.V93.OneToOne.OneToOne (Evergreen.V93.Slack.Id Evergreen.V93.Slack.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    , slackServers : Evergreen.V93.OneToOne.OneToOne (Evergreen.V93.Slack.Id Evergreen.V93.Slack.TeamId) (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId)
    , slackToken : Maybe Evergreen.V93.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V93.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V93.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V93.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V93.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V93.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V93.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V93.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V93.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V93.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V93.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) Evergreen.V93.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) Evergreen.V93.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V93.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V93.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V93.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage (Evergreen.V93.Coord.Coord Evergreen.V93.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V93.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V93.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V93.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V93.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V93.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V93.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V93.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V93.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V93.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V93.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V93.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V93.NonemptyDict.NonemptyDict Int Evergreen.V93.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V93.NonemptyDict.NonemptyDict Int Evergreen.V93.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V93.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V93.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V93.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V93.Editable.Msg Evergreen.V93.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V93.Editable.Msg (Maybe Evergreen.V93.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V93.Editable.Msg (Maybe Evergreen.V93.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V93.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V93.Editable.Msg Evergreen.V93.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V93.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V93.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V93.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V93.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V93.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V93.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V93.Id.GuildOrDmId (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V93.Id.GuildOrDmIdNoThread Evergreen.V93.Id.ThreadRouteWithMessage Evergreen.V93.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V93.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V93.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) Evergreen.V93.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V93.UserAgent.UserAgent
    | WindowHasFocusChanged Bool
    | GotServiceWorkerMessage String


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute )) Int Evergreen.V93.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute )) Int Evergreen.V93.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V93.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V93.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V93.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V93.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.SecretId.SecretId Evergreen.V93.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute )) Evergreen.V93.PersonName.PersonName Evergreen.V93.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V93.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V93.Slack.OAuthCode Evergreen.V93.SessionIdHash.SessionIdHash


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V93.EmailAddress.EmailAddress (Result Evergreen.V93.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V93.EmailAddress.EmailAddress (Result Evergreen.V93.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V93.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V93.LocalState.DiscordBotToken (Result Evergreen.V93.Discord.HttpError ( Evergreen.V93.Discord.User, List Evergreen.V93.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.UserId)
        (Result
            Evergreen.V93.Discord.HttpError
            (List
                ( Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.GuildId
                , { guild : Evergreen.V93.Discord.Guild
                  , members : List Evergreen.V93.Discord.GuildMember
                  , channels : List ( Evergreen.V93.Discord.Channel2, List Evergreen.V93.Discord.Message )
                  , icon : Maybe Evergreen.V93.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V93.Discord.Channel, List Evergreen.V93.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) Evergreen.V93.Id.ThreadRouteWithMessage (Result Evergreen.V93.Discord.HttpError Evergreen.V93.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V93.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V93.DmChannel.DmChannelId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Result Evergreen.V93.Discord.HttpError Evergreen.V93.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V93.Discord.HttpError (List ( Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.UserId, Maybe Evergreen.V93.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V93.Slack.CurrentUser
            , team : Evergreen.V93.Slack.Team
            , users : List Evergreen.V93.Slack.User
            , channels : List ( Evergreen.V93.Slack.Channel, List Evergreen.V93.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Result Effect.Http.Error Evergreen.V93.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V93.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V93.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V93.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V93.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
