module Evergreen.V7.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V7.ChannelName
import Evergreen.V7.Coord
import Evergreen.V7.CssPixels
import Evergreen.V7.EmailAddress
import Evergreen.V7.Emoji
import Evergreen.V7.Id
import Evergreen.V7.Local
import Evergreen.V7.LocalState
import Evergreen.V7.Log
import Evergreen.V7.LoginForm
import Evergreen.V7.MessageInput
import Evergreen.V7.NonemptyDict
import Evergreen.V7.NonemptySet
import Evergreen.V7.Pages.Admin
import Evergreen.V7.Pages.UserOverview
import Evergreen.V7.PersonName
import Evergreen.V7.Point2d
import Evergreen.V7.Ports
import Evergreen.V7.Postmark
import Evergreen.V7.RichText
import Evergreen.V7.Route
import Evergreen.V7.SecretId
import Evergreen.V7.TwoFactorAuthentication
import Evergreen.V7.Ui.Anim
import Evergreen.V7.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V7.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) Evergreen.V7.LocalState.FrontendGuild
    , user : Evergreen.V7.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V7.Route.Route
    , windowSize : Evergreen.V7.Coord.Coord Evergreen.V7.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V7.Ports.NotificationPermission
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId
    , channelId : Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V7.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V7.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) Evergreen.V7.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) Evergreen.V7.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V7.SecretId.SecretId Evergreen.V7.Id.InviteLinkId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V7.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V7.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V7.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) Int


type ServerChange
    = Server_SendMessage (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V7.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) Evergreen.V7.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) Evergreen.V7.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.SecretId.SecretId Evergreen.V7.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) Evergreen.V7.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V7.LocalState.JoinGuildError
            { guildId : Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId
            , guild : Evergreen.V7.LocalState.FrontendGuild
            , owner : Evergreen.V7.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) MessageId Evergreen.V7.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) MessageId Evergreen.V7.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V7.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction MessageId
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    }


type alias RevealedSpoilers =
    { guildId : Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId
    , channelId : Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V7.NonemptySet.NonemptySet Int)
    }


type alias LoggedIn2 =
    { localState : Evergreen.V7.Local.Local LocalMsg Evergreen.V7.LocalState.LocalState
    , admin : Maybe Evergreen.V7.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId, Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId, Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId ) NewChannelForm
    , channelNameHover : Maybe ( Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId, Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V7.MessageInput.MentionUserDropdown
    , messageHover : Maybe MessageId
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId, Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId, Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarOffset : Float
    , sidebarPreviousOffset : Float
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V7.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V7.SecretId.SecretId Evergreen.V7.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V7.Point2d.Point2d Evergreen.V7.CssPixels.CssPixels ScreenCoordinate
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V7.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V7.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V7.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V7.Coord.Coord Evergreen.V7.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V7.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V7.Ports.NotificationPermission
    , drag : Drag
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V7.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V7.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V7.NonemptyDict.NonemptyDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V7.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V7.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) Evergreen.V7.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | ScrolledToTop
    | LoginFormMsg Evergreen.V7.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V7.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V7.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V7.Route.Route
    | UserOverviewMsg Evergreen.V7.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V7.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) Int
    | SetFocus
    | PressedArrowInDropdown (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | RemovedFocus
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | PressedShowReactionEmojiSelector Int
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V7.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V7.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V7.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V7.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V7.Ports.NotificationPermission
    | TouchStart (Evergreen.V7.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved (Evergreen.V7.NonemptyDict.NonemptyDict Int Touch)
    | TouchEnd
    | TouchCancel
    | OnAnimationFrameDelta Duration.Duration
    | ScrolledToBottom
    | PressedChannelHeaderBackButton


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V7.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V7.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V7.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V7.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) (Evergreen.V7.SecretId.SecretId Evergreen.V7.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V7.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V7.EmailAddress.EmailAddress (Result Evergreen.V7.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V7.EmailAddress.EmailAddress (Result Evergreen.V7.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V7.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V7.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V7.Pages.UserOverview.ToFrontend
