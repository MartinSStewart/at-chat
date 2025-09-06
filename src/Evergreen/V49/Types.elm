module Evergreen.V49.Types exposing (..)

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
import Evergreen.V49.AiChat
import Evergreen.V49.ChannelName
import Evergreen.V49.Coord
import Evergreen.V49.CssPixels
import Evergreen.V49.Discord
import Evergreen.V49.Discord.Id
import Evergreen.V49.DmChannel
import Evergreen.V49.Editable
import Evergreen.V49.EmailAddress
import Evergreen.V49.Emoji
import Evergreen.V49.FileStatus
import Evergreen.V49.GuildName
import Evergreen.V49.Id
import Evergreen.V49.Local
import Evergreen.V49.LocalState
import Evergreen.V49.Log
import Evergreen.V49.LoginForm
import Evergreen.V49.Message
import Evergreen.V49.MessageInput
import Evergreen.V49.MessageView
import Evergreen.V49.NonemptyDict
import Evergreen.V49.NonemptySet
import Evergreen.V49.OneToOne
import Evergreen.V49.Pages.Admin
import Evergreen.V49.PersonName
import Evergreen.V49.Ports
import Evergreen.V49.Postmark
import Evergreen.V49.RichText
import Evergreen.V49.Route
import Evergreen.V49.SecretId
import Evergreen.V49.Slack
import Evergreen.V49.Touch
import Evergreen.V49.TwoFactorAuthentication
import Evergreen.V49.Ui.Anim
import Evergreen.V49.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V49.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) Evergreen.V49.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.DmChannel.FrontendDmChannel
    , user : Evergreen.V49.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V49.Route.Route
    , windowSize : Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V49.Ports.NotificationPermission
    , pwaStatus : Evergreen.V49.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V49.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V49.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V49.RichText.RichText) Evergreen.V49.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Evergreen.V49.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) Evergreen.V49.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) Evergreen.V49.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V49.SecretId.SecretId Evergreen.V49.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V49.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V49.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage Evergreen.V49.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage Evergreen.V49.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V49.RichText.RichText) (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Evergreen.V49.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (Evergreen.V49.Message.Message Evergreen.V49.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ThreadMessageId) (Evergreen.V49.Message.Message Evergreen.V49.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (Evergreen.V49.Message.Message Evergreen.V49.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ThreadMessageId) (Evergreen.V49.Message.Message Evergreen.V49.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V49.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V49.Id.GuildOrDmIdNoThread (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (Evergreen.V49.Message.Message Evergreen.V49.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V49.Id.GuildOrDmIdNoThread (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ThreadMessageId) (Evergreen.V49.Message.Message Evergreen.V49.Id.ThreadMessageId)))


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId
    , channelId : Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId
    , messageIndex : Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Effect.Time.Posix Evergreen.V49.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V49.RichText.RichText) Evergreen.V49.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Evergreen.V49.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) Evergreen.V49.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) Evergreen.V49.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.SecretId.SecretId Evergreen.V49.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) Evergreen.V49.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V49.LocalState.JoinGuildError
            { guildId : Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId
            , guild : Evergreen.V49.LocalState.FrontendGuild
            , owner : Evergreen.V49.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage Evergreen.V49.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage Evergreen.V49.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V49.RichText.RichText) (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Evergreen.V49.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (List.Nonempty.Nonempty Evergreen.V49.RichText.RichText) (Maybe (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalMsg
    = LocalChange (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V49.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V49.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V49.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V49.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V49.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V49.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V49.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V49.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Evergreen.V49.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V49.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (Evergreen.V49.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ThreadMessageId) (Evergreen.V49.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V49.Editable.Model
    , botToken : Evergreen.V49.Editable.Model
    , slackClientSecret : Evergreen.V49.Editable.Model
    , publicVapidKey : Evergreen.V49.Editable.Model
    , privateVapidKey : Evergreen.V49.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V49.Local.Local LocalMsg Evergreen.V49.LocalState.LocalState
    , admin : Maybe Evergreen.V49.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V49.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId, Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId, Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId, Evergreen.V49.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V49.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V49.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V49.Id.GuildOrDmId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V49.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V49.Id.GuildOrDmId (Evergreen.V49.NonemptyDict.NonemptyDict (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Evergreen.V49.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V49.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V49.SecretId.SecretId Evergreen.V49.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V49.NonemptyDict.NonemptyDict Int Evergreen.V49.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V49.NonemptyDict.NonemptyDict Int Evergreen.V49.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V49.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V49.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V49.Ports.NotificationPermission
    , pwaStatus : Evergreen.V49.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V49.AiChat.FrontendModel
    , enabledPushNotifications : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V49.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V49.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V49.NonemptyDict.NonemptyDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V49.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V49.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) Evergreen.V49.LocalState.BackendGuild
    , discordModel : Evergreen.V49.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V49.OneToOne.OneToOne (Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId)
    , discordUsers : Evergreen.V49.OneToOne.OneToOne (Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    , discordBotId : Maybe (Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V49.DmChannel.DmChannelId Evergreen.V49.DmChannel.DmChannel
    , discordDms : Evergreen.V49.OneToOne.OneToOne (Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.ChannelId) Evergreen.V49.DmChannel.DmChannelId
    , slackDms : Evergreen.V49.OneToOne.OneToOne (Evergreen.V49.Slack.Id Evergreen.V49.Slack.ChannelId) Evergreen.V49.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V49.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V49.OneToOne.OneToOne String (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId)
    , slackUsers : Evergreen.V49.OneToOne.OneToOne (Evergreen.V49.Slack.Id Evergreen.V49.Slack.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    , slackServers : Evergreen.V49.OneToOne.OneToOne (Evergreen.V49.Slack.Id Evergreen.V49.Slack.TeamId) (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId)
    , slackToken : Maybe Evergreen.V49.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V49.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V49.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V49.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V49.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V49.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V49.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V49.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V49.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V49.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V49.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V49.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) Evergreen.V49.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) Evergreen.V49.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V49.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V49.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V49.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V49.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V49.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V49.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V49.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V49.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V49.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V49.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V49.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V49.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V49.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V49.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V49.Id.GuildOrDmIdNoThread, Evergreen.V49.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V49.NonemptyDict.NonemptyDict Int Evergreen.V49.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V49.NonemptyDict.NonemptyDict Int Evergreen.V49.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V49.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V49.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V49.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V49.Editable.Msg Evergreen.V49.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V49.Editable.Msg (Maybe Evergreen.V49.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V49.Editable.Msg (Maybe Evergreen.V49.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V49.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V49.Editable.Msg Evergreen.V49.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V49.Id.GuildOrDmId (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V49.FileStatus.FileHash, Maybe (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V49.Id.GuildOrDmId (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V49.Id.GuildOrDmId (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V49.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V49.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V49.Id.GuildOrDmId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V49.FileStatus.FileHash, Maybe (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V49.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V49.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V49.Id.GuildOrDmId (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V49.Id.GuildOrDmIdNoThread Evergreen.V49.Id.ThreadRouteWithMessage Evergreen.V49.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V49.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V49.Id.GuildOrDmIdNoThread, Evergreen.V49.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V49.Id.GuildOrDmIdNoThread, Evergreen.V49.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V49.Id.GuildOrDmIdNoThread, Evergreen.V49.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V49.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V49.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V49.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V49.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.SecretId.SecretId Evergreen.V49.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V49.Id.GuildOrDmIdNoThread, Evergreen.V49.Id.ThreadRoute )) Evergreen.V49.PersonName.PersonName
    | AiChatToBackend Evergreen.V49.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V49.Id.GuildOrDmIdNoThread, Evergreen.V49.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V49.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V49.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V49.EmailAddress.EmailAddress (Result Evergreen.V49.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V49.EmailAddress.EmailAddress (Result Evergreen.V49.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V49.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V49.LocalState.DiscordBotToken (Result Evergreen.V49.Discord.HttpError ( Evergreen.V49.Discord.User, List Evergreen.V49.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.UserId)
        (Result
            Evergreen.V49.Discord.HttpError
            (List
                ( Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.GuildId
                , { guild : Evergreen.V49.Discord.Guild
                  , members : List Evergreen.V49.Discord.GuildMember
                  , channels : List ( Evergreen.V49.Discord.Channel2, List Evergreen.V49.Discord.Message )
                  , icon : Maybe ( Evergreen.V49.FileStatus.FileHash, Maybe (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V49.Discord.Channel, List Evergreen.V49.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) Evergreen.V49.Id.ThreadRouteWithMessage (Result Evergreen.V49.Discord.HttpError Evergreen.V49.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V49.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V49.DmChannel.DmChannelId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) (Result Evergreen.V49.Discord.HttpError Evergreen.V49.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V49.Discord.HttpError (List ( Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.UserId, Maybe ( Evergreen.V49.FileStatus.FileHash, Maybe (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels) ) )))
    | SentNotification Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V49.Slack.CurrentUser
            , team : Evergreen.V49.Slack.Team
            , users : List Evergreen.V49.Slack.User
            , channels : List ( Evergreen.V49.Slack.Channel, List Evergreen.V49.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Result Effect.Http.Error Evergreen.V49.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V49.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V49.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V49.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V49.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
