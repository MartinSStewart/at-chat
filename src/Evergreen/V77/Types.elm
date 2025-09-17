module Evergreen.V77.Types exposing (..)

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
import Evergreen.V77.AiChat
import Evergreen.V77.ChannelName
import Evergreen.V77.Coord
import Evergreen.V77.CssPixels
import Evergreen.V77.Discord
import Evergreen.V77.Discord.Id
import Evergreen.V77.DmChannel
import Evergreen.V77.Editable
import Evergreen.V77.EmailAddress
import Evergreen.V77.Emoji
import Evergreen.V77.FileStatus
import Evergreen.V77.GuildName
import Evergreen.V77.Id
import Evergreen.V77.Local
import Evergreen.V77.LocalState
import Evergreen.V77.Log
import Evergreen.V77.LoginForm
import Evergreen.V77.Message
import Evergreen.V77.MessageInput
import Evergreen.V77.MessageView
import Evergreen.V77.NonemptyDict
import Evergreen.V77.NonemptySet
import Evergreen.V77.OneToOne
import Evergreen.V77.Pages.Admin
import Evergreen.V77.PersonName
import Evergreen.V77.Ports
import Evergreen.V77.Postmark
import Evergreen.V77.RichText
import Evergreen.V77.Route
import Evergreen.V77.SecretId
import Evergreen.V77.Slack
import Evergreen.V77.Touch
import Evergreen.V77.TwoFactorAuthentication
import Evergreen.V77.Ui.Anim
import Evergreen.V77.User
import Evergreen.V77.UserAgent
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V77.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V77.LocalState.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.DmChannel.FrontendDmChannel
    , user : Evergreen.V77.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V77.Route.Route
    , windowSize : Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V77.Ports.NotificationPermission
    , pwaStatus : Evergreen.V77.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V77.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V77.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V77.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V77.RichText.RichText) Evergreen.V77.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Evergreen.V77.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) Evergreen.V77.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V77.SecretId.SecretId Evergreen.V77.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V77.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V77.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage Evergreen.V77.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage Evergreen.V77.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V77.RichText.RichText) (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Evergreen.V77.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Evergreen.V77.Message.Message Evergreen.V77.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId) (Evergreen.V77.Message.Message Evergreen.V77.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Evergreen.V77.Message.Message Evergreen.V77.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId) (Evergreen.V77.Message.Message Evergreen.V77.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V77.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V77.Id.GuildOrDmIdNoThread (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Evergreen.V77.Message.Message Evergreen.V77.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V77.Id.GuildOrDmIdNoThread (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId) (Evergreen.V77.Message.Message Evergreen.V77.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V77.LocalState.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V77.LocalState.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId
    , channelId : Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId
    , messageIndex : Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Effect.Time.Posix Evergreen.V77.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V77.RichText.RichText) Evergreen.V77.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Evergreen.V77.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) Evergreen.V77.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.SecretId.SecretId Evergreen.V77.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V77.LocalState.JoinGuildError
            { guildId : Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId
            , guild : Evergreen.V77.LocalState.FrontendGuild
            , owner : Evergreen.V77.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage Evergreen.V77.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage Evergreen.V77.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V77.RichText.RichText) (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Evergreen.V77.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (List.Nonempty.Nonempty Evergreen.V77.RichText.RichText) (Maybe (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error


type LocalMsg
    = LocalChange (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V77.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V77.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V77.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V77.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V77.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V77.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V77.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V77.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Evergreen.V77.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V77.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Evergreen.V77.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId) (Evergreen.V77.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V77.Editable.Model
    , botToken : Evergreen.V77.Editable.Model
    , slackClientSecret : Evergreen.V77.Editable.Model
    , publicVapidKey : Evergreen.V77.Editable.Model
    , privateVapidKey : Evergreen.V77.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V77.Local.Local LocalMsg Evergreen.V77.LocalState.LocalState
    , admin : Maybe Evergreen.V77.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V77.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId, Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId, Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId, Evergreen.V77.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V77.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V77.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V77.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.NonemptyDict.NonemptyDict (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Evergreen.V77.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V77.FileStatus.FileDataWithImage
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V77.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V77.SecretId.SecretId Evergreen.V77.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V77.NonemptyDict.NonemptyDict Int Evergreen.V77.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V77.NonemptyDict.NonemptyDict Int Evergreen.V77.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V77.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V77.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V77.Ports.NotificationPermission
    , pwaStatus : Evergreen.V77.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V77.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V77.UserAgent.UserAgent
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V77.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V77.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V77.NonemptyDict.NonemptyDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V77.LocalState.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V77.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V77.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.LocalState.BackendGuild
    , discordModel : Evergreen.V77.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V77.OneToOne.OneToOne (Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId)
    , discordUsers : Evergreen.V77.OneToOne.OneToOne (Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    , discordBotId : Maybe (Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V77.DmChannel.DmChannelId Evergreen.V77.DmChannel.DmChannel
    , discordDms : Evergreen.V77.OneToOne.OneToOne (Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.ChannelId) Evergreen.V77.DmChannel.DmChannelId
    , slackDms : Evergreen.V77.OneToOne.OneToOne (Evergreen.V77.Slack.Id Evergreen.V77.Slack.ChannelId) Evergreen.V77.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V77.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V77.OneToOne.OneToOne String (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId)
    , slackUsers : Evergreen.V77.OneToOne.OneToOne (Evergreen.V77.Slack.Id Evergreen.V77.Slack.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    , slackServers : Evergreen.V77.OneToOne.OneToOne (Evergreen.V77.Slack.Id Evergreen.V77.Slack.TeamId) (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId)
    , slackToken : Maybe Evergreen.V77.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V77.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V77.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V77.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V77.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V77.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V77.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V77.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V77.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V77.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V77.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) Evergreen.V77.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) Evergreen.V77.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V77.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V77.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V77.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage (Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V77.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V77.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V77.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V77.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V77.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V77.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V77.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V77.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V77.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V77.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V77.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V77.Id.GuildOrDmIdNoThread, Evergreen.V77.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V77.NonemptyDict.NonemptyDict Int Evergreen.V77.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V77.NonemptyDict.NonemptyDict Int Evergreen.V77.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V77.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V77.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V77.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V77.Editable.Msg Evergreen.V77.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V77.Editable.Msg (Maybe Evergreen.V77.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V77.Editable.Msg (Maybe Evergreen.V77.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V77.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V77.Editable.Msg Evergreen.V77.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V77.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V77.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V77.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V77.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V77.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V77.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V77.Id.GuildOrDmId (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V77.Id.GuildOrDmIdNoThread Evergreen.V77.Id.ThreadRouteWithMessage Evergreen.V77.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V77.LocalState.SubscribeData)
    | SelectedNotificationMode Evergreen.V77.LocalState.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) Evergreen.V77.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V77.UserAgent.UserAgent


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V77.Id.GuildOrDmIdNoThread, Evergreen.V77.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V77.Id.GuildOrDmIdNoThread, Evergreen.V77.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V77.Id.GuildOrDmIdNoThread, Evergreen.V77.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V77.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V77.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V77.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V77.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.SecretId.SecretId Evergreen.V77.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V77.Id.GuildOrDmIdNoThread, Evergreen.V77.Id.ThreadRoute )) Evergreen.V77.PersonName.PersonName
    | AiChatToBackend Evergreen.V77.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V77.Id.GuildOrDmIdNoThread, Evergreen.V77.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V77.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V77.EmailAddress.EmailAddress (Result Evergreen.V77.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V77.EmailAddress.EmailAddress (Result Evergreen.V77.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V77.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V77.LocalState.DiscordBotToken (Result Evergreen.V77.Discord.HttpError ( Evergreen.V77.Discord.User, List Evergreen.V77.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.UserId)
        (Result
            Evergreen.V77.Discord.HttpError
            (List
                ( Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.GuildId
                , { guild : Evergreen.V77.Discord.Guild
                  , members : List Evergreen.V77.Discord.GuildMember
                  , channels : List ( Evergreen.V77.Discord.Channel2, List Evergreen.V77.Discord.Message )
                  , icon : Maybe Evergreen.V77.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V77.Discord.Channel, List Evergreen.V77.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) Evergreen.V77.Id.ThreadRouteWithMessage (Result Evergreen.V77.Discord.HttpError Evergreen.V77.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V77.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V77.DmChannel.DmChannelId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Result Evergreen.V77.Discord.HttpError Evergreen.V77.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V77.Discord.HttpError (List ( Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.UserId, Maybe Evergreen.V77.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V77.Slack.CurrentUser
            , team : Evergreen.V77.Slack.Team
            , users : List Evergreen.V77.Slack.User
            , channels : List ( Evergreen.V77.Slack.Channel, List Evergreen.V77.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Result Effect.Http.Error Evergreen.V77.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V77.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V77.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V77.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V77.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
