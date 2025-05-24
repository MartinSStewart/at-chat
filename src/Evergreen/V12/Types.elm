module Evergreen.V12.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V12.ChannelName
import Evergreen.V12.Coord
import Evergreen.V12.CssPixels
import Evergreen.V12.EmailAddress
import Evergreen.V12.Emoji
import Evergreen.V12.GuildName
import Evergreen.V12.Id
import Evergreen.V12.Local
import Evergreen.V12.LocalState
import Evergreen.V12.Log
import Evergreen.V12.LoginForm
import Evergreen.V12.MessageInput
import Evergreen.V12.NonemptyDict
import Evergreen.V12.NonemptySet
import Evergreen.V12.Pages.Admin
import Evergreen.V12.Pages.UserOverview
import Evergreen.V12.PersonName
import Evergreen.V12.Point2d
import Evergreen.V12.Ports
import Evergreen.V12.Postmark
import Evergreen.V12.RichText
import Evergreen.V12.Route
import Evergreen.V12.SecretId
import Evergreen.V12.TwoFactorAuthentication
import Evergreen.V12.Ui.Anim
import Evergreen.V12.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V12.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) Evergreen.V12.LocalState.FrontendGuild
    , user : Evergreen.V12.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V12.Route.Route
    , windowSize : Evergreen.V12.Coord.Coord Evergreen.V12.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V12.Ports.NotificationPermission
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId
    , channelId : Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V12.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V12.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) Evergreen.V12.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) Evergreen.V12.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V12.SecretId.SecretId Evergreen.V12.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V12.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V12.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V12.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V12.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) Int


type ServerChange
    = Server_SendMessage (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V12.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) Evergreen.V12.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) Evergreen.V12.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.SecretId.SecretId Evergreen.V12.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) Evergreen.V12.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V12.LocalState.JoinGuildError
            { guildId : Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId
            , guild : Evergreen.V12.LocalState.FrontendGuild
            , owner : Evergreen.V12.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) MessageId Evergreen.V12.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) MessageId Evergreen.V12.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V12.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
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
    { guildId : Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId
    , channelId : Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V12.NonemptySet.NonemptySet Int)
    }


type alias LoggedIn2 =
    { localState : Evergreen.V12.Local.Local LocalMsg Evergreen.V12.LocalState.LocalState
    , admin : Maybe Evergreen.V12.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId, Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId, Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId, Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V12.MessageInput.MentionUserDropdown
    , messageHover : Maybe MessageId
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId, Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId, Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarOffset : Float
    , sidebarPreviousOffset : Float
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V12.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V12.SecretId.SecretId Evergreen.V12.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V12.Point2d.Point2d Evergreen.V12.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V12.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V12.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V12.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V12.Coord.Coord Evergreen.V12.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V12.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V12.Ports.NotificationPermission
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
    , userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V12.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V12.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V12.NonemptyDict.NonemptyDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V12.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V12.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) Evergreen.V12.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | ScrolledToTop
    | LoginFormMsg Evergreen.V12.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V12.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V12.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V12.Route.Route
    | UserOverviewMsg Evergreen.V12.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V12.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) Int
    | SetFocus
    | PressedArrowInDropdown (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | RemovedFocus
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | PressedShowReactionEmojiSelector Int
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V12.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V12.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V12.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V12.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V12.Ports.NotificationPermission
    | TouchStart (Evergreen.V12.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved (Evergreen.V12.NonemptyDict.NonemptyDict Int Touch)
    | TouchEnd
    | TouchCancel
    | OnAnimationFrameDelta Duration.Duration
    | ScrolledToBottom
    | PressedChannelHeaderBackButton


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V12.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V12.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V12.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V12.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) (Evergreen.V12.SecretId.SecretId Evergreen.V12.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V12.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V12.EmailAddress.EmailAddress (Result Evergreen.V12.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V12.EmailAddress.EmailAddress (Result Evergreen.V12.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V12.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V12.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V12.Pages.UserOverview.ToFrontend
