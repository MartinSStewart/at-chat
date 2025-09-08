module Evergreen.V52.Types exposing (..)

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
import Evergreen.V52.AiChat
import Evergreen.V52.ChannelName
import Evergreen.V52.Coord
import Evergreen.V52.CssPixels
import Evergreen.V52.Discord
import Evergreen.V52.Discord.Id
import Evergreen.V52.DmChannel
import Evergreen.V52.Editable
import Evergreen.V52.EmailAddress
import Evergreen.V52.Emoji
import Evergreen.V52.FileStatus
import Evergreen.V52.GuildName
import Evergreen.V52.Id
import Evergreen.V52.Local
import Evergreen.V52.LocalState
import Evergreen.V52.Log
import Evergreen.V52.LoginForm
import Evergreen.V52.Message
import Evergreen.V52.MessageInput
import Evergreen.V52.MessageView
import Evergreen.V52.NonemptyDict
import Evergreen.V52.NonemptySet
import Evergreen.V52.OneToOne
import Evergreen.V52.Pages.Admin
import Evergreen.V52.PersonName
import Evergreen.V52.Ports
import Evergreen.V52.Postmark
import Evergreen.V52.RichText
import Evergreen.V52.Route
import Evergreen.V52.SecretId
import Evergreen.V52.Slack
import Evergreen.V52.Touch
import Evergreen.V52.TwoFactorAuthentication
import Evergreen.V52.Ui.Anim
import Evergreen.V52.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V52.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) Evergreen.V52.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.DmChannel.FrontendDmChannel
    , user : Evergreen.V52.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V52.Route.Route
    , windowSize : Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V52.Ports.NotificationPermission
    , pwaStatus : Evergreen.V52.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V52.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V52.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V52.RichText.RichText) Evergreen.V52.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Evergreen.V52.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) Evergreen.V52.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) Evergreen.V52.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V52.SecretId.SecretId Evergreen.V52.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V52.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V52.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage Evergreen.V52.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage Evergreen.V52.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V52.RichText.RichText) (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Evergreen.V52.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (Evergreen.V52.Message.Message Evergreen.V52.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ThreadMessageId) (Evergreen.V52.Message.Message Evergreen.V52.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (Evergreen.V52.Message.Message Evergreen.V52.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ThreadMessageId) (Evergreen.V52.Message.Message Evergreen.V52.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V52.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V52.Id.GuildOrDmIdNoThread (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (Evergreen.V52.Message.Message Evergreen.V52.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V52.Id.GuildOrDmIdNoThread (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ThreadMessageId) (Evergreen.V52.Message.Message Evergreen.V52.Id.ThreadMessageId)))
    | Local_SetNotifyOnAllChanges (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) Bool


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId
    , channelId : Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId
    , messageIndex : Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Effect.Time.Posix Evergreen.V52.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V52.RichText.RichText) Evergreen.V52.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Evergreen.V52.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) Evergreen.V52.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) Evergreen.V52.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.SecretId.SecretId Evergreen.V52.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) Evergreen.V52.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V52.LocalState.JoinGuildError
            { guildId : Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId
            , guild : Evergreen.V52.LocalState.FrontendGuild
            , owner : Evergreen.V52.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage Evergreen.V52.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage Evergreen.V52.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V52.RichText.RichText) (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Evergreen.V52.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (List.Nonempty.Nonempty Evergreen.V52.RichText.RichText) (Maybe (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetNotifyOnAllChanges (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) Bool


type LocalMsg
    = LocalChange (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V52.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V52.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V52.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V52.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V52.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V52.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V52.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V52.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Evergreen.V52.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V52.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (Evergreen.V52.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ThreadMessageId) (Evergreen.V52.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V52.Editable.Model
    , botToken : Evergreen.V52.Editable.Model
    , slackClientSecret : Evergreen.V52.Editable.Model
    , publicVapidKey : Evergreen.V52.Editable.Model
    , privateVapidKey : Evergreen.V52.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V52.Local.Local LocalMsg Evergreen.V52.LocalState.LocalState
    , admin : Maybe Evergreen.V52.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V52.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId, Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId, Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId, Evergreen.V52.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V52.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V52.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V52.Id.GuildOrDmId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V52.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V52.Id.GuildOrDmId (Evergreen.V52.NonemptyDict.NonemptyDict (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Evergreen.V52.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V52.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V52.SecretId.SecretId Evergreen.V52.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V52.NonemptyDict.NonemptyDict Int Evergreen.V52.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V52.NonemptyDict.NonemptyDict Int Evergreen.V52.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V52.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V52.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V52.Ports.NotificationPermission
    , pwaStatus : Evergreen.V52.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V52.AiChat.FrontendModel
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
    , userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V52.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V52.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V52.NonemptyDict.NonemptyDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V52.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V52.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) Evergreen.V52.LocalState.BackendGuild
    , discordModel : Evergreen.V52.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V52.OneToOne.OneToOne (Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId)
    , discordUsers : Evergreen.V52.OneToOne.OneToOne (Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    , discordBotId : Maybe (Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V52.DmChannel.DmChannelId Evergreen.V52.DmChannel.DmChannel
    , discordDms : Evergreen.V52.OneToOne.OneToOne (Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.ChannelId) Evergreen.V52.DmChannel.DmChannelId
    , slackDms : Evergreen.V52.OneToOne.OneToOne (Evergreen.V52.Slack.Id Evergreen.V52.Slack.ChannelId) Evergreen.V52.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V52.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V52.OneToOne.OneToOne String (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId)
    , slackUsers : Evergreen.V52.OneToOne.OneToOne (Evergreen.V52.Slack.Id Evergreen.V52.Slack.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    , slackServers : Evergreen.V52.OneToOne.OneToOne (Evergreen.V52.Slack.Id Evergreen.V52.Slack.TeamId) (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId)
    , slackToken : Maybe Evergreen.V52.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V52.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V52.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V52.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V52.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V52.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V52.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V52.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V52.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V52.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V52.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V52.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) Evergreen.V52.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) Evergreen.V52.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V52.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V52.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V52.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V52.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V52.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V52.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V52.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V52.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V52.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V52.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V52.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V52.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V52.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V52.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V52.Id.GuildOrDmIdNoThread, Evergreen.V52.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V52.NonemptyDict.NonemptyDict Int Evergreen.V52.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V52.NonemptyDict.NonemptyDict Int Evergreen.V52.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V52.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V52.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V52.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V52.Editable.Msg Evergreen.V52.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V52.Editable.Msg (Maybe Evergreen.V52.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V52.Editable.Msg (Maybe Evergreen.V52.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V52.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V52.Editable.Msg Evergreen.V52.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V52.Id.GuildOrDmId (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V52.FileStatus.FileHash, Maybe (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V52.Id.GuildOrDmId (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V52.Id.GuildOrDmId (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V52.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V52.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V52.Id.GuildOrDmId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V52.FileStatus.FileHash, Maybe (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V52.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V52.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V52.Id.GuildOrDmId (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V52.Id.GuildOrDmIdNoThread Evergreen.V52.Id.ThreadRouteWithMessage Evergreen.V52.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V52.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V52.Id.GuildOrDmIdNoThread, Evergreen.V52.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V52.Id.GuildOrDmIdNoThread, Evergreen.V52.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V52.Id.GuildOrDmIdNoThread, Evergreen.V52.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V52.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V52.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V52.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V52.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.SecretId.SecretId Evergreen.V52.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V52.Id.GuildOrDmIdNoThread, Evergreen.V52.Id.ThreadRoute )) Evergreen.V52.PersonName.PersonName
    | AiChatToBackend Evergreen.V52.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V52.Id.GuildOrDmIdNoThread, Evergreen.V52.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V52.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V52.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V52.EmailAddress.EmailAddress (Result Evergreen.V52.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V52.EmailAddress.EmailAddress (Result Evergreen.V52.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V52.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V52.LocalState.DiscordBotToken (Result Evergreen.V52.Discord.HttpError ( Evergreen.V52.Discord.User, List Evergreen.V52.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.UserId)
        (Result
            Evergreen.V52.Discord.HttpError
            (List
                ( Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.GuildId
                , { guild : Evergreen.V52.Discord.Guild
                  , members : List Evergreen.V52.Discord.GuildMember
                  , channels : List ( Evergreen.V52.Discord.Channel2, List Evergreen.V52.Discord.Message )
                  , icon : Maybe ( Evergreen.V52.FileStatus.FileHash, Maybe (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V52.Discord.Channel, List Evergreen.V52.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) Evergreen.V52.Id.ThreadRouteWithMessage (Result Evergreen.V52.Discord.HttpError Evergreen.V52.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V52.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V52.DmChannel.DmChannelId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) (Result Evergreen.V52.Discord.HttpError Evergreen.V52.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V52.Discord.HttpError (List ( Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.UserId, Maybe ( Evergreen.V52.FileStatus.FileHash, Maybe (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels) ) )))
    | SentNotification Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V52.Slack.CurrentUser
            , team : Evergreen.V52.Slack.Team
            , users : List Evergreen.V52.Slack.User
            , channels : List ( Evergreen.V52.Slack.Channel, List Evergreen.V52.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Result Effect.Http.Error Evergreen.V52.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V52.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V52.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V52.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V52.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
