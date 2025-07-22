module Evergreen.V14.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V14.AiChat
import Evergreen.V14.ChannelName
import Evergreen.V14.Coord
import Evergreen.V14.CssPixels
import Evergreen.V14.Discord
import Evergreen.V14.Discord.Id
import Evergreen.V14.EmailAddress
import Evergreen.V14.Emoji
import Evergreen.V14.GuildName
import Evergreen.V14.Id
import Evergreen.V14.Local
import Evergreen.V14.LocalState
import Evergreen.V14.Log
import Evergreen.V14.LoginForm
import Evergreen.V14.MessageInput
import Evergreen.V14.NonemptyDict
import Evergreen.V14.NonemptySet
import Evergreen.V14.OneToOne
import Evergreen.V14.Pages.Admin
import Evergreen.V14.PersonName
import Evergreen.V14.Ports
import Evergreen.V14.Postmark
import Evergreen.V14.RichText
import Evergreen.V14.Route
import Evergreen.V14.SecretId
import Evergreen.V14.Touch
import Evergreen.V14.TwoFactorAuthentication
import Evergreen.V14.Ui.Anim
import Evergreen.V14.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V14.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) Evergreen.V14.LocalState.FrontendGuild
    , user : Evergreen.V14.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V14.Route.Route
    , windowSize : Evergreen.V14.Coord.Coord Evergreen.V14.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V14.Ports.NotificationPermission
    , pwaStatus : Evergreen.V14.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId
    , channelId : Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V14.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V14.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) Evergreen.V14.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) Evergreen.V14.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V14.SecretId.SecretId Evergreen.V14.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V14.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V14.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V14.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V14.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) Int
    | Local_DeleteMessage MessageId
    | Local_SetDiscordWebsocket Evergreen.V14.LocalState.IsEnabled
    | Local_ViewChannel (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)


type ServerChange
    = Server_SendMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V14.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) Evergreen.V14.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) Evergreen.V14.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.SecretId.SecretId Evergreen.V14.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) Evergreen.V14.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V14.LocalState.JoinGuildError
            { guildId : Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId
            , guild : Evergreen.V14.LocalState.FrontendGuild
            , owner : Evergreen.V14.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) MessageId Evergreen.V14.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) MessageId Evergreen.V14.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V14.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) MessageId
    | Server_DiscordDeleteMessage MessageId
    | Server_SetWebsocketToggled Evergreen.V14.LocalState.IsEnabled


type LocalMsg
    = LocalChange (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V14.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V14.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V14.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V14.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V14.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V14.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V14.Coord.Coord Evergreen.V14.CssPixels.CssPixels
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
    { guildId : Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId
    , channelId : Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V14.NonemptySet.NonemptySet Int)
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
    { localState : Evergreen.V14.Local.Local LocalMsg Evergreen.V14.LocalState.LocalState
    , admin : Maybe Evergreen.V14.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId, Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId, Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId, Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V14.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId, Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId, Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , showUserOptions : Bool
    , twoFactor : Evergreen.V14.TwoFactorAuthentication.TwoFactorState
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V14.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V14.SecretId.SecretId Evergreen.V14.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V14.NonemptyDict.NonemptyDict Int Evergreen.V14.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V14.NonemptyDict.NonemptyDict Int Evergreen.V14.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V14.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V14.Coord.Coord Evergreen.V14.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V14.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V14.Ports.NotificationPermission
    , pwaStatus : Evergreen.V14.Ports.PwaStatus
    , drag : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V14.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V14.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V14.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V14.NonemptyDict.NonemptyDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V14.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V14.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) Evergreen.V14.LocalState.BackendGuild
    , discordModel : Evergreen.V14.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V14.OneToOne.OneToOne (Evergreen.V14.Discord.Id.Id Evergreen.V14.Discord.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId)
    , discordUsers : Evergreen.V14.OneToOne.OneToOne (Evergreen.V14.Discord.Id.Id Evergreen.V14.Discord.Id.UserId) (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , discordBotId : Maybe (Evergreen.V14.Discord.Id.Id Evergreen.V14.Discord.Id.UserId)
    , websocketEnabled : Evergreen.V14.LocalState.IsEnabled
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V14.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V14.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V14.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V14.Route.Route
    | TypedMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V14.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V14.Coord.Coord Evergreen.V14.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V14.Coord.Coord Evergreen.V14.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V14.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V14.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V14.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V14.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V14.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V14.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V14.NonemptyDict.NonemptyDict Int Evergreen.V14.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V14.NonemptyDict.NonemptyDict Int Evergreen.V14.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V14.Coord.Coord Evergreen.V14.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedSetDiscordWebsocket Evergreen.V14.LocalState.IsEnabled
    | TwoFactorMsg Evergreen.V14.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V14.AiChat.FrontendMsg


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V14.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V14.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V14.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V14.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.SecretId.SecretId Evergreen.V14.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V14.PersonName.PersonName
    | AiChatToBackend Evergreen.V14.AiChat.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V14.EmailAddress.EmailAddress (Result Evergreen.V14.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V14.EmailAddress.EmailAddress (Result Evergreen.V14.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V14.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix (Result Evergreen.V14.Discord.HttpError (List Evergreen.V14.Discord.PartialGuild))
    | GotCurrentUser (Result Evergreen.V14.Discord.HttpError Evergreen.V14.Discord.User)
    | GotDiscordGuilds Effect.Time.Posix (Result Evergreen.V14.Discord.HttpError (List ( Evergreen.V14.Discord.Id.Id Evergreen.V14.Discord.Id.GuildId, ( Evergreen.V14.Discord.Guild, List Evergreen.V14.Discord.GuildMember, List Evergreen.V14.Discord.Channel2 ) )))
    | SentMessageToDiscord MessageId (Result Evergreen.V14.Discord.HttpError Evergreen.V14.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V14.AiChat.BackendMsg


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
    | AdminToFrontend Evergreen.V14.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V14.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V14.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V14.AiChat.ToFrontend
