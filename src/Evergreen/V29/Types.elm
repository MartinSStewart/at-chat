module Evergreen.V29.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V29.ChannelName
import Evergreen.V29.Coord
import Evergreen.V29.CssPixels
import Evergreen.V29.EmailAddress
import Evergreen.V29.Emoji
import Evergreen.V29.GuildName
import Evergreen.V29.Id
import Evergreen.V29.Local
import Evergreen.V29.LocalState
import Evergreen.V29.Log
import Evergreen.V29.LoginForm
import Evergreen.V29.MessageInput
import Evergreen.V29.NonemptyDict
import Evergreen.V29.NonemptySet
import Evergreen.V29.Pages.Admin
import Evergreen.V29.Pages.UserOverview
import Evergreen.V29.PersonName
import Evergreen.V29.Point2d
import Evergreen.V29.Ports
import Evergreen.V29.Postmark
import Evergreen.V29.RichText
import Evergreen.V29.Route
import Evergreen.V29.SecretId
import Evergreen.V29.TwoFactorAuthentication
import Evergreen.V29.Ui.Anim
import Evergreen.V29.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V29.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.LocalState.FrontendGuild
    , user : Evergreen.V29.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V29.Route.Route
    , windowSize : Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V29.Ports.NotificationPermission
    , pwaStatus : Evergreen.V29.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId
    , channelId : Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V29.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) Evergreen.V29.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V29.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V29.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V29.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) Int
    | Local_DeleteMessage MessageId


type ServerChange
    = Server_SendMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) Evergreen.V29.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V29.LocalState.JoinGuildError
            { guildId : Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId
            , guild : Evergreen.V29.LocalState.FrontendGuild
            , owner : Evergreen.V29.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) MessageId Evergreen.V29.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) MessageId Evergreen.V29.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) LocalChange
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
    { position : Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels
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
    { guildId : Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId
    , channelId : Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V29.NonemptySet.NonemptySet Int)
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
    { localState : Evergreen.V29.Local.Local LocalMsg Evergreen.V29.LocalState.LocalState
    , admin : Maybe Evergreen.V29.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V29.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V29.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
        }


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V29.Point2d.Point2d Evergreen.V29.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }


type Drag
    = NoDrag
    | DragStart (Evergreen.V29.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V29.NonemptyDict.NonemptyDict Int Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V29.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V29.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V29.Ports.NotificationPermission
    , pwaStatus : Evergreen.V29.Ports.PwaStatus
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
    , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V29.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V29.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V29.NonemptyDict.NonemptyDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V29.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V29.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V29.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V29.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V29.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V29.Route.Route
    | UserOverviewMsg Evergreen.V29.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V29.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V29.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V29.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V29.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V29.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V29.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V29.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V29.NonemptyDict.NonemptyDict Int Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V29.NonemptyDict.NonemptyDict Int Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V29.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V29.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V29.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V29.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V29.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V29.EmailAddress.EmailAddress (Result Evergreen.V29.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V29.EmailAddress.EmailAddress (Result Evergreen.V29.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V29.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V29.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V29.Pages.UserOverview.ToFrontend
