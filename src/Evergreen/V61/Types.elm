module Evergreen.V61.Types exposing (..)

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
import Evergreen.V61.AiChat
import Evergreen.V61.ChannelName
import Evergreen.V61.Coord
import Evergreen.V61.CssPixels
import Evergreen.V61.Discord
import Evergreen.V61.Discord.Id
import Evergreen.V61.DmChannel
import Evergreen.V61.Editable
import Evergreen.V61.EmailAddress
import Evergreen.V61.Emoji
import Evergreen.V61.FileStatus
import Evergreen.V61.GuildName
import Evergreen.V61.Id
import Evergreen.V61.Local
import Evergreen.V61.LocalState
import Evergreen.V61.Log
import Evergreen.V61.LoginForm
import Evergreen.V61.Message
import Evergreen.V61.MessageInput
import Evergreen.V61.MessageView
import Evergreen.V61.NonemptyDict
import Evergreen.V61.NonemptySet
import Evergreen.V61.OneToOne
import Evergreen.V61.Pages.Admin
import Evergreen.V61.PersonName
import Evergreen.V61.Ports
import Evergreen.V61.Postmark
import Evergreen.V61.RichText
import Evergreen.V61.Route
import Evergreen.V61.SecretId
import Evergreen.V61.Slack
import Evergreen.V61.Touch
import Evergreen.V61.TwoFactorAuthentication
import Evergreen.V61.Ui.Anim
import Evergreen.V61.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V61.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.DmChannel.FrontendDmChannel
    , user : Evergreen.V61.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V61.Route.Route
    , windowSize : Evergreen.V61.Coord.Coord Evergreen.V61.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V61.Ports.NotificationPermission
    , pwaStatus : Evergreen.V61.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    , scrollbarWidth : Int
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V61.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V61.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V61.RichText.RichText) Evergreen.V61.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Evergreen.V61.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) Evergreen.V61.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V61.SecretId.SecretId Evergreen.V61.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V61.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V61.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage Evergreen.V61.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage Evergreen.V61.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V61.RichText.RichText) (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Evergreen.V61.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Evergreen.V61.Message.Message Evergreen.V61.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ThreadMessageId) (Evergreen.V61.Message.Message Evergreen.V61.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Evergreen.V61.Message.Message Evergreen.V61.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ThreadMessageId) (Evergreen.V61.Message.Message Evergreen.V61.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V61.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V61.Id.GuildOrDmIdNoThread (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Evergreen.V61.Message.Message Evergreen.V61.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V61.Id.GuildOrDmIdNoThread (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ThreadMessageId) (Evergreen.V61.Message.Message Evergreen.V61.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.User.NotificationLevel


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId
    , channelId : Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId
    , messageIndex : Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Effect.Time.Posix Evergreen.V61.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V61.RichText.RichText) Evergreen.V61.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Evergreen.V61.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) Evergreen.V61.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.SecretId.SecretId Evergreen.V61.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V61.LocalState.JoinGuildError
            { guildId : Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId
            , guild : Evergreen.V61.LocalState.FrontendGuild
            , owner : Evergreen.V61.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage Evergreen.V61.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage Evergreen.V61.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V61.RichText.RichText) (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Evergreen.V61.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (List.Nonempty.Nonempty Evergreen.V61.RichText.RichText) (Maybe (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.User.NotificationLevel


type LocalMsg
    = LocalChange (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V61.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V61.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V61.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V61.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V61.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V61.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V61.Coord.Coord Evergreen.V61.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V61.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V61.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Evergreen.V61.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V61.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Evergreen.V61.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ThreadMessageId) (Evergreen.V61.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V61.Editable.Model
    , botToken : Evergreen.V61.Editable.Model
    , slackClientSecret : Evergreen.V61.Editable.Model
    , publicVapidKey : Evergreen.V61.Editable.Model
    , privateVapidKey : Evergreen.V61.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V61.Local.Local LocalMsg Evergreen.V61.LocalState.LocalState
    , admin : Maybe Evergreen.V61.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V61.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId, Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId, Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId, Evergreen.V61.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V61.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V61.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V61.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.NonemptyDict.NonemptyDict (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Evergreen.V61.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V61.FileStatus.FileDataWithImage
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V61.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V61.SecretId.SecretId Evergreen.V61.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V61.NonemptyDict.NonemptyDict Int Evergreen.V61.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V61.NonemptyDict.NonemptyDict Int Evergreen.V61.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V61.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V61.Coord.Coord Evergreen.V61.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V61.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V61.Ports.NotificationPermission
    , pwaStatus : Evergreen.V61.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V61.AiChat.FrontendModel
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
    , userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V61.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V61.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V61.Coord.Coord Evergreen.V61.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V61.NonemptyDict.NonemptyDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V61.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V61.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.LocalState.BackendGuild
    , discordModel : Evergreen.V61.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V61.OneToOne.OneToOne (Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId)
    , discordUsers : Evergreen.V61.OneToOne.OneToOne (Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    , discordBotId : Maybe (Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V61.DmChannel.DmChannelId Evergreen.V61.DmChannel.DmChannel
    , discordDms : Evergreen.V61.OneToOne.OneToOne (Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.ChannelId) Evergreen.V61.DmChannel.DmChannelId
    , slackDms : Evergreen.V61.OneToOne.OneToOne (Evergreen.V61.Slack.Id Evergreen.V61.Slack.ChannelId) Evergreen.V61.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V61.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V61.OneToOne.OneToOne String (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId)
    , slackUsers : Evergreen.V61.OneToOne.OneToOne (Evergreen.V61.Slack.Id Evergreen.V61.Slack.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    , slackServers : Evergreen.V61.OneToOne.OneToOne (Evergreen.V61.Slack.Id Evergreen.V61.Slack.TeamId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId)
    , slackToken : Maybe Evergreen.V61.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V61.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V61.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V61.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V61.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V61.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V61.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V61.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V61.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V61.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V61.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V61.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) Evergreen.V61.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) Evergreen.V61.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V61.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V61.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V61.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage (Evergreen.V61.Coord.Coord Evergreen.V61.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V61.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V61.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V61.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V61.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V61.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V61.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V61.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V61.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V61.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V61.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V61.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V61.Id.GuildOrDmIdNoThread, Evergreen.V61.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V61.NonemptyDict.NonemptyDict Int Evergreen.V61.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V61.NonemptyDict.NonemptyDict Int Evergreen.V61.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V61.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V61.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V61.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V61.Editable.Msg Evergreen.V61.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V61.Editable.Msg (Maybe Evergreen.V61.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V61.Editable.Msg (Maybe Evergreen.V61.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V61.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V61.Editable.Msg Evergreen.V61.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V61.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V61.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V61.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V61.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V61.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V61.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V61.Id.GuildOrDmId (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V61.Id.GuildOrDmIdNoThread Evergreen.V61.Id.ThreadRouteWithMessage Evergreen.V61.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V61.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool
    | PressedGuildNotificationLevel (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) Evergreen.V61.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V61.Id.GuildOrDmIdNoThread, Evergreen.V61.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V61.Id.GuildOrDmIdNoThread, Evergreen.V61.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V61.Id.GuildOrDmIdNoThread, Evergreen.V61.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V61.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V61.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V61.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V61.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.SecretId.SecretId Evergreen.V61.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V61.Id.GuildOrDmIdNoThread, Evergreen.V61.Id.ThreadRoute )) Evergreen.V61.PersonName.PersonName
    | AiChatToBackend Evergreen.V61.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V61.Id.GuildOrDmIdNoThread, Evergreen.V61.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V61.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V61.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V61.EmailAddress.EmailAddress (Result Evergreen.V61.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V61.EmailAddress.EmailAddress (Result Evergreen.V61.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V61.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V61.LocalState.DiscordBotToken (Result Evergreen.V61.Discord.HttpError ( Evergreen.V61.Discord.User, List Evergreen.V61.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.UserId)
        (Result
            Evergreen.V61.Discord.HttpError
            (List
                ( Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.GuildId
                , { guild : Evergreen.V61.Discord.Guild
                  , members : List Evergreen.V61.Discord.GuildMember
                  , channels : List ( Evergreen.V61.Discord.Channel2, List Evergreen.V61.Discord.Message )
                  , icon : Maybe Evergreen.V61.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V61.Discord.Channel, List Evergreen.V61.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) Evergreen.V61.Id.ThreadRouteWithMessage (Result Evergreen.V61.Discord.HttpError Evergreen.V61.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V61.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V61.DmChannel.DmChannelId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Result Evergreen.V61.Discord.HttpError Evergreen.V61.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V61.Discord.HttpError (List ( Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.UserId, Maybe Evergreen.V61.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V61.Slack.CurrentUser
            , team : Evergreen.V61.Slack.Team
            , users : List Evergreen.V61.Slack.User
            , channels : List ( Evergreen.V61.Slack.Channel, List Evergreen.V61.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Result Effect.Http.Error Evergreen.V61.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V61.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V61.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V61.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V61.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
