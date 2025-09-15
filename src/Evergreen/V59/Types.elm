module Evergreen.V59.Types exposing (..)

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
import Evergreen.V59.AiChat
import Evergreen.V59.ChannelName
import Evergreen.V59.Coord
import Evergreen.V59.CssPixels
import Evergreen.V59.Discord
import Evergreen.V59.Discord.Id
import Evergreen.V59.DmChannel
import Evergreen.V59.Editable
import Evergreen.V59.EmailAddress
import Evergreen.V59.Emoji
import Evergreen.V59.FileStatus
import Evergreen.V59.GuildName
import Evergreen.V59.Id
import Evergreen.V59.Local
import Evergreen.V59.LocalState
import Evergreen.V59.Log
import Evergreen.V59.LoginForm
import Evergreen.V59.Message
import Evergreen.V59.MessageInput
import Evergreen.V59.MessageView
import Evergreen.V59.NonemptyDict
import Evergreen.V59.NonemptySet
import Evergreen.V59.OneToOne
import Evergreen.V59.Pages.Admin
import Evergreen.V59.PersonName
import Evergreen.V59.Ports
import Evergreen.V59.Postmark
import Evergreen.V59.RichText
import Evergreen.V59.Route
import Evergreen.V59.SecretId
import Evergreen.V59.Slack
import Evergreen.V59.Touch
import Evergreen.V59.TwoFactorAuthentication
import Evergreen.V59.Ui.Anim
import Evergreen.V59.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V59.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.DmChannel.FrontendDmChannel
    , user : Evergreen.V59.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V59.Route.Route
    , windowSize : Evergreen.V59.Coord.Coord Evergreen.V59.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V59.Ports.NotificationPermission
    , pwaStatus : Evergreen.V59.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    , scrollbarWidth : Int
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V59.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V59.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V59.RichText.RichText) Evergreen.V59.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Evergreen.V59.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) Evergreen.V59.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V59.SecretId.SecretId Evergreen.V59.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V59.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V59.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage Evergreen.V59.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage Evergreen.V59.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V59.RichText.RichText) (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Evergreen.V59.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (Evergreen.V59.Message.Message Evergreen.V59.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ThreadMessageId) (Evergreen.V59.Message.Message Evergreen.V59.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (Evergreen.V59.Message.Message Evergreen.V59.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ThreadMessageId) (Evergreen.V59.Message.Message Evergreen.V59.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V59.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V59.Id.GuildOrDmIdNoThread (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (Evergreen.V59.Message.Message Evergreen.V59.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V59.Id.GuildOrDmIdNoThread (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ThreadMessageId) (Evergreen.V59.Message.Message Evergreen.V59.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.User.NotificationLevel


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId
    , channelId : Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId
    , messageIndex : Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Effect.Time.Posix Evergreen.V59.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V59.RichText.RichText) Evergreen.V59.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Evergreen.V59.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) Evergreen.V59.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.SecretId.SecretId Evergreen.V59.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V59.LocalState.JoinGuildError
            { guildId : Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId
            , guild : Evergreen.V59.LocalState.FrontendGuild
            , owner : Evergreen.V59.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage Evergreen.V59.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage Evergreen.V59.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V59.RichText.RichText) (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Evergreen.V59.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (List.Nonempty.Nonempty Evergreen.V59.RichText.RichText) (Maybe (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.User.NotificationLevel


type LocalMsg
    = LocalChange (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V59.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V59.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V59.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V59.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V59.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V59.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V59.Coord.Coord Evergreen.V59.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V59.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V59.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Evergreen.V59.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V59.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (Evergreen.V59.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ThreadMessageId) (Evergreen.V59.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V59.Editable.Model
    , botToken : Evergreen.V59.Editable.Model
    , slackClientSecret : Evergreen.V59.Editable.Model
    , publicVapidKey : Evergreen.V59.Editable.Model
    , privateVapidKey : Evergreen.V59.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V59.Local.Local LocalMsg Evergreen.V59.LocalState.LocalState
    , admin : Maybe Evergreen.V59.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V59.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId, Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId, Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId, Evergreen.V59.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V59.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V59.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V59.Id.GuildOrDmId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V59.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V59.Id.GuildOrDmId (Evergreen.V59.NonemptyDict.NonemptyDict (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Evergreen.V59.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V59.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V59.SecretId.SecretId Evergreen.V59.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V59.NonemptyDict.NonemptyDict Int Evergreen.V59.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V59.NonemptyDict.NonemptyDict Int Evergreen.V59.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V59.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V59.Coord.Coord Evergreen.V59.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V59.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V59.Ports.NotificationPermission
    , pwaStatus : Evergreen.V59.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V59.AiChat.FrontendModel
    , enabledPushNotifications : Bool
    , scrollbarWidth : Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V59.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V59.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V59.Coord.Coord Evergreen.V59.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V59.NonemptyDict.NonemptyDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V59.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V59.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.LocalState.BackendGuild
    , discordModel : Evergreen.V59.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V59.OneToOne.OneToOne (Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId)
    , discordUsers : Evergreen.V59.OneToOne.OneToOne (Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    , discordBotId : Maybe (Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V59.DmChannel.DmChannelId Evergreen.V59.DmChannel.DmChannel
    , discordDms : Evergreen.V59.OneToOne.OneToOne (Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.ChannelId) Evergreen.V59.DmChannel.DmChannelId
    , slackDms : Evergreen.V59.OneToOne.OneToOne (Evergreen.V59.Slack.Id Evergreen.V59.Slack.ChannelId) Evergreen.V59.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V59.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V59.OneToOne.OneToOne String (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId)
    , slackUsers : Evergreen.V59.OneToOne.OneToOne (Evergreen.V59.Slack.Id Evergreen.V59.Slack.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    , slackServers : Evergreen.V59.OneToOne.OneToOne (Evergreen.V59.Slack.Id Evergreen.V59.Slack.TeamId) (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId)
    , slackToken : Maybe Evergreen.V59.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V59.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V59.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V59.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V59.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V59.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V59.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V59.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V59.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V59.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V59.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V59.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) Evergreen.V59.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) Evergreen.V59.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V59.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V59.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V59.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage (Evergreen.V59.Coord.Coord Evergreen.V59.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V59.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V59.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V59.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V59.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V59.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V59.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V59.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V59.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V59.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V59.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V59.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V59.Id.GuildOrDmIdNoThread, Evergreen.V59.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V59.NonemptyDict.NonemptyDict Int Evergreen.V59.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V59.NonemptyDict.NonemptyDict Int Evergreen.V59.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V59.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V59.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V59.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V59.Editable.Msg Evergreen.V59.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V59.Editable.Msg (Maybe Evergreen.V59.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V59.Editable.Msg (Maybe Evergreen.V59.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V59.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V59.Editable.Msg Evergreen.V59.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V59.Id.GuildOrDmId (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V59.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V59.Id.GuildOrDmId (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V59.Id.GuildOrDmId (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V59.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V59.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V59.Id.GuildOrDmId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V59.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V59.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V59.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V59.Id.GuildOrDmId (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V59.Id.GuildOrDmIdNoThread Evergreen.V59.Id.ThreadRouteWithMessage Evergreen.V59.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V59.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool
    | PressedGuildNotificationLevel (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) Evergreen.V59.User.NotificationLevel
    | GotScrollbarWidth Int


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V59.Id.GuildOrDmIdNoThread, Evergreen.V59.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V59.Id.GuildOrDmIdNoThread, Evergreen.V59.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V59.Id.GuildOrDmIdNoThread, Evergreen.V59.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V59.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V59.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V59.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V59.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.SecretId.SecretId Evergreen.V59.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V59.Id.GuildOrDmIdNoThread, Evergreen.V59.Id.ThreadRoute )) Evergreen.V59.PersonName.PersonName
    | AiChatToBackend Evergreen.V59.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V59.Id.GuildOrDmIdNoThread, Evergreen.V59.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V59.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V59.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V59.EmailAddress.EmailAddress (Result Evergreen.V59.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V59.EmailAddress.EmailAddress (Result Evergreen.V59.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V59.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V59.LocalState.DiscordBotToken (Result Evergreen.V59.Discord.HttpError ( Evergreen.V59.Discord.User, List Evergreen.V59.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.UserId)
        (Result
            Evergreen.V59.Discord.HttpError
            (List
                ( Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.GuildId
                , { guild : Evergreen.V59.Discord.Guild
                  , members : List Evergreen.V59.Discord.GuildMember
                  , channels : List ( Evergreen.V59.Discord.Channel2, List Evergreen.V59.Discord.Message )
                  , icon : Maybe Evergreen.V59.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V59.Discord.Channel, List Evergreen.V59.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) Evergreen.V59.Id.ThreadRouteWithMessage (Result Evergreen.V59.Discord.HttpError Evergreen.V59.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V59.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V59.DmChannel.DmChannelId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) (Result Evergreen.V59.Discord.HttpError Evergreen.V59.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V59.Discord.HttpError (List ( Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.UserId, Maybe Evergreen.V59.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V59.Slack.CurrentUser
            , team : Evergreen.V59.Slack.Team
            , users : List Evergreen.V59.Slack.User
            , channels : List ( Evergreen.V59.Slack.Channel, List Evergreen.V59.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Result Effect.Http.Error Evergreen.V59.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V59.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V59.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V59.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V59.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
