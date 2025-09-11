module Evergreen.V53.Types exposing (..)

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
import Evergreen.V53.AiChat
import Evergreen.V53.ChannelName
import Evergreen.V53.Coord
import Evergreen.V53.CssPixels
import Evergreen.V53.Discord
import Evergreen.V53.Discord.Id
import Evergreen.V53.DmChannel
import Evergreen.V53.Editable
import Evergreen.V53.EmailAddress
import Evergreen.V53.Emoji
import Evergreen.V53.FileStatus
import Evergreen.V53.GuildName
import Evergreen.V53.Id
import Evergreen.V53.Local
import Evergreen.V53.LocalState
import Evergreen.V53.Log
import Evergreen.V53.LoginForm
import Evergreen.V53.Message
import Evergreen.V53.MessageInput
import Evergreen.V53.MessageView
import Evergreen.V53.NonemptyDict
import Evergreen.V53.NonemptySet
import Evergreen.V53.OneToOne
import Evergreen.V53.Pages.Admin
import Evergreen.V53.PersonName
import Evergreen.V53.Ports
import Evergreen.V53.Postmark
import Evergreen.V53.RichText
import Evergreen.V53.Route
import Evergreen.V53.SecretId
import Evergreen.V53.Slack
import Evergreen.V53.Touch
import Evergreen.V53.TwoFactorAuthentication
import Evergreen.V53.Ui.Anim
import Evergreen.V53.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V53.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.DmChannel.FrontendDmChannel
    , user : Evergreen.V53.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V53.Route.Route
    , windowSize : Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V53.Ports.NotificationPermission
    , pwaStatus : Evergreen.V53.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V53.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V53.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V53.RichText.RichText) Evergreen.V53.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Evergreen.V53.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) Evergreen.V53.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V53.SecretId.SecretId Evergreen.V53.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V53.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V53.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage Evergreen.V53.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage Evergreen.V53.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V53.RichText.RichText) (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Evergreen.V53.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (Evergreen.V53.Message.Message Evergreen.V53.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ThreadMessageId) (Evergreen.V53.Message.Message Evergreen.V53.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (Evergreen.V53.Message.Message Evergreen.V53.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ThreadMessageId) (Evergreen.V53.Message.Message Evergreen.V53.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V53.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V53.Id.GuildOrDmIdNoThread (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (Evergreen.V53.Message.Message Evergreen.V53.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V53.Id.GuildOrDmIdNoThread (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ThreadMessageId) (Evergreen.V53.Message.Message Evergreen.V53.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.User.NotificationLevel


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId
    , channelId : Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId
    , messageIndex : Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Effect.Time.Posix Evergreen.V53.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V53.RichText.RichText) Evergreen.V53.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Evergreen.V53.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) Evergreen.V53.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.SecretId.SecretId Evergreen.V53.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V53.LocalState.JoinGuildError
            { guildId : Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId
            , guild : Evergreen.V53.LocalState.FrontendGuild
            , owner : Evergreen.V53.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage Evergreen.V53.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage Evergreen.V53.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V53.RichText.RichText) (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Evergreen.V53.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (List.Nonempty.Nonempty Evergreen.V53.RichText.RichText) (Maybe (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetNotifyOnAllChanges (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.User.NotificationLevel


type LocalMsg
    = LocalChange (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V53.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V53.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V53.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V53.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V53.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V53.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V53.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V53.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Evergreen.V53.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V53.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (Evergreen.V53.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ThreadMessageId) (Evergreen.V53.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V53.Editable.Model
    , botToken : Evergreen.V53.Editable.Model
    , slackClientSecret : Evergreen.V53.Editable.Model
    , publicVapidKey : Evergreen.V53.Editable.Model
    , privateVapidKey : Evergreen.V53.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V53.Local.Local LocalMsg Evergreen.V53.LocalState.LocalState
    , admin : Maybe Evergreen.V53.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V53.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId, Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId, Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId, Evergreen.V53.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V53.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V53.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V53.Id.GuildOrDmId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V53.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V53.Id.GuildOrDmId (Evergreen.V53.NonemptyDict.NonemptyDict (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Evergreen.V53.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V53.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V53.SecretId.SecretId Evergreen.V53.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V53.NonemptyDict.NonemptyDict Int Evergreen.V53.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V53.NonemptyDict.NonemptyDict Int Evergreen.V53.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V53.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V53.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V53.Ports.NotificationPermission
    , pwaStatus : Evergreen.V53.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V53.AiChat.FrontendModel
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
    , userId : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V53.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V53.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V53.NonemptyDict.NonemptyDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V53.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V53.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.LocalState.BackendGuild
    , discordModel : Evergreen.V53.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V53.OneToOne.OneToOne (Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId)
    , discordUsers : Evergreen.V53.OneToOne.OneToOne (Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.UserId) (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    , discordBotId : Maybe (Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V53.DmChannel.DmChannelId Evergreen.V53.DmChannel.DmChannel
    , discordDms : Evergreen.V53.OneToOne.OneToOne (Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.ChannelId) Evergreen.V53.DmChannel.DmChannelId
    , slackDms : Evergreen.V53.OneToOne.OneToOne (Evergreen.V53.Slack.Id Evergreen.V53.Slack.ChannelId) Evergreen.V53.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V53.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V53.OneToOne.OneToOne String (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId)
    , slackUsers : Evergreen.V53.OneToOne.OneToOne (Evergreen.V53.Slack.Id Evergreen.V53.Slack.UserId) (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    , slackServers : Evergreen.V53.OneToOne.OneToOne (Evergreen.V53.Slack.Id Evergreen.V53.Slack.TeamId) (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId)
    , slackToken : Maybe Evergreen.V53.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V53.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V53.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V53.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V53.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V53.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V53.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V53.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V53.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V53.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V53.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V53.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) Evergreen.V53.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) Evergreen.V53.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V53.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V53.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V53.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V53.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V53.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V53.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V53.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V53.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V53.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V53.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V53.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V53.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V53.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V53.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V53.Id.GuildOrDmIdNoThread, Evergreen.V53.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V53.NonemptyDict.NonemptyDict Int Evergreen.V53.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V53.NonemptyDict.NonemptyDict Int Evergreen.V53.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V53.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V53.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V53.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V53.Editable.Msg Evergreen.V53.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V53.Editable.Msg (Maybe Evergreen.V53.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V53.Editable.Msg (Maybe Evergreen.V53.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V53.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V53.Editable.Msg Evergreen.V53.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V53.Id.GuildOrDmId (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V53.FileStatus.FileHash, Maybe (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V53.Id.GuildOrDmId (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V53.Id.GuildOrDmId (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V53.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V53.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V53.Id.GuildOrDmId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V53.FileStatus.FileHash, Maybe (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V53.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V53.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V53.Id.GuildOrDmId (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V53.Id.GuildOrDmIdNoThread Evergreen.V53.Id.ThreadRouteWithMessage Evergreen.V53.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V53.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool
    | PressedGuildNotificationLevel (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) Evergreen.V53.User.NotificationLevel


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V53.Id.GuildOrDmIdNoThread, Evergreen.V53.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V53.Id.GuildOrDmIdNoThread, Evergreen.V53.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V53.Id.GuildOrDmIdNoThread, Evergreen.V53.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V53.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V53.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V53.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V53.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.SecretId.SecretId Evergreen.V53.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V53.Id.GuildOrDmIdNoThread, Evergreen.V53.Id.ThreadRoute )) Evergreen.V53.PersonName.PersonName
    | AiChatToBackend Evergreen.V53.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V53.Id.GuildOrDmIdNoThread, Evergreen.V53.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V53.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V53.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V53.EmailAddress.EmailAddress (Result Evergreen.V53.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V53.EmailAddress.EmailAddress (Result Evergreen.V53.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V53.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V53.LocalState.DiscordBotToken (Result Evergreen.V53.Discord.HttpError ( Evergreen.V53.Discord.User, List Evergreen.V53.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.UserId)
        (Result
            Evergreen.V53.Discord.HttpError
            (List
                ( Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.GuildId
                , { guild : Evergreen.V53.Discord.Guild
                  , members : List Evergreen.V53.Discord.GuildMember
                  , channels : List ( Evergreen.V53.Discord.Channel2, List Evergreen.V53.Discord.Message )
                  , icon : Maybe ( Evergreen.V53.FileStatus.FileHash, Maybe (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V53.Discord.Channel, List Evergreen.V53.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) Evergreen.V53.Id.ThreadRouteWithMessage (Result Evergreen.V53.Discord.HttpError Evergreen.V53.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V53.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V53.DmChannel.DmChannelId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) (Result Evergreen.V53.Discord.HttpError Evergreen.V53.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V53.Discord.HttpError (List ( Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.UserId, Maybe ( Evergreen.V53.FileStatus.FileHash, Maybe (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels) ) )))
    | SentNotification Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V53.Slack.CurrentUser
            , team : Evergreen.V53.Slack.Team
            , users : List Evergreen.V53.Slack.User
            , channels : List ( Evergreen.V53.Slack.Channel, List Evergreen.V53.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (Result Effect.Http.Error Evergreen.V53.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V53.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V53.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V53.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V53.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
