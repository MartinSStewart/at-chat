module Evergreen.V22.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V22.ChannelName
import Evergreen.V22.Coord
import Evergreen.V22.CssPixels
import Evergreen.V22.EmailAddress
import Evergreen.V22.Emoji
import Evergreen.V22.GuildName
import Evergreen.V22.Id
import Evergreen.V22.Local
import Evergreen.V22.LocalState
import Evergreen.V22.Log
import Evergreen.V22.LoginForm
import Evergreen.V22.MessageInput
import Evergreen.V22.NonemptyDict
import Evergreen.V22.NonemptySet
import Evergreen.V22.Pages.Admin
import Evergreen.V22.Pages.UserOverview
import Evergreen.V22.PersonName
import Evergreen.V22.Point2d
import Evergreen.V22.Ports
import Evergreen.V22.Postmark
import Evergreen.V22.RichText
import Evergreen.V22.Route
import Evergreen.V22.SecretId
import Evergreen.V22.TwoFactorAuthentication
import Evergreen.V22.Ui.Anim
import Evergreen.V22.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V22.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.LocalState.FrontendGuild
    , user : Evergreen.V22.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V22.Route.Route
    , windowSize : Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V22.Ports.NotificationPermission
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId
    , channelId : Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V22.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) Evergreen.V22.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V22.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V22.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V22.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) Int


type ServerChange
    = Server_SendMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) Evergreen.V22.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V22.LocalState.JoinGuildError
            { guildId : Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId
            , guild : Evergreen.V22.LocalState.FrontendGuild
            , owner : Evergreen.V22.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) MessageId Evergreen.V22.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) MessageId Evergreen.V22.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) LocalChange
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
    { guildId : Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId
    , channelId : Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V22.NonemptySet.NonemptySet Int)
    }


type alias LoggedIn2 =
    { localState : Evergreen.V22.Local.Local LocalMsg Evergreen.V22.LocalState.LocalState
    , admin : Maybe Evergreen.V22.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId, Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId, Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId, Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V22.MessageInput.MentionUserDropdown
    , messageHover : Maybe MessageId
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId, Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId, Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarOffset : Float
    , sidebarPreviousOffset : Float
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V22.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V22.Point2d.Point2d Evergreen.V22.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V22.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V22.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V22.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V22.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V22.Ports.NotificationPermission
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
    , userId : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V22.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V22.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V22.NonemptyDict.NonemptyDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V22.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V22.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V22.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V22.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V22.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V22.Route.Route
    | UserOverviewMsg Evergreen.V22.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V22.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) Int
    | SetFocus
    | PressedArrowInDropdown (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | PressedShowReactionEmojiSelector Int
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V22.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V22.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V22.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V22.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V22.Ports.NotificationPermission
    | TouchStart (Evergreen.V22.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved (Evergreen.V22.NonemptyDict.NonemptyDict Int Touch)
    | TouchEnd
    | TouchCancel
    | OnAnimationFrameDelta Duration.Duration
    | ScrolledToBottom
    | PressedChannelHeaderBackButton


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V22.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V22.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V22.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V22.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V22.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V22.EmailAddress.EmailAddress (Result Evergreen.V22.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V22.EmailAddress.EmailAddress (Result Evergreen.V22.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V22.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V22.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V22.Pages.UserOverview.ToFrontend
