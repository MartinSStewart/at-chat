module Evergreen.V5.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V5.ChannelName
import Evergreen.V5.Coord
import Evergreen.V5.CssPixels
import Evergreen.V5.EmailAddress
import Evergreen.V5.Emoji
import Evergreen.V5.Id
import Evergreen.V5.Local
import Evergreen.V5.LocalState
import Evergreen.V5.Log
import Evergreen.V5.LoginForm
import Evergreen.V5.MessageInput
import Evergreen.V5.NonemptyDict
import Evergreen.V5.NonemptySet
import Evergreen.V5.Pages.Admin
import Evergreen.V5.Pages.UserOverview
import Evergreen.V5.PersonName
import Evergreen.V5.Point2d
import Evergreen.V5.Ports
import Evergreen.V5.Postmark
import Evergreen.V5.RichText
import Evergreen.V5.Route
import Evergreen.V5.SecretId
import Evergreen.V5.TwoFactorAuthentication
import Evergreen.V5.Ui.Anim
import Evergreen.V5.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V5.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) Evergreen.V5.LocalState.FrontendGuild
    , user : Evergreen.V5.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V5.Route.Route
    , windowSize : Evergreen.V5.Coord.Coord Evergreen.V5.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V5.Ports.NotificationPermission
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId
    , channelId : Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V5.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V5.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) Evergreen.V5.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) Evergreen.V5.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V5.SecretId.SecretId Evergreen.V5.Id.InviteLinkId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V5.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V5.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V5.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) Int


type ServerChange
    = Server_SendMessage (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V5.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) Evergreen.V5.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) Evergreen.V5.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.SecretId.SecretId Evergreen.V5.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) Evergreen.V5.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V5.LocalState.JoinGuildError
            { guildId : Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId
            , guild : Evergreen.V5.LocalState.FrontendGuild
            , owner : Evergreen.V5.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) MessageId Evergreen.V5.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) MessageId Evergreen.V5.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V5.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) LocalChange
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
    { guildId : Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId
    , channelId : Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V5.NonemptySet.NonemptySet Int)
    }


type alias LoggedIn2 =
    { localState : Evergreen.V5.Local.Local LocalMsg Evergreen.V5.LocalState.LocalState
    , admin : Maybe Evergreen.V5.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId, Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId, Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId ) NewChannelForm
    , channelNameHover : Maybe ( Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId, Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V5.MessageInput.MentionUserDropdown
    , messageHover : Maybe MessageId
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId, Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId, Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarOffset : Float
    , sidebarPreviousOffset : Float
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V5.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V5.SecretId.SecretId Evergreen.V5.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V5.Point2d.Point2d Evergreen.V5.CssPixels.CssPixels ScreenCoordinate
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V5.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V5.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V5.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V5.Coord.Coord Evergreen.V5.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V5.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V5.Ports.NotificationPermission
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
    , userId : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V5.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V5.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V5.NonemptyDict.NonemptyDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V5.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V5.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) Evergreen.V5.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | ScrolledToTop
    | LoginFormMsg Evergreen.V5.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V5.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V5.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V5.Route.Route
    | UserOverviewMsg Evergreen.V5.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V5.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) Int
    | SetFocus
    | PressedArrowInDropdown (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | RemovedFocus
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | PressedShowReactionEmojiSelector Int
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V5.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V5.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V5.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V5.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V5.Ports.NotificationPermission
    | TouchStart (Evergreen.V5.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved (Evergreen.V5.NonemptyDict.NonemptyDict Int Touch)
    | TouchEnd
    | TouchCancel
    | OnAnimationFrameDelta Duration.Duration
    | ScrolledToBottom


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V5.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V5.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V5.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V5.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) (Evergreen.V5.SecretId.SecretId Evergreen.V5.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V5.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V5.EmailAddress.EmailAddress (Result Evergreen.V5.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V5.EmailAddress.EmailAddress (Result Evergreen.V5.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V5.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V5.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V5.Pages.UserOverview.ToFrontend
