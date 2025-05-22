module Evergreen.V4.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V4.ChannelName
import Evergreen.V4.Coord
import Evergreen.V4.CssPixels
import Evergreen.V4.EmailAddress
import Evergreen.V4.Emoji
import Evergreen.V4.Id
import Evergreen.V4.Local
import Evergreen.V4.LocalState
import Evergreen.V4.Log
import Evergreen.V4.LoginForm
import Evergreen.V4.MessageInput
import Evergreen.V4.NonemptyDict
import Evergreen.V4.NonemptySet
import Evergreen.V4.Pages.Admin
import Evergreen.V4.Pages.UserOverview
import Evergreen.V4.PersonName
import Evergreen.V4.Point2d
import Evergreen.V4.Ports
import Evergreen.V4.Postmark
import Evergreen.V4.RichText
import Evergreen.V4.Route
import Evergreen.V4.SecretId
import Evergreen.V4.TwoFactorAuthentication
import Evergreen.V4.Ui.Anim
import Evergreen.V4.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V4.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) Evergreen.V4.LocalState.FrontendGuild
    , user : Evergreen.V4.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V4.Route.Route
    , windowSize : Evergreen.V4.Coord.Coord Evergreen.V4.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V4.Ports.NotificationPermission
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId
    , channelId : Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V4.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V4.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) Evergreen.V4.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) Evergreen.V4.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V4.SecretId.SecretId Evergreen.V4.Id.InviteLinkId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V4.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V4.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V4.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) Int


type ServerChange
    = Server_SendMessage (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V4.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) Evergreen.V4.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) Evergreen.V4.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.SecretId.SecretId Evergreen.V4.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) Evergreen.V4.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V4.LocalState.JoinGuildError
            { guildId : Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId
            , guild : Evergreen.V4.LocalState.FrontendGuild
            , owner : Evergreen.V4.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) MessageId Evergreen.V4.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) MessageId Evergreen.V4.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V4.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) LocalChange
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
    { guildId : Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId
    , channelId : Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V4.NonemptySet.NonemptySet Int)
    }


type alias LoggedIn2 =
    { localState : Evergreen.V4.Local.Local LocalMsg Evergreen.V4.LocalState.LocalState
    , admin : Maybe Evergreen.V4.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId, Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId, Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId ) NewChannelForm
    , channelNameHover : Maybe ( Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId, Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V4.MessageInput.MentionUserDropdown
    , messageHover : Maybe MessageId
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId, Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId, Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarOffset : Float
    , sidebarPreviousOffset : Float
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V4.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V4.SecretId.SecretId Evergreen.V4.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V4.Point2d.Point2d Evergreen.V4.CssPixels.CssPixels ScreenCoordinate
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V4.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V4.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V4.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V4.Coord.Coord Evergreen.V4.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V4.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V4.Ports.NotificationPermission
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
    , userId : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V4.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V4.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V4.NonemptyDict.NonemptyDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V4.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V4.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) Evergreen.V4.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | ScrolledToTop
    | LoginFormMsg Evergreen.V4.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V4.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V4.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V4.Route.Route
    | UserOverviewMsg Evergreen.V4.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V4.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) Int
    | SetFocus
    | PressedArrowInDropdown (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | RemovedFocus
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | PressedShowReactionEmojiSelector Int
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V4.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V4.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V4.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V4.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V4.Ports.NotificationPermission
    | TouchStart (Evergreen.V4.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved (Evergreen.V4.NonemptyDict.NonemptyDict Int Touch)
    | TouchEnd
    | TouchCancel
    | OnAnimationFrameDelta Duration.Duration
    | ScrolledToBottom


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V4.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V4.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V4.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V4.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) (Evergreen.V4.SecretId.SecretId Evergreen.V4.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V4.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V4.EmailAddress.EmailAddress (Result Evergreen.V4.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V4.EmailAddress.EmailAddress (Result Evergreen.V4.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V4.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V4.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V4.Pages.UserOverview.ToFrontend
