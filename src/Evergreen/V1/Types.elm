module Evergreen.V1.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Evergreen.V1.ChannelName
import Evergreen.V1.Coord
import Evergreen.V1.CssPixels
import Evergreen.V1.EmailAddress
import Evergreen.V1.Emoji
import Evergreen.V1.GuildName
import Evergreen.V1.Id
import Evergreen.V1.Local
import Evergreen.V1.LocalState
import Evergreen.V1.Log
import Evergreen.V1.LoginForm
import Evergreen.V1.MessageInput
import Evergreen.V1.NonemptyDict
import Evergreen.V1.NonemptySet
import Evergreen.V1.Pages.Admin
import Evergreen.V1.Pages.UserOverview
import Evergreen.V1.PersonName
import Evergreen.V1.Ports
import Evergreen.V1.Postmark
import Evergreen.V1.RichText
import Evergreen.V1.Route
import Evergreen.V1.SecretId
import Evergreen.V1.Touch
import Evergreen.V1.TwoFactorAuthentication
import Evergreen.V1.Ui.Anim
import Evergreen.V1.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V1.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) Evergreen.V1.LocalState.FrontendGuild
    , user : Evergreen.V1.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V1.Route.Route
    , windowSize : Evergreen.V1.Coord.Coord Evergreen.V1.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V1.Ports.NotificationPermission
    , pwaStatus : Evergreen.V1.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId
    , channelId : Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V1.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V1.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) Evergreen.V1.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) Evergreen.V1.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V1.SecretId.SecretId Evergreen.V1.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V1.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V1.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V1.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V1.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) Int
    | Local_DeleteMessage MessageId


type ServerChange
    = Server_SendMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V1.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) Evergreen.V1.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) Evergreen.V1.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.SecretId.SecretId Evergreen.V1.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) Evergreen.V1.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V1.LocalState.JoinGuildError
            { guildId : Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId
            , guild : Evergreen.V1.LocalState.FrontendGuild
            , owner : Evergreen.V1.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) MessageId Evergreen.V1.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) MessageId Evergreen.V1.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V1.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) MessageId


type LocalMsg
    = LocalChange (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V1.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V1.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V1.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V1.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V1.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V1.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V1.Coord.Coord Evergreen.V1.CssPixels.CssPixels
    , messageId : MessageId
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover MessageId
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction MessageId
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    }


type alias RevealedSpoilers =
    { guildId : Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId
    , channelId : Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V1.NonemptySet.NonemptySet Int)
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
    { localState : Evergreen.V1.Local.Local LocalMsg Evergreen.V1.LocalState.LocalState
    , admin : Maybe Evergreen.V1.Pages.Admin.Model
    , userOverview : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.Pages.UserOverview.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId, Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId, Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId, Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V1.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId, Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId, Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V1.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V1.SecretId.SecretId Evergreen.V1.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V1.NonemptyDict.NonemptyDict Int Evergreen.V1.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V1.NonemptyDict.NonemptyDict Int Evergreen.V1.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V1.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V1.Coord.Coord Evergreen.V1.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V1.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V1.Ports.NotificationPermission
    , pwaStatus : Evergreen.V1.Ports.PwaStatus
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
    , userId : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V1.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V1.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V1.NonemptyDict.NonemptyDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V1.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V1.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) Evergreen.V1.LocalState.BackendGuild
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V1.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V1.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V1.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V1.Route.Route
    | UserOverviewMsg Evergreen.V1.Pages.UserOverview.Msg
    | TypedMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V1.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V1.Coord.Coord Evergreen.V1.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V1.Coord.Coord Evergreen.V1.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V1.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V1.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V1.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V1.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V1.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V1.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V1.NonemptyDict.NonemptyDict Int Evergreen.V1.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V1.NonemptyDict.NonemptyDict Int Evergreen.V1.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | ScrolledToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled
        { scrolledToBottomOfChannel : Bool
        }
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V1.Coord.Coord Evergreen.V1.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V1.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V1.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V1.Local.ChangeId LocalChange
    | UserOverviewToBackend Evergreen.V1.Pages.UserOverview.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) (Evergreen.V1.SecretId.SecretId Evergreen.V1.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V1.PersonName.PersonName


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V1.EmailAddress.EmailAddress (Result Evergreen.V1.Postmark.SendEmailError ())
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V1.EmailAddress.EmailAddress (Result Evergreen.V1.Postmark.SendEmailError ())


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
    | AdminToFrontend Evergreen.V1.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V1.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Evergreen.V1.Pages.UserOverview.ToFrontend
