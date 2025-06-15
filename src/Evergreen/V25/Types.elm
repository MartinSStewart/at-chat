module Evergreen.V25.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V25.ChannelName
import Evergreen.V25.Coord
import Evergreen.V25.CssPixels
import Evergreen.V25.EmailAddress
import Evergreen.V25.Emoji
import Evergreen.V25.GuildName
import Evergreen.V25.Id
import Evergreen.V25.Local
import Evergreen.V25.LocalState
import Evergreen.V25.Log
import Evergreen.V25.LoginForm
import Evergreen.V25.MessageInput
import Evergreen.V25.NonemptyDict
import Evergreen.V25.NonemptySet
import Evergreen.V25.Pages.Admin
import Evergreen.V25.Pages.UserOverview
import Evergreen.V25.PersonName
import Evergreen.V25.Point2d
import Evergreen.V25.Ports
import Evergreen.V25.Postmark
import Evergreen.V25.RichText
import Evergreen.V25.Route
import Evergreen.V25.SecretId
import Evergreen.V25.TwoFactorAuthentication
import Evergreen.V25.Ui.Anim
import Evergreen.V25.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V25.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) Evergreen.V25.LocalState.FrontendGuild
    , user : Evergreen.V25.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V25.Route.Route
    , windowSize : Evergreen.V25.Coord.Coord Evergreen.V25.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V25.Ports.NotificationPermission
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId
    , channelId : Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V25.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V25.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) Evergreen.V25.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) Evergreen.V25.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V25.SecretId.SecretId Evergreen.V25.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V25.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V25.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V25.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V25.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) Int
    | Local_DeleteMessage MessageId


type ServerChange
    = Server_SendMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V25.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) Evergreen.V25.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) Evergreen.V25.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.SecretId.SecretId Evergreen.V25.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) Evergreen.V25.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V25.LocalState.JoinGuildError
            { guildId : Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId
            , guild : Evergreen.V25.LocalState.FrontendGuild
            , owner : Evergreen.V25.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) MessageId Evergreen.V25.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) MessageId Evergreen.V25.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V25.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias MessageHoverExtraOptions =
    { position : Evergreen.V25.Coord.Coord Evergreen.V25.CssPixels.CssPixels
    , messageId : MessageId
    }


type MessageHover
    = NoMessageHover
    | MessageHover MessageId
    | MessageHoverShowExtraOptions MessageHoverExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction MessageId
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    }


type alias RevealedSpoilers =
    { guildId : Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId
    , channelId : Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V25.NonemptySet.NonemptySet Int)
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


type alias LoggedIn2 =
    { localState : Evergreen.V25.Local.Local LocalMsg Evergreen.V25.LocalState.LocalState
    , admin : Maybe Evergreen.V25.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId, Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId, Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId, Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V25.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId, Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId, Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V25.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V25.SecretId.SecretId Evergreen.V25.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V25.Point2d.Point2d Evergreen.V25.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V25.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V25.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V25.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V25.Coord.Coord Evergreen.V25.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V25.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V25.Ports.NotificationPermission
    , drag : Drag
    , scrolledToBottomOfChannel : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V25.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V25.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V25.NonemptyDict.NonemptyDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V25.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V25.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) Evergreen.V25.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V25.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V25.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V25.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V25.Route.Route
    | UserOverviewMsg Evergreen.V25.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V25.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V25.Coord.Coord Evergreen.V25.CssPixels.CssPixels)
    | PressedShowReactionEmojiSelector Int (Evergreen.V25.Coord.Coord Evergreen.V25.CssPixels.CssPixels)
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V25.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V25.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V25.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V25.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V25.Ports.NotificationPermission
    | TouchStart Effect.Time.Posix (Evergreen.V25.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V25.NonemptyDict.NonemptyDict Int Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | OnAnimationFrameDelta Duration.Duration
    | ScrolledToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled
        { scrolledToBottomOfChannel : Bool
        }
    | PressedBody
    | PressedReactionEmojiContainer
    | PressedShowMessageHoverExtraOptions Int (Evergreen.V25.Coord.Coord Evergreen.V25.CssPixels.CssPixels)
    | PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V25.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V25.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V25.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V25.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) (Evergreen.V25.SecretId.SecretId Evergreen.V25.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V25.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V25.EmailAddress.EmailAddress (Result Evergreen.V25.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V25.EmailAddress.EmailAddress (Result Evergreen.V25.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V25.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V25.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V25.Pages.UserOverview.ToFrontend
