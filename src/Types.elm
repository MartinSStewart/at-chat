module Types exposing
    ( AdminStatusLoginData(..)
    , BackendModel
    , BackendMsg(..)
    , Drag(..)
    , EditMessage
    , EmojiSelector(..)
    , FrontendModel(..)
    , FrontendMsg(..)
    , LastRequest(..)
    , LoadStatus(..)
    , LoadedFrontend
    , LoadingFrontend
    , LocalChange(..)
    , LocalMsg(..)
    , LoggedIn2
    , LoginData
    , LoginResult(..)
    , LoginStatus(..)
    , LoginTokenData(..)
    , MessageId
    , NewChannelForm
    , NewGuildForm
    , RevealedSpoilers
    , ScreenCoordinate(..)
    , ServerChange(..)
    , ToBackend(..)
    , ToBeFilledInByBackend(..)
    , ToFrontend(..)
    , Touch
    , WaitingForLoginTokenData
    )

import Array exposing (Array)
import Browser exposing (UrlRequest)
import ChannelName exposing (ChannelName)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events exposing (Visibility)
import Effect.Browser.Navigation exposing (Key)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Emoji)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, UserId)
import List.Nonempty exposing (Nonempty)
import Local exposing (ChangeId, Local)
import LocalState exposing (BackendGuild, FrontendGuild, JoinGuildError, LocalState)
import Log exposing (Log)
import LoginForm exposing (LoginForm)
import MessageInput exposing (MentionUserDropdown)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import Pages.Admin exposing (AdminChange, InitAdminData)
import Pages.UserOverview
import PersonName exposing (PersonName)
import Point2d exposing (Point2d)
import Ports exposing (NotificationPermission)
import Postmark
import RichText exposing (RichText)
import Route exposing (Route)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString)
import TwoFactorAuthentication exposing (TwoFactorAuthentication, TwoFactorAuthenticationSetup)
import Ui.Anim
import Url exposing (Url)
import User exposing (BackendUser, FrontendUser)


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias LoadingFrontend =
    { navigationKey : Key
    , route : Route
    , windowSize : Coord CssPixels
    , time : Maybe Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : NotificationPermission
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadedFrontend =
    { navigationKey : Key
    , route : Route
    , time : Time.Posix
    , windowSize : Coord CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Ui.Anim.State
    , lastCopied : Maybe { copiedAt : Time.Posix, copiedText : String }
    , textInputFocus : Maybe HtmlId
    , notificationPermission : NotificationPermission
    , drag : Drag
    , scrolledToBottomOfChannel : Bool
    }


type Drag
    = NoDrag
    | DragStart (NonemptyDict Int Touch)
    | Dragging { horizontalStart : Bool, touches : NonemptyDict Int Touch }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn { loginForm : Maybe LoginForm, useInviteAfterLoggedIn : Maybe (SecretId InviteLinkId) }


type alias LoggedIn2 =
    { localState : Local LocalMsg LocalState
    , admin : Maybe Pages.Admin.Model
    , userOverview : SeqDict (Id UserId) Pages.UserOverview.Model
    , drafts : SeqDict ( Id GuildId, Id ChannelId ) NonemptyString
    , newChannelForm : SeqDict (Id GuildId) NewChannelForm
    , editChannelForm : SeqDict ( Id GuildId, Id ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Id GuildId, Id ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe MentionUserDropdown
    , messageHover : Maybe MessageId
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict ( Id GuildId, Id ChannelId ) EditMessage
    , replyTo : SeqDict ( Id GuildId, Id ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarOffset : Float
    , sidebarPreviousOffset : Float
    }


type alias RevealedSpoilers =
    { guildId : Id GuildId
    , channelId : Id ChannelId
    , messages : SeqDict Int (NonemptySet Int)
    }


type alias EditMessage =
    { messageIndex : Int, text : String }


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction MessageId
    | EmojiSelectorForMessage


type alias MessageId =
    { guildId : Id GuildId, channelId : Id ChannelId, messageIndex : Int }


type alias BackendModel =
    { users : NonemptyDict (Id UserId) BackendUser
    , sessions : SeqDict SessionId (Id UserId)
    , connections : SeqDict SessionId (NonemptyDict ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict SessionId LoginTokenData
    , logs : Array { time : Time.Posix, log : Log }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Time.Posix
    , -- This could be part of BackendUser but having it separate reduces the chances of leaking 2FA secrets to other users. We could also just derive a secret key from `Env.secretKey ++ Id.toString userId` but this would cause problems if we ever changed Env.secretKey for some reason.
      twoFactorAuthentication : SeqDict (Id UserId) TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict (Id UserId) TwoFactorAuthenticationSetup
    , guilds : SeqDict (Id GuildId) BackendGuild
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Time.Posix


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Time.Posix
        , userId : Id UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Time.Posix
        , emailAddress : EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Time.Posix
        , emailAddress : EmailAddress
        }


type alias WaitingForLoginTokenData =
    { creationTime : Time.Posix
    , userId : Id UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | GotTime Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Route
    | UserOverviewMsg Pages.UserOverview.Msg
    | TypedMessage (Id GuildId) (Id ChannelId) String
    | PressedSendMessage (Id GuildId) (Id ChannelId)
    | NewChannelFormChanged (Id GuildId) NewChannelForm
    | PressedSubmitNewChannel (Id GuildId) NewChannelForm
    | MouseEnteredChannelName (Id GuildId) (Id ChannelId)
    | MouseExitedChannelName (Id GuildId) (Id ChannelId)
    | EditChannelFormChanged (Id GuildId) (Id ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Id GuildId) (Id ChannelId)
    | PressedSubmitEditChannelChanges (Id GuildId) (Id ChannelId) NewChannelForm
    | PressedDeleteChannel (Id GuildId) (Id ChannelId)
    | PressedCreateInviteLink (Id GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Dom.Error MentionUserDropdown)
    | PressedPingUser (Id GuildId) (Id ChannelId) Int
    | SetFocus
    | PressedArrowInDropdown (Id GuildId) Int
    | TextInputGotFocus HtmlId
    | TextInputLostFocus HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | PressedShowReactionEmojiSelector Int
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Emoji
    | PressedReactionEmoji_Add Int Emoji
    | PressedReactionEmoji_Remove Int Emoji
    | GotPingUserPositionForEditMessage (Result Dom.Error MentionUserDropdown)
    | TypedEditMessage (Id GuildId) (Id ChannelId) String
    | PressedSendEditMessage (Id GuildId) (Id ChannelId)
    | PressedArrowInDropdownForEditMessage (Id GuildId) Int
    | PressedPingUserForEditMessage (Id GuildId) (Id ChannelId) Int
    | PressedArrowUpInEmptyInput (Id GuildId) (Id ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Id GuildId) (Id ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Visibility
    | CheckedNotificationPermission NotificationPermission
    | TouchStart (NonemptyDict Int Touch)
    | TouchMoved (NonemptyDict Int Touch)
    | TouchEnd
    | TouchCancel
    | OnAnimationFrameDelta Duration
    | ScrolledToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled { scrolledToBottomOfChannel : Bool }
    | PressedBody
    | PressedReactionEmojiContainer


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Point2d CssPixels ScreenCoordinate
    , target : HtmlId
    }


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest EmailAddress
    | AdminToBackend Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest ChangeId LocalChange
    | UserOverviewToBackend Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Id GuildId) (SecretId InviteLinkId)
    | FinishUserCreationRequest PersonName


type BackendMsg
    = SentLoginEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())
    | Connected SessionId ClientId
    | Disconnected SessionId ClientId
    | BackendGotTime SessionId ClientId ToBackend Time.Posix
    | SentLogErrorEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())


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
    | AdminToFrontend Pages.Admin.ToFrontend
    | LocalChangeResponse ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Pages.UserOverview.ToFrontend


type alias LoginData =
    { userId : Id UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Time.Posix
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , user : BackendUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    }


type AdminStatusLoginData
    = IsAdminLoginData InitAdminData
    | IsNotAdminLoginData


type LocalMsg
    = LocalChange (Id UserId) LocalChange
    | ServerChange ServerChange


type ServerChange
    = Server_SendMessage (Id UserId) Time.Posix (Id GuildId) (Id ChannelId) (Nonempty RichText) (Maybe Int)
    | Server_NewChannel Time.Posix (Id GuildId) ChannelName
    | Server_EditChannel (Id GuildId) (Id ChannelId) ChannelName
    | Server_DeleteChannel (Id GuildId) (Id ChannelId)
    | Server_NewInviteLink Time.Posix (Id UserId) (Id GuildId) (SecretId InviteLinkId)
    | Server_MemberJoined Time.Posix (Id UserId) (Id GuildId) FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            JoinGuildError
            { guildId : Id GuildId
            , guild : FrontendGuild
            , owner : FrontendUser
            , members : SeqDict (Id UserId) FrontendUser
            }
        )
    | Server_MemberTyping Time.Posix (Id UserId) (Id GuildId) (Id ChannelId)
    | Server_AddReactionEmoji (Id UserId) MessageId Emoji
    | Server_RemoveReactionEmoji (Id UserId) MessageId Emoji
    | Server_SendEditMessage Time.Posix (Id UserId) MessageId (Nonempty RichText)
    | Server_MemberEditTyping Time.Posix (Id UserId) MessageId


type LocalChange
    = Local_Invalid
    | Local_Admin AdminChange
    | Local_SendMessage Time.Posix (Id GuildId) (Id ChannelId) (Nonempty RichText) (Maybe Int)
    | Local_NewChannel Time.Posix (Id GuildId) ChannelName
    | Local_EditChannel (Id GuildId) (Id ChannelId) ChannelName
    | Local_DeleteChannel (Id GuildId) (Id ChannelId)
    | Local_NewInviteLink Time.Posix (Id GuildId) (ToBeFilledInByBackend (SecretId InviteLinkId))
    | Local_NewGuild Time.Posix GuildName (ToBeFilledInByBackend (Id GuildId))
    | Local_MemberTyping Time.Posix (Id GuildId) (Id ChannelId)
    | Local_AddReactionEmoji MessageId Emoji
    | Local_RemoveReactionEmoji MessageId Emoji
    | Local_SendEditMessage Time.Posix MessageId (Nonempty RichText)
    | Local_MemberEditTyping Time.Posix MessageId
    | Local_SetLastViewed (Id GuildId) (Id ChannelId) Int


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a
