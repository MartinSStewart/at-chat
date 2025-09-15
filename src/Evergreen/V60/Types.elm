module Evergreen.V60.Types exposing (..)

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
import Evergreen.V60.AiChat
import Evergreen.V60.ChannelName
import Evergreen.V60.Coord
import Evergreen.V60.CssPixels
import Evergreen.V60.Discord
import Evergreen.V60.Discord.Id
import Evergreen.V60.DmChannel
import Evergreen.V60.Editable
import Evergreen.V60.EmailAddress
import Evergreen.V60.Emoji
import Evergreen.V60.FileStatus
import Evergreen.V60.GuildName
import Evergreen.V60.Id
import Evergreen.V60.Local
import Evergreen.V60.LocalState
import Evergreen.V60.Log
import Evergreen.V60.LoginForm
import Evergreen.V60.Message
import Evergreen.V60.MessageInput
import Evergreen.V60.MessageView
import Evergreen.V60.NonemptyDict
import Evergreen.V60.NonemptySet
import Evergreen.V60.OneToOne
import Evergreen.V60.Pages.Admin
import Evergreen.V60.PersonName
import Evergreen.V60.Ports
import Evergreen.V60.Postmark
import Evergreen.V60.RichText
import Evergreen.V60.Route
import Evergreen.V60.SecretId
import Evergreen.V60.Slack
import Evergreen.V60.Touch
import Evergreen.V60.TwoFactorAuthentication
import Evergreen.V60.Ui.Anim
import Evergreen.V60.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V60.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.DmChannel.FrontendDmChannel
    , user : Evergreen.V60.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V60.Route.Route
    , windowSize : Evergreen.V60.Coord.Coord Evergreen.V60.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V60.Ports.NotificationPermission
    , pwaStatus : Evergreen.V60.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    , scrollbarWidth : Int
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V60.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V60.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V60.RichText.RichText) Evergreen.V60.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Evergreen.V60.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) Evergreen.V60.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V60.SecretId.SecretId Evergreen.V60.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V60.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V60.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage Evergreen.V60.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage Evergreen.V60.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V60.RichText.RichText) (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Evergreen.V60.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (Evergreen.V60.Message.Message Evergreen.V60.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ThreadMessageId) (Evergreen.V60.Message.Message Evergreen.V60.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (Evergreen.V60.Message.Message Evergreen.V60.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ThreadMessageId) (Evergreen.V60.Message.Message Evergreen.V60.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V60.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V60.Id.GuildOrDmIdNoThread (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (Evergreen.V60.Message.Message Evergreen.V60.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V60.Id.GuildOrDmIdNoThread (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ThreadMessageId) (Evergreen.V60.Message.Message Evergreen.V60.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.User.NotificationLevel


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId
    , channelId : Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId
    , messageIndex : Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Effect.Time.Posix Evergreen.V60.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V60.RichText.RichText) Evergreen.V60.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Evergreen.V60.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) Evergreen.V60.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.SecretId.SecretId Evergreen.V60.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V60.LocalState.JoinGuildError
            { guildId : Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId
            , guild : Evergreen.V60.LocalState.FrontendGuild
            , owner : Evergreen.V60.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage Evergreen.V60.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage Evergreen.V60.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V60.RichText.RichText) (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Evergreen.V60.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (List.Nonempty.Nonempty Evergreen.V60.RichText.RichText) (Maybe (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.User.NotificationLevel


type LocalMsg
    = LocalChange (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V60.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V60.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V60.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V60.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V60.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V60.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V60.Coord.Coord Evergreen.V60.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V60.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V60.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Evergreen.V60.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V60.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (Evergreen.V60.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ThreadMessageId) (Evergreen.V60.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V60.Editable.Model
    , botToken : Evergreen.V60.Editable.Model
    , slackClientSecret : Evergreen.V60.Editable.Model
    , publicVapidKey : Evergreen.V60.Editable.Model
    , privateVapidKey : Evergreen.V60.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V60.Local.Local LocalMsg Evergreen.V60.LocalState.LocalState
    , admin : Maybe Evergreen.V60.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V60.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId, Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId, Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId, Evergreen.V60.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V60.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V60.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V60.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.NonemptyDict.NonemptyDict (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Evergreen.V60.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V60.FileStatus.FileDataWithImage
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V60.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V60.SecretId.SecretId Evergreen.V60.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V60.NonemptyDict.NonemptyDict Int Evergreen.V60.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V60.NonemptyDict.NonemptyDict Int Evergreen.V60.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V60.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V60.Coord.Coord Evergreen.V60.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V60.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V60.Ports.NotificationPermission
    , pwaStatus : Evergreen.V60.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V60.AiChat.FrontendModel
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
    , userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V60.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V60.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V60.Coord.Coord Evergreen.V60.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V60.NonemptyDict.NonemptyDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V60.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V60.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.LocalState.BackendGuild
    , discordModel : Evergreen.V60.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V60.OneToOne.OneToOne (Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId)
    , discordUsers : Evergreen.V60.OneToOne.OneToOne (Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    , discordBotId : Maybe (Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V60.DmChannel.DmChannelId Evergreen.V60.DmChannel.DmChannel
    , discordDms : Evergreen.V60.OneToOne.OneToOne (Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.ChannelId) Evergreen.V60.DmChannel.DmChannelId
    , slackDms : Evergreen.V60.OneToOne.OneToOne (Evergreen.V60.Slack.Id Evergreen.V60.Slack.ChannelId) Evergreen.V60.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V60.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V60.OneToOne.OneToOne String (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId)
    , slackUsers : Evergreen.V60.OneToOne.OneToOne (Evergreen.V60.Slack.Id Evergreen.V60.Slack.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    , slackServers : Evergreen.V60.OneToOne.OneToOne (Evergreen.V60.Slack.Id Evergreen.V60.Slack.TeamId) (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId)
    , slackToken : Maybe Evergreen.V60.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V60.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V60.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V60.Ports.PushSubscription
    , slackClientSecret : Maybe Evergreen.V60.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V60.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V60.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V60.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V60.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V60.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V60.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V60.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) Evergreen.V60.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) Evergreen.V60.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V60.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V60.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V60.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage (Evergreen.V60.Coord.Coord Evergreen.V60.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V60.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V60.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V60.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V60.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V60.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V60.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V60.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V60.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V60.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V60.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V60.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V60.Id.GuildOrDmIdNoThread, Evergreen.V60.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V60.NonemptyDict.NonemptyDict Int Evergreen.V60.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V60.NonemptyDict.NonemptyDict Int Evergreen.V60.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V60.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V60.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V60.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V60.Editable.Msg Evergreen.V60.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V60.Editable.Msg (Maybe Evergreen.V60.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V60.Editable.Msg (Maybe Evergreen.V60.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V60.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V60.Editable.Msg Evergreen.V60.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V60.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V60.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V60.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V60.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V60.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V60.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V60.Id.GuildOrDmId (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V60.Id.GuildOrDmIdNoThread Evergreen.V60.Id.ThreadRouteWithMessage Evergreen.V60.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V60.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool
    | PressedGuildNotificationLevel (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) Evergreen.V60.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V60.Id.GuildOrDmIdNoThread, Evergreen.V60.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V60.Id.GuildOrDmIdNoThread, Evergreen.V60.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V60.Id.GuildOrDmIdNoThread, Evergreen.V60.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V60.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V60.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V60.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V60.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.SecretId.SecretId Evergreen.V60.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V60.Id.GuildOrDmIdNoThread, Evergreen.V60.Id.ThreadRoute )) Evergreen.V60.PersonName.PersonName
    | AiChatToBackend Evergreen.V60.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V60.Id.GuildOrDmIdNoThread, Evergreen.V60.Id.ThreadRoute ))
    | RegisterPushSubscriptionRequest Evergreen.V60.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Evergreen.V60.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V60.EmailAddress.EmailAddress (Result Evergreen.V60.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V60.EmailAddress.EmailAddress (Result Evergreen.V60.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V60.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V60.LocalState.DiscordBotToken (Result Evergreen.V60.Discord.HttpError ( Evergreen.V60.Discord.User, List Evergreen.V60.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.UserId)
        (Result
            Evergreen.V60.Discord.HttpError
            (List
                ( Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.GuildId
                , { guild : Evergreen.V60.Discord.Guild
                  , members : List Evergreen.V60.Discord.GuildMember
                  , channels : List ( Evergreen.V60.Discord.Channel2, List Evergreen.V60.Discord.Message )
                  , icon : Maybe Evergreen.V60.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V60.Discord.Channel, List Evergreen.V60.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) Evergreen.V60.Id.ThreadRouteWithMessage (Result Evergreen.V60.Discord.HttpError Evergreen.V60.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V60.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V60.DmChannel.DmChannelId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) (Result Evergreen.V60.Discord.HttpError Evergreen.V60.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V60.Discord.HttpError (List ( Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.UserId, Maybe Evergreen.V60.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V60.Slack.CurrentUser
            , team : Evergreen.V60.Slack.Team
            , users : List Evergreen.V60.Slack.User
            , channels : List ( Evergreen.V60.Slack.Channel, List Evergreen.V60.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Result Effect.Http.Error Evergreen.V60.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V60.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V60.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V60.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V60.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
