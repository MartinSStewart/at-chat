module Evergreen.V54.Types exposing (..)

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
import Evergreen.V54.AiChat
import Evergreen.V54.ChannelName
import Evergreen.V54.Coord
import Evergreen.V54.CssPixels
import Evergreen.V54.Discord
import Evergreen.V54.Discord.Id
import Evergreen.V54.DmChannel
import Evergreen.V54.Editable
import Evergreen.V54.EmailAddress
import Evergreen.V54.Emoji
import Evergreen.V54.FileStatus
import Evergreen.V54.GuildName
import Evergreen.V54.Id
import Evergreen.V54.Local
import Evergreen.V54.LocalState
import Evergreen.V54.Log
import Evergreen.V54.LoginForm
import Evergreen.V54.Message
import Evergreen.V54.MessageInput
import Evergreen.V54.MessageView
import Evergreen.V54.NonemptyDict
import Evergreen.V54.NonemptySet
import Evergreen.V54.OneToOne
import Evergreen.V54.Pages.Admin
import Evergreen.V54.PersonName
import Evergreen.V54.Ports
import Evergreen.V54.Postmark
import Evergreen.V54.RichText
import Evergreen.V54.Route
import Evergreen.V54.SecretId
import Evergreen.V54.Slack
import Evergreen.V54.Touch
import Evergreen.V54.TwoFactorAuthentication
import Evergreen.V54.Ui.Anim
import Evergreen.V54.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V54.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.DmChannel.FrontendDmChannel
    , user : Evergreen.V54.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V54.Route.Route
    , windowSize : Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V54.Ports.NotificationPermission
    , pwaStatus : Evergreen.V54.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V54.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V54.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V54.RichText.RichText) Evergreen.V54.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Evergreen.V54.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) Evergreen.V54.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V54.SecretId.SecretId Evergreen.V54.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V54.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V54.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage Evergreen.V54.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage Evergreen.V54.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V54.RichText.RichText) (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Evergreen.V54.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (Evergreen.V54.Message.Message Evergreen.V54.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ThreadMessageId) (Evergreen.V54.Message.Message Evergreen.V54.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (Evergreen.V54.Message.Message Evergreen.V54.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ThreadMessageId) (Evergreen.V54.Message.Message Evergreen.V54.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V54.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V54.Id.GuildOrDmIdNoThread (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (Evergreen.V54.Message.Message Evergreen.V54.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V54.Id.GuildOrDmIdNoThread (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ThreadMessageId) (Evergreen.V54.Message.Message Evergreen.V54.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.User.NotificationLevel


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId
    , channelId : Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId
    , messageIndex : Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Effect.Time.Posix Evergreen.V54.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V54.RichText.RichText) Evergreen.V54.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Evergreen.V54.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) Evergreen.V54.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.SecretId.SecretId Evergreen.V54.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V54.LocalState.JoinGuildError
            { guildId : Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId
            , guild : Evergreen.V54.LocalState.FrontendGuild
            , owner : Evergreen.V54.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage Evergreen.V54.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage Evergreen.V54.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V54.RichText.RichText) (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Evergreen.V54.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (List.Nonempty.Nonempty Evergreen.V54.RichText.RichText) (Maybe (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.User.NotificationLevel


type LocalMsg
    = LocalChange (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V54.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V54.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V54.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V54.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V54.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V54.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V54.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V54.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Evergreen.V54.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V54.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (Evergreen.V54.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ThreadMessageId) (Evergreen.V54.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V54.Editable.Model
    , botToken : Evergreen.V54.Editable.Model
    , slackClientSecret : Evergreen.V54.Editable.Model
    , publicVapidKey : Evergreen.V54.Editable.Model
    , privateVapidKey : Evergreen.V54.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V54.Local.Local LocalMsg Evergreen.V54.LocalState.LocalState
    , admin : Maybe Evergreen.V54.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V54.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId, Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId, Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId, Evergreen.V54.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V54.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V54.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V54.Id.GuildOrDmId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V54.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V54.Id.GuildOrDmId (Evergreen.V54.NonemptyDict.NonemptyDict (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Evergreen.V54.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V54.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V54.SecretId.SecretId Evergreen.V54.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V54.NonemptyDict.NonemptyDict Int Evergreen.V54.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V54.NonemptyDict.NonemptyDict Int Evergreen.V54.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V54.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V54.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V54.Ports.NotificationPermission
    , pwaStatus : Evergreen.V54.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V54.AiChat.FrontendModel
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
    , userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V54.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V54.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V54.NonemptyDict.NonemptyDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V54.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V54.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.LocalState.BackendGuild
    , discordModel : Evergreen.V54.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V54.OneToOne.OneToOne (Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId)
    , discordUsers : Evergreen.V54.OneToOne.OneToOne (Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    , discordBotId : Maybe (Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V54.DmChannel.DmChannelId Evergreen.V54.DmChannel.DmChannel
    , discordDms : Evergreen.V54.OneToOne.OneToOne (Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.ChannelId) Evergreen.V54.DmChannel.DmChannelId
    , slackDms : Evergreen.V54.OneToOne.OneToOne (Evergreen.V54.Slack.Id Evergreen.V54.Slack.ChannelId) Evergreen.V54.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V54.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V54.OneToOne.OneToOne String (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId)
    , slackUsers : Evergreen.V54.OneToOne.OneToOne (Evergreen.V54.Slack.Id Evergreen.V54.Slack.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    , slackServers : Evergreen.V54.OneToOne.OneToOne (Evergreen.V54.Slack.Id Evergreen.V54.Slack.TeamId) (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId)
    , slackToken : Maybe Evergreen.V54.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V54.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V54.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V54.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V54.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V54.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V54.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V54.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V54.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V54.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V54.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V54.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) Evergreen.V54.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) Evergreen.V54.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V54.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V54.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V54.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V54.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V54.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V54.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V54.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V54.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V54.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V54.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V54.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V54.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V54.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V54.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V54.Id.GuildOrDmIdNoThread, Evergreen.V54.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V54.NonemptyDict.NonemptyDict Int Evergreen.V54.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V54.NonemptyDict.NonemptyDict Int Evergreen.V54.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V54.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V54.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V54.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V54.Editable.Msg Evergreen.V54.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V54.Editable.Msg (Maybe Evergreen.V54.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V54.Editable.Msg (Maybe Evergreen.V54.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V54.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V54.Editable.Msg Evergreen.V54.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V54.Id.GuildOrDmId (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V54.FileStatus.FileHash, Maybe (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V54.Id.GuildOrDmId (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V54.Id.GuildOrDmId (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V54.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V54.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V54.Id.GuildOrDmId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V54.FileStatus.FileHash, Maybe (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V54.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V54.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V54.Id.GuildOrDmId (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V54.Id.GuildOrDmIdNoThread Evergreen.V54.Id.ThreadRouteWithMessage Evergreen.V54.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V54.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool
    | PressedGuildNotificationLevel (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) Evergreen.V54.User.NotificationLevel


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V54.Id.GuildOrDmIdNoThread, Evergreen.V54.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V54.Id.GuildOrDmIdNoThread, Evergreen.V54.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V54.Id.GuildOrDmIdNoThread, Evergreen.V54.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V54.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V54.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V54.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V54.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.SecretId.SecretId Evergreen.V54.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V54.Id.GuildOrDmIdNoThread, Evergreen.V54.Id.ThreadRoute )) Evergreen.V54.PersonName.PersonName
    | AiChatToBackend Evergreen.V54.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V54.Id.GuildOrDmIdNoThread, Evergreen.V54.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V54.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V54.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V54.EmailAddress.EmailAddress (Result Evergreen.V54.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V54.EmailAddress.EmailAddress (Result Evergreen.V54.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V54.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V54.LocalState.DiscordBotToken (Result Evergreen.V54.Discord.HttpError ( Evergreen.V54.Discord.User, List Evergreen.V54.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.UserId)
        (Result
            Evergreen.V54.Discord.HttpError
            (List
                ( Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.GuildId
                , { guild : Evergreen.V54.Discord.Guild
                  , members : List Evergreen.V54.Discord.GuildMember
                  , channels : List ( Evergreen.V54.Discord.Channel2, List Evergreen.V54.Discord.Message )
                  , icon : Maybe ( Evergreen.V54.FileStatus.FileHash, Maybe (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V54.Discord.Channel, List Evergreen.V54.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) Evergreen.V54.Id.ThreadRouteWithMessage (Result Evergreen.V54.Discord.HttpError Evergreen.V54.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V54.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V54.DmChannel.DmChannelId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) (Result Evergreen.V54.Discord.HttpError Evergreen.V54.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V54.Discord.HttpError (List ( Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.UserId, Maybe ( Evergreen.V54.FileStatus.FileHash, Maybe (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels) ) )))
    | SentNotification Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V54.Slack.CurrentUser
            , team : Evergreen.V54.Slack.Team
            , users : List Evergreen.V54.Slack.User
            , channels : List ( Evergreen.V54.Slack.Channel, List Evergreen.V54.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Result Effect.Http.Error Evergreen.V54.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V54.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V54.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V54.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V54.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
