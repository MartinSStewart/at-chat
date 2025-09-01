module Evergreen.V46.Types exposing (..)

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
import Evergreen.V46.AiChat
import Evergreen.V46.ChannelName
import Evergreen.V46.Coord
import Evergreen.V46.CssPixels
import Evergreen.V46.Discord
import Evergreen.V46.Discord.Id
import Evergreen.V46.DmChannel
import Evergreen.V46.Editable
import Evergreen.V46.EmailAddress
import Evergreen.V46.Emoji
import Evergreen.V46.FileStatus
import Evergreen.V46.GuildName
import Evergreen.V46.Id
import Evergreen.V46.Local
import Evergreen.V46.LocalState
import Evergreen.V46.Log
import Evergreen.V46.LoginForm
import Evergreen.V46.MessageInput
import Evergreen.V46.MessageView
import Evergreen.V46.NonemptyDict
import Evergreen.V46.NonemptySet
import Evergreen.V46.OneToOne
import Evergreen.V46.Pages.Admin
import Evergreen.V46.PersonName
import Evergreen.V46.Ports
import Evergreen.V46.Postmark
import Evergreen.V46.RichText
import Evergreen.V46.Route
import Evergreen.V46.SecretId
import Evergreen.V46.Touch
import Evergreen.V46.TwoFactorAuthentication
import Evergreen.V46.Ui.Anim
import Evergreen.V46.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V46.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) Evergreen.V46.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.DmChannel.DmChannel
    , user : Evergreen.V46.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V46.Route.Route
    , windowSize : Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V46.Ports.NotificationPermission
    , pwaStatus : Evergreen.V46.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V46.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V46.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V46.RichText.RichText) Evergreen.V46.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Evergreen.V46.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) Evergreen.V46.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) Evergreen.V46.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V46.SecretId.SecretId Evergreen.V46.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V46.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V46.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage Evergreen.V46.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage Evergreen.V46.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V46.RichText.RichText) (SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Evergreen.V46.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | Local_ViewChannel (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    | Local_SetName Evergreen.V46.PersonName.PersonName


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId
    , channelId : Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId
    , messageIndex : Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Effect.Time.Posix Evergreen.V46.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V46.RichText.RichText) Evergreen.V46.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Evergreen.V46.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) Evergreen.V46.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) Evergreen.V46.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.SecretId.SecretId Evergreen.V46.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) Evergreen.V46.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V46.LocalState.JoinGuildError
            { guildId : Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId
            , guild : Evergreen.V46.LocalState.FrontendGuild
            , owner : Evergreen.V46.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage Evergreen.V46.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage Evergreen.V46.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V46.RichText.RichText) (SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Evergreen.V46.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.MessageId) (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (List.Nonempty.Nonempty Evergreen.V46.RichText.RichText) (Maybe (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalMsg
    = LocalChange (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V46.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V46.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V46.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V46.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V46.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V46.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V46.Id.GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V46.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Evergreen.V46.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V46.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId) (Evergreen.V46.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ThreadMessageId) (Evergreen.V46.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V46.Editable.Model
    , botToken : Evergreen.V46.Editable.Model
    , publicVapidKey : Evergreen.V46.Editable.Model
    , privateVapidKey : Evergreen.V46.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V46.Local.Local LocalMsg Evergreen.V46.LocalState.LocalState
    , admin : Maybe Evergreen.V46.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V46.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId, Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId, Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId, Evergreen.V46.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V46.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V46.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V46.Id.GuildOrDmId (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V46.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V46.Id.GuildOrDmId (Evergreen.V46.NonemptyDict.NonemptyDict (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Evergreen.V46.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V46.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V46.SecretId.SecretId Evergreen.V46.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V46.NonemptyDict.NonemptyDict Int Evergreen.V46.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V46.NonemptyDict.NonemptyDict Int Evergreen.V46.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V46.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V46.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V46.Ports.NotificationPermission
    , pwaStatus : Evergreen.V46.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V46.AiChat.FrontendModel
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
    , userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V46.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V46.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V46.NonemptyDict.NonemptyDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V46.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V46.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) Evergreen.V46.LocalState.BackendGuild
    , discordModel : Evergreen.V46.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId)
    , discordUsers : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    , discordBotId : Maybe (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V46.DmChannel.DmChannelId Evergreen.V46.DmChannel.DmChannel
    , discordDms : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.ChannelId) Evergreen.V46.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V46.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V46.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V46.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V46.Ports.PushSubscription
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V46.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V46.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V46.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V46.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V46.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V46.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V46.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) Evergreen.V46.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) Evergreen.V46.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V46.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V46.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V46.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V46.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V46.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V46.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V46.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V46.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V46.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V46.Id.GuildOrDmId
    | MessageMenu_PressedReply Evergreen.V46.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V46.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V46.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V46.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V46.Id.GuildOrDmIdNoThread, Evergreen.V46.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V46.NonemptyDict.NonemptyDict Int Evergreen.V46.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V46.NonemptyDict.NonemptyDict Int Evergreen.V46.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | ScrolledToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled
        { scrolledToBottomOfChannel : Bool
        }
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V46.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V46.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V46.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V46.Editable.Msg Evergreen.V46.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V46.Editable.Msg (Maybe Evergreen.V46.LocalState.DiscordBotToken))
    | PublicVapidKeyEditableMsg (Evergreen.V46.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V46.Editable.Msg Evergreen.V46.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V46.Id.GuildOrDmId (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V46.FileStatus.FileHash, Maybe (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V46.Id.GuildOrDmId (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V46.Id.GuildOrDmId (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V46.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V46.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V46.Id.GuildOrDmId (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId) (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V46.FileStatus.FileHash, Maybe (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V46.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V46.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V46.Id.GuildOrDmId (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V46.Id.GuildOrDmIdNoThread Evergreen.V46.Id.ThreadRouteWithMessage Evergreen.V46.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V46.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V46.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V46.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V46.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V46.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.SecretId.SecretId Evergreen.V46.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V46.PersonName.PersonName
    | AiChatToBackend Evergreen.V46.AiChat.ToBackend
    | ReloadDataRequest
    | RegisterPushSubscriptionRequest Evergreen.V46.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V46.EmailAddress.EmailAddress (Result Evergreen.V46.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V46.EmailAddress.EmailAddress (Result Evergreen.V46.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V46.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V46.LocalState.DiscordBotToken (Result Evergreen.V46.Discord.HttpError ( Evergreen.V46.Discord.User, List Evergreen.V46.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.UserId)
        (Result
            Evergreen.V46.Discord.HttpError
            (List
                ( Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.GuildId
                , { guild : Evergreen.V46.Discord.Guild
                  , members : List Evergreen.V46.Discord.GuildMember
                  , channels : List ( Evergreen.V46.Discord.Channel2, List Evergreen.V46.Discord.Message )
                  , icon : Maybe ( Evergreen.V46.FileStatus.FileHash, Maybe (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V46.Discord.Channel, List Evergreen.V46.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) Evergreen.V46.Id.ThreadRouteWithMessage (Result Evergreen.V46.Discord.HttpError Evergreen.V46.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V46.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V46.DmChannel.DmChannelId (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId) (Result Evergreen.V46.Discord.HttpError Evergreen.V46.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V46.Discord.HttpError (List ( Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.UserId, Maybe ( Evergreen.V46.FileStatus.FileHash, Maybe (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels) ) )))
    | SentNotification Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)


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
    | AdminToFrontend Evergreen.V46.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V46.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V46.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V46.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
