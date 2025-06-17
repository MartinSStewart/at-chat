module Evergreen.V32.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V32.ChannelName
import Evergreen.V32.Coord
import Evergreen.V32.CssPixels
import Evergreen.V32.EmailAddress
import Evergreen.V32.Emoji
import Evergreen.V32.GuildName
import Evergreen.V32.Id
import Evergreen.V32.Local
import Evergreen.V32.LocalState
import Evergreen.V32.Log
import Evergreen.V32.LoginForm
import Evergreen.V32.MessageInput
import Evergreen.V32.NonemptyDict
import Evergreen.V32.NonemptySet
import Evergreen.V32.Pages.Admin
import Evergreen.V32.Pages.UserOverview
import Evergreen.V32.PersonName
import Evergreen.V32.Ports
import Evergreen.V32.Postmark
import Evergreen.V32.RichText
import Evergreen.V32.Route
import Evergreen.V32.SecretId
import Evergreen.V32.Touch
import Evergreen.V32.TwoFactorAuthentication
import Evergreen.V32.Ui.Anim
import Evergreen.V32.User
import List.Nonempty
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V32.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) Evergreen.V32.LocalState.FrontendGuild
    , user : Evergreen.V32.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V32.Route.Route
    , windowSize : Evergreen.V32.Coord.Coord Evergreen.V32.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V32.Ports.NotificationPermission
    , pwaStatus : Evergreen.V32.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId
    , channelId : Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V32.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V32.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) Evergreen.V32.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) Evergreen.V32.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V32.SecretId.SecretId Evergreen.V32.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V32.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V32.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V32.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V32.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) Int
    | Local_DeleteMessage MessageId


type ServerChange
    = Server_SendMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V32.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) Evergreen.V32.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) Evergreen.V32.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.SecretId.SecretId Evergreen.V32.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) Evergreen.V32.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V32.LocalState.JoinGuildError
            { guildId : Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId
            , guild : Evergreen.V32.LocalState.FrontendGuild
            , owner : Evergreen.V32.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) MessageId Evergreen.V32.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) MessageId Evergreen.V32.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V32.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) LocalChange
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
    { position : Evergreen.V32.Coord.Coord Evergreen.V32.CssPixels.CssPixels
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
    { guildId : Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId
    , channelId : Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V32.NonemptySet.NonemptySet Int)
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
    { localState : Evergreen.V32.Local.Local LocalMsg Evergreen.V32.LocalState.LocalState
    , admin : Maybe Evergreen.V32.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId, Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId, Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId, Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V32.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId, Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId, Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V32.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V32.SecretId.SecretId Evergreen.V32.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V32.NonemptyDict.NonemptyDict Int Evergreen.V32.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V32.NonemptyDict.NonemptyDict Int Evergreen.V32.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V32.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V32.Coord.Coord Evergreen.V32.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V32.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V32.Ports.NotificationPermission
    , pwaStatus : Evergreen.V32.Ports.PwaStatus
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
    , userId : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V32.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V32.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V32.NonemptyDict.NonemptyDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V32.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V32.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) Evergreen.V32.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V32.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V32.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V32.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V32.Route.Route
    | UserOverviewMsg Evergreen.V32.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V32.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V32.Coord.Coord Evergreen.V32.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V32.Coord.Coord Evergreen.V32.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V32.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V32.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V32.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V32.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V32.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V32.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V32.NonemptyDict.NonemptyDict Int Evergreen.V32.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V32.NonemptyDict.NonemptyDict Int Evergreen.V32.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V32.Coord.Coord Evergreen.V32.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V32.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V32.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V32.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V32.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) (Evergreen.V32.SecretId.SecretId Evergreen.V32.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V32.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V32.EmailAddress.EmailAddress (Result Evergreen.V32.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V32.EmailAddress.EmailAddress (Result Evergreen.V32.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V32.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V32.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V32.Pages.UserOverview.ToFrontend
