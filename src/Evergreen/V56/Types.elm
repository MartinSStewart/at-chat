module Evergreen.V56.Types exposing (..)

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
import Evergreen.V56.AiChat
import Evergreen.V56.ChannelName
import Evergreen.V56.Coord
import Evergreen.V56.CssPixels
import Evergreen.V56.Discord
import Evergreen.V56.Discord.Id
import Evergreen.V56.DmChannel
import Evergreen.V56.Editable
import Evergreen.V56.EmailAddress
import Evergreen.V56.Emoji
import Evergreen.V56.FileStatus
import Evergreen.V56.GuildName
import Evergreen.V56.Id
import Evergreen.V56.Local
import Evergreen.V56.LocalState
import Evergreen.V56.Log
import Evergreen.V56.LoginForm
import Evergreen.V56.Message
import Evergreen.V56.MessageInput
import Evergreen.V56.MessageView
import Evergreen.V56.NonemptyDict
import Evergreen.V56.NonemptySet
import Evergreen.V56.OneToOne
import Evergreen.V56.Pages.Admin
import Evergreen.V56.PersonName
import Evergreen.V56.Ports
import Evergreen.V56.Postmark
import Evergreen.V56.RichText
import Evergreen.V56.Route
import Evergreen.V56.SecretId
import Evergreen.V56.Slack
import Evergreen.V56.Touch
import Evergreen.V56.TwoFactorAuthentication
import Evergreen.V56.Ui.Anim
import Evergreen.V56.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V56.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.DmChannel.FrontendDmChannel
    , user : Evergreen.V56.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V56.Route.Route
    , windowSize : Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V56.Ports.NotificationPermission
    , pwaStatus : Evergreen.V56.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V56.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V56.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V56.RichText.RichText) Evergreen.V56.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Evergreen.V56.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) Evergreen.V56.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V56.SecretId.SecretId Evergreen.V56.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V56.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V56.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage Evergreen.V56.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage Evergreen.V56.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V56.RichText.RichText) (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Evergreen.V56.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (Evergreen.V56.Message.Message Evergreen.V56.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ThreadMessageId) (Evergreen.V56.Message.Message Evergreen.V56.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (Evergreen.V56.Message.Message Evergreen.V56.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ThreadMessageId) (Evergreen.V56.Message.Message Evergreen.V56.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V56.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V56.Id.GuildOrDmIdNoThread (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (Evergreen.V56.Message.Message Evergreen.V56.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V56.Id.GuildOrDmIdNoThread (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ThreadMessageId) (Evergreen.V56.Message.Message Evergreen.V56.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.User.NotificationLevel


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId
    , channelId : Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId
    , messageIndex : Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Effect.Time.Posix Evergreen.V56.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V56.RichText.RichText) Evergreen.V56.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Evergreen.V56.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) Evergreen.V56.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.SecretId.SecretId Evergreen.V56.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V56.LocalState.JoinGuildError
            { guildId : Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId
            , guild : Evergreen.V56.LocalState.FrontendGuild
            , owner : Evergreen.V56.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage Evergreen.V56.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage Evergreen.V56.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V56.RichText.RichText) (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Evergreen.V56.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (List.Nonempty.Nonempty Evergreen.V56.RichText.RichText) (Maybe (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.User.NotificationLevel


type LocalMsg
    = LocalChange (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V56.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V56.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V56.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V56.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V56.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V56.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V56.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V56.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Evergreen.V56.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V56.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (Evergreen.V56.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ThreadMessageId) (Evergreen.V56.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V56.Editable.Model
    , botToken : Evergreen.V56.Editable.Model
    , slackClientSecret : Evergreen.V56.Editable.Model
    , publicVapidKey : Evergreen.V56.Editable.Model
    , privateVapidKey : Evergreen.V56.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V56.Local.Local LocalMsg Evergreen.V56.LocalState.LocalState
    , admin : Maybe Evergreen.V56.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V56.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId, Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId, Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId, Evergreen.V56.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V56.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V56.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V56.Id.GuildOrDmId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V56.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V56.Id.GuildOrDmId (Evergreen.V56.NonemptyDict.NonemptyDict (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Evergreen.V56.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V56.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V56.SecretId.SecretId Evergreen.V56.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V56.NonemptyDict.NonemptyDict Int Evergreen.V56.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V56.NonemptyDict.NonemptyDict Int Evergreen.V56.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V56.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V56.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V56.Ports.NotificationPermission
    , pwaStatus : Evergreen.V56.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V56.AiChat.FrontendModel
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
    , userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V56.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V56.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V56.NonemptyDict.NonemptyDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V56.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V56.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.LocalState.BackendGuild
    , discordModel : Evergreen.V56.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V56.OneToOne.OneToOne (Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId)
    , discordUsers : Evergreen.V56.OneToOne.OneToOne (Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    , discordBotId : Maybe (Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V56.DmChannel.DmChannelId Evergreen.V56.DmChannel.DmChannel
    , discordDms : Evergreen.V56.OneToOne.OneToOne (Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.ChannelId) Evergreen.V56.DmChannel.DmChannelId
    , slackDms : Evergreen.V56.OneToOne.OneToOne (Evergreen.V56.Slack.Id Evergreen.V56.Slack.ChannelId) Evergreen.V56.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V56.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V56.OneToOne.OneToOne String (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId)
    , slackUsers : Evergreen.V56.OneToOne.OneToOne (Evergreen.V56.Slack.Id Evergreen.V56.Slack.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    , slackServers : Evergreen.V56.OneToOne.OneToOne (Evergreen.V56.Slack.Id Evergreen.V56.Slack.TeamId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId)
    , slackToken : Maybe Evergreen.V56.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V56.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V56.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V56.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V56.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V56.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V56.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V56.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V56.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V56.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V56.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V56.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) Evergreen.V56.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) Evergreen.V56.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V56.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V56.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V56.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage (Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V56.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V56.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V56.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V56.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V56.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V56.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V56.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V56.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V56.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V56.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V56.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V56.Id.GuildOrDmIdNoThread, Evergreen.V56.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V56.NonemptyDict.NonemptyDict Int Evergreen.V56.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V56.NonemptyDict.NonemptyDict Int Evergreen.V56.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V56.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V56.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V56.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V56.Editable.Msg Evergreen.V56.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V56.Editable.Msg (Maybe Evergreen.V56.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V56.Editable.Msg (Maybe Evergreen.V56.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V56.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V56.Editable.Msg Evergreen.V56.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V56.Id.GuildOrDmId (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V56.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V56.Id.GuildOrDmId (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V56.Id.GuildOrDmId (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V56.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V56.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V56.Id.GuildOrDmId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V56.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V56.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V56.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V56.Id.GuildOrDmId (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V56.Id.GuildOrDmIdNoThread Evergreen.V56.Id.ThreadRouteWithMessage Evergreen.V56.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V56.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool
    | PressedGuildNotificationLevel (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) Evergreen.V56.User.NotificationLevel


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V56.Id.GuildOrDmIdNoThread, Evergreen.V56.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V56.Id.GuildOrDmIdNoThread, Evergreen.V56.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V56.Id.GuildOrDmIdNoThread, Evergreen.V56.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V56.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V56.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V56.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V56.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.SecretId.SecretId Evergreen.V56.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V56.Id.GuildOrDmIdNoThread, Evergreen.V56.Id.ThreadRoute )) Evergreen.V56.PersonName.PersonName
    | AiChatToBackend Evergreen.V56.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V56.Id.GuildOrDmIdNoThread, Evergreen.V56.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V56.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V56.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V56.EmailAddress.EmailAddress (Result Evergreen.V56.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V56.EmailAddress.EmailAddress (Result Evergreen.V56.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V56.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V56.LocalState.DiscordBotToken (Result Evergreen.V56.Discord.HttpError ( Evergreen.V56.Discord.User, List Evergreen.V56.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.UserId)
        (Result
            Evergreen.V56.Discord.HttpError
            (List
                ( Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.GuildId
                , { guild : Evergreen.V56.Discord.Guild
                  , members : List Evergreen.V56.Discord.GuildMember
                  , channels : List ( Evergreen.V56.Discord.Channel2, List Evergreen.V56.Discord.Message )
                  , icon : Maybe Evergreen.V56.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V56.Discord.Channel, List Evergreen.V56.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) Evergreen.V56.Id.ThreadRouteWithMessage (Result Evergreen.V56.Discord.HttpError Evergreen.V56.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V56.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V56.DmChannel.DmChannelId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) (Result Evergreen.V56.Discord.HttpError Evergreen.V56.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V56.Discord.HttpError (List ( Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.UserId, Maybe Evergreen.V56.FileStatus.UploadResponse )))
    | SentNotification Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V56.Slack.CurrentUser
            , team : Evergreen.V56.Slack.Team
            , users : List Evergreen.V56.Slack.User
            , channels : List ( Evergreen.V56.Slack.Channel, List Evergreen.V56.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Result Effect.Http.Error Evergreen.V56.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V56.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V56.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V56.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V56.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
