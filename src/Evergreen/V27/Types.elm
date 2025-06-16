module Evergreen.V27.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V27.ChannelName
import Evergreen.V27.Coord
import Evergreen.V27.CssPixels
import Evergreen.V27.EmailAddress
import Evergreen.V27.Emoji
import Evergreen.V27.GuildName
import Evergreen.V27.Id
import Evergreen.V27.Local
import Evergreen.V27.LocalState
import Evergreen.V27.Log
import Evergreen.V27.LoginForm
import Evergreen.V27.MessageInput
import Evergreen.V27.NonemptyDict
import Evergreen.V27.NonemptySet
import Evergreen.V27.Pages.Admin
import Evergreen.V27.Pages.UserOverview
import Evergreen.V27.PersonName
import Evergreen.V27.Point2d
import Evergreen.V27.Ports
import Evergreen.V27.Postmark
import Evergreen.V27.RichText
import Evergreen.V27.Route
import Evergreen.V27.SecretId
import Evergreen.V27.TwoFactorAuthentication
import Evergreen.V27.Ui.Anim
import Evergreen.V27.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V27.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.LocalState.FrontendGuild
    , user : Evergreen.V27.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V27.Route.Route
    , windowSize : Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V27.Ports.NotificationPermission
    , pwaStatus : Evergreen.V27.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId
    , channelId : Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V27.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) Evergreen.V27.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V27.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V27.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V27.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) Int
    | Local_DeleteMessage MessageId


type ServerChange
    = Server_SendMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) Evergreen.V27.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V27.LocalState.JoinGuildError
            { guildId : Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId
            , guild : Evergreen.V27.LocalState.FrontendGuild
            , owner : Evergreen.V27.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) MessageId Evergreen.V27.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) MessageId Evergreen.V27.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) LocalChange
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
    { position : Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels
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
    { guildId : Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId
    , channelId : Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V27.NonemptySet.NonemptySet Int)
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
    { localState : Evergreen.V27.Local.Local LocalMsg Evergreen.V27.LocalState.LocalState
    , admin : Maybe Evergreen.V27.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V27.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V27.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V27.Point2d.Point2d Evergreen.V27.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V27.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V27.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V27.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V27.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V27.Ports.NotificationPermission
    , pwaStatus : Evergreen.V27.Ports.PwaStatus
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
    , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V27.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V27.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V27.NonemptyDict.NonemptyDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V27.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V27.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V27.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V27.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V27.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V27.Route.Route
    | UserOverviewMsg Evergreen.V27.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V27.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels)
    | PressedShowReactionEmojiSelector Int (Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels)
    | PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V27.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V27.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V27.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V27.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | PressedReply Int
    | PressedCloseReplyTo (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V27.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V27.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V27.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V27.NonemptyDict.NonemptyDict Int Touch)
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
    | PressedShowMessageHoverExtraOptions Int (Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels)
    | PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage
    | PressedCloseMessageHoverExtraOptions
    | PressedMessageHoverExtraOptionsContainer


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V27.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V27.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V27.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V27.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V27.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V27.EmailAddress.EmailAddress (Result Evergreen.V27.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V27.EmailAddress.EmailAddress (Result Evergreen.V27.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V27.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V27.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V27.Pages.UserOverview.ToFrontend
