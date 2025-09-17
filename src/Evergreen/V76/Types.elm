module Evergreen.V76.Types exposing (..)

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
import Evergreen.V76.AiChat
import Evergreen.V76.ChannelName
import Evergreen.V76.Coord
import Evergreen.V76.CssPixels
import Evergreen.V76.Discord
import Evergreen.V76.Discord.Id
import Evergreen.V76.DmChannel
import Evergreen.V76.Editable
import Evergreen.V76.EmailAddress
import Evergreen.V76.Emoji
import Evergreen.V76.FileStatus
import Evergreen.V76.GuildName
import Evergreen.V76.Id
import Evergreen.V76.Local
import Evergreen.V76.LocalState
import Evergreen.V76.Log
import Evergreen.V76.LoginForm
import Evergreen.V76.Message
import Evergreen.V76.MessageInput
import Evergreen.V76.MessageView
import Evergreen.V76.NonemptyDict
import Evergreen.V76.NonemptySet
import Evergreen.V76.OneToOne
import Evergreen.V76.Pages.Admin
import Evergreen.V76.PersonName
import Evergreen.V76.Ports
import Evergreen.V76.Postmark
import Evergreen.V76.RichText
import Evergreen.V76.Route
import Evergreen.V76.SecretId
import Evergreen.V76.Slack
import Evergreen.V76.Touch
import Evergreen.V76.TwoFactorAuthentication
import Evergreen.V76.Ui.Anim
import Evergreen.V76.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V76.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V76.LocalState.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.DmChannel.FrontendDmChannel
    , user : Evergreen.V76.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V76.Route.Route
    , windowSize : Evergreen.V76.Coord.Coord Evergreen.V76.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V76.Ports.NotificationPermission
    , pwaStatus : Evergreen.V76.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V76.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V76.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V76.RichText.RichText) Evergreen.V76.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Evergreen.V76.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) Evergreen.V76.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V76.SecretId.SecretId Evergreen.V76.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V76.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V76.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage Evergreen.V76.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage Evergreen.V76.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V76.RichText.RichText) (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Evergreen.V76.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | Local_ViewDm (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Evergreen.V76.Message.Message Evergreen.V76.Id.ChannelMessageId)))
    | Local_ViewDmThread (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ThreadMessageId) (Evergreen.V76.Message.Message Evergreen.V76.Id.ThreadMessageId)))
    | Local_ViewChannel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Evergreen.V76.Message.Message Evergreen.V76.Id.ChannelMessageId)))
    | Local_ViewThread (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ThreadMessageId) (Evergreen.V76.Message.Message Evergreen.V76.Id.ThreadMessageId)))
    | Local_SetName Evergreen.V76.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V76.Id.GuildOrDmIdNoThread (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Evergreen.V76.Message.Message Evergreen.V76.Id.ChannelMessageId)))
    | Local_LoadThreadMessages Evergreen.V76.Id.GuildOrDmIdNoThread (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ThreadMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ThreadMessageId) (Evergreen.V76.Message.Message Evergreen.V76.Id.ThreadMessageId)))
    | Local_SetGuildNotificationLevel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V76.LocalState.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V76.LocalState.SubscribeData


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId
    , channelId : Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId
    , messageIndex : Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Effect.Time.Posix Evergreen.V76.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V76.RichText.RichText) Evergreen.V76.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Evergreen.V76.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) Evergreen.V76.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.SecretId.SecretId Evergreen.V76.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V76.LocalState.JoinGuildError
            { guildId : Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId
            , guild : Evergreen.V76.LocalState.FrontendGuild
            , owner : Evergreen.V76.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage Evergreen.V76.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage Evergreen.V76.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V76.RichText.RichText) (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Evergreen.V76.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (List.Nonempty.Nonempty Evergreen.V76.RichText.RichText) (Maybe (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error


type LocalMsg
    = LocalChange (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V76.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V76.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V76.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V76.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V76.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V76.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V76.Coord.Coord Evergreen.V76.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V76.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V76.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Evergreen.V76.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V76.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Evergreen.V76.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ThreadMessageId) (Evergreen.V76.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V76.Editable.Model
    , botToken : Evergreen.V76.Editable.Model
    , slackClientSecret : Evergreen.V76.Editable.Model
    , publicVapidKey : Evergreen.V76.Editable.Model
    , privateVapidKey : Evergreen.V76.Editable.Model
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V76.Local.Local LocalMsg Evergreen.V76.LocalState.LocalState
    , admin : Maybe Evergreen.V76.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V76.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId, Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId, Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId, Evergreen.V76.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V76.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V76.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V76.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.NonemptyDict.NonemptyDict (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Evergreen.V76.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V76.FileStatus.FileDataWithImage
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V76.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V76.SecretId.SecretId Evergreen.V76.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V76.NonemptyDict.NonemptyDict Int Evergreen.V76.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V76.NonemptyDict.NonemptyDict Int Evergreen.V76.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V76.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V76.Coord.Coord Evergreen.V76.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V76.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V76.Ports.NotificationPermission
    , pwaStatus : Evergreen.V76.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V76.AiChat.FrontendModel
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
    , userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V76.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V76.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V76.Coord.Coord Evergreen.V76.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V76.NonemptyDict.NonemptyDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V76.LocalState.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V76.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V76.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.LocalState.BackendGuild
    , discordModel : Evergreen.V76.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V76.OneToOne.OneToOne (Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId)
    , discordUsers : Evergreen.V76.OneToOne.OneToOne (Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    , discordBotId : Maybe (Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V76.DmChannel.DmChannelId Evergreen.V76.DmChannel.DmChannel
    , discordDms : Evergreen.V76.OneToOne.OneToOne (Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.ChannelId) Evergreen.V76.DmChannel.DmChannelId
    , slackDms : Evergreen.V76.OneToOne.OneToOne (Evergreen.V76.Slack.Id Evergreen.V76.Slack.ChannelId) Evergreen.V76.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V76.LocalState.DiscordBotToken
    , slackWorkspaces : Evergreen.V76.OneToOne.OneToOne String (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId)
    , slackUsers : Evergreen.V76.OneToOne.OneToOne (Evergreen.V76.Slack.Id Evergreen.V76.Slack.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    , slackServers : Evergreen.V76.OneToOne.OneToOne (Evergreen.V76.Slack.Id Evergreen.V76.Slack.TeamId) (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId)
    , slackToken : Maybe Evergreen.V76.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V76.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V76.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V76.Slack.ClientSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V76.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V76.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V76.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V76.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V76.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V76.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V76.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) Evergreen.V76.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) Evergreen.V76.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V76.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V76.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V76.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage (Evergreen.V76.Coord.Coord Evergreen.V76.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V76.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V76.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V76.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V76.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V76.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V76.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V76.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V76.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V76.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V76.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V76.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V76.Id.GuildOrDmIdNoThread, Evergreen.V76.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V76.NonemptyDict.NonemptyDict Int Evergreen.V76.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V76.NonemptyDict.NonemptyDict Int Evergreen.V76.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V76.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V76.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V76.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V76.Editable.Msg Evergreen.V76.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V76.Editable.Msg (Maybe Evergreen.V76.LocalState.DiscordBotToken))
    | SlackClientSecretEditableMsg (Evergreen.V76.Editable.Msg (Maybe Evergreen.V76.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V76.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V76.Editable.Msg Evergreen.V76.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V76.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId)
    | PressedViewAttachedFileInfo Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V76.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V76.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V76.FileStatus.UploadResponse)
    | EditMessage_PastedFiles Evergreen.V76.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V76.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V76.Id.GuildOrDmId (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V76.Id.GuildOrDmIdNoThread Evergreen.V76.Id.ThreadRouteWithMessage Evergreen.V76.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V76.LocalState.SubscribeData)
    | SelectedNotificationMode Evergreen.V76.LocalState.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) Evergreen.V76.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V76.Id.GuildOrDmIdNoThread, Evergreen.V76.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V76.Id.GuildOrDmIdNoThread, Evergreen.V76.Id.ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V76.Id.GuildOrDmIdNoThread, Evergreen.V76.Id.ThreadRoute )) Int
    | GetLoginTokenRequest Evergreen.V76.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V76.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V76.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V76.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.SecretId.SecretId Evergreen.V76.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V76.Id.GuildOrDmIdNoThread, Evergreen.V76.Id.ThreadRoute )) Evergreen.V76.PersonName.PersonName
    | AiChatToBackend Evergreen.V76.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V76.Id.GuildOrDmIdNoThread, Evergreen.V76.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V76.Slack.OAuthCode Effect.Lamdera.SessionId


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V76.EmailAddress.EmailAddress (Result Evergreen.V76.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V76.EmailAddress.EmailAddress (Result Evergreen.V76.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V76.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V76.LocalState.DiscordBotToken (Result Evergreen.V76.Discord.HttpError ( Evergreen.V76.Discord.User, List Evergreen.V76.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.UserId)
        (Result
            Evergreen.V76.Discord.HttpError
            (List
                ( Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.GuildId
                , { guild : Evergreen.V76.Discord.Guild
                  , members : List Evergreen.V76.Discord.GuildMember
                  , channels : List ( Evergreen.V76.Discord.Channel2, List Evergreen.V76.Discord.Message )
                  , icon : Maybe Evergreen.V76.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V76.Discord.Channel, List Evergreen.V76.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) Evergreen.V76.Id.ThreadRouteWithMessage (Result Evergreen.V76.Discord.HttpError Evergreen.V76.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V76.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V76.DmChannel.DmChannelId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Result Evergreen.V76.Discord.HttpError Evergreen.V76.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V76.Discord.HttpError (List ( Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.UserId, Maybe Evergreen.V76.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V76.Slack.CurrentUser
            , team : Evergreen.V76.Slack.Team
            , users : List Evergreen.V76.Slack.User
            , channels : List ( Evergreen.V76.Slack.Channel, List Evergreen.V76.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Result Effect.Http.Error Evergreen.V76.Slack.TokenResponse)


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
    | AdminToFrontend Evergreen.V76.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V76.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V76.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V76.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
