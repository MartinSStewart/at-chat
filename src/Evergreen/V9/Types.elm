module Evergreen.V9.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V9.AiChat
import Evergreen.V9.ChannelName
import Evergreen.V9.Coord
import Evergreen.V9.CssPixels
import Evergreen.V9.Discord
import Evergreen.V9.Discord.Id
import Evergreen.V9.EmailAddress
import Evergreen.V9.Emoji
import Evergreen.V9.GuildName
import Evergreen.V9.Id
import Evergreen.V9.Local
import Evergreen.V9.LocalState
import Evergreen.V9.Log
import Evergreen.V9.LoginForm
import Evergreen.V9.MessageInput
import Evergreen.V9.NonemptyDict
import Evergreen.V9.NonemptySet
import Evergreen.V9.OneToOne
import Evergreen.V9.Pages.Admin
import Evergreen.V9.PersonName
import Evergreen.V9.Ports
import Evergreen.V9.Postmark
import Evergreen.V9.RichText
import Evergreen.V9.Route
import Evergreen.V9.SecretId
import Evergreen.V9.Touch
import Evergreen.V9.TwoFactorAuthentication
import Evergreen.V9.Ui.Anim
import Evergreen.V9.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V9.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) Evergreen.V9.LocalState.FrontendGuild
    , user : Evergreen.V9.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V9.Route.Route
    , windowSize : Evergreen.V9.Coord.Coord Evergreen.V9.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V9.Ports.NotificationPermission
    , pwaStatus : Evergreen.V9.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId
    , channelId : Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V9.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V9.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) Evergreen.V9.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) Evergreen.V9.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V9.SecretId.SecretId Evergreen.V9.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V9.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V9.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V9.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V9.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) Int
    | Local_DeleteMessage MessageId
    | Local_SetDiscordWebsocket Evergreen.V9.LocalState.IsEnabled
    | Local_ViewChannel (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)


type ServerChange
    = Server_SendMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V9.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) Evergreen.V9.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) Evergreen.V9.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.SecretId.SecretId Evergreen.V9.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) Evergreen.V9.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V9.LocalState.JoinGuildError
            { guildId : Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId
            , guild : Evergreen.V9.LocalState.FrontendGuild
            , owner : Evergreen.V9.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) MessageId Evergreen.V9.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) MessageId Evergreen.V9.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V9.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) MessageId
    | Server_DiscordDeleteMessage MessageId
    | Server_SetWebsocketToggled Evergreen.V9.LocalState.IsEnabled


type LocalMsg
    = LocalChange (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V9.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V9.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V9.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V9.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V9.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V9.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V9.Coord.Coord Evergreen.V9.CssPixels.CssPixels
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
    { guildId : Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId
    , channelId : Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V9.NonemptySet.NonemptySet Int)
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
    { localState : Evergreen.V9.Local.Local LocalMsg Evergreen.V9.LocalState.LocalState
    , admin : Maybe Evergreen.V9.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId, Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId, Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId, Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V9.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId, Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId, Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , showUserOptions : Bool
    , twoFactor : Evergreen.V9.TwoFactorAuthentication.TwoFactorState
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V9.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V9.SecretId.SecretId Evergreen.V9.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V9.NonemptyDict.NonemptyDict Int Evergreen.V9.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V9.NonemptyDict.NonemptyDict Int Evergreen.V9.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V9.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V9.Coord.Coord Evergreen.V9.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V9.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V9.Ports.NotificationPermission
    , pwaStatus : Evergreen.V9.Ports.PwaStatus
    , drag : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V9.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V9.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V9.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V9.NonemptyDict.NonemptyDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V9.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V9.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) Evergreen.V9.LocalState.BackendGuild
    , discordModel : Evergreen.V9.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V9.OneToOne.OneToOne (Evergreen.V9.Discord.Id.Id Evergreen.V9.Discord.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId)
    , discordUsers : Evergreen.V9.OneToOne.OneToOne (Evergreen.V9.Discord.Id.Id Evergreen.V9.Discord.Id.UserId) (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , discordBotId : Maybe (Evergreen.V9.Discord.Id.Id Evergreen.V9.Discord.Id.UserId)
    , websocketEnabled : Evergreen.V9.LocalState.IsEnabled
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V9.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V9.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V9.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V9.Route.Route
    | TypedMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V9.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V9.Coord.Coord Evergreen.V9.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V9.Coord.Coord Evergreen.V9.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V9.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V9.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V9.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V9.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V9.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V9.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V9.NonemptyDict.NonemptyDict Int Evergreen.V9.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V9.NonemptyDict.NonemptyDict Int Evergreen.V9.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V9.Coord.Coord Evergreen.V9.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedSetDiscordWebsocket Evergreen.V9.LocalState.IsEnabled
    | TwoFactorMsg Evergreen.V9.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V9.AiChat.FrontendMsg


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V9.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V9.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V9.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V9.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.SecretId.SecretId Evergreen.V9.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V9.PersonName.PersonName
    | AiChatToBackend Evergreen.V9.AiChat.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V9.EmailAddress.EmailAddress (Result Evergreen.V9.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V9.EmailAddress.EmailAddress (Result Evergreen.V9.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V9.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix (Result Evergreen.V9.Discord.HttpError (List Evergreen.V9.Discord.PartialGuild))
    | GotCurrentUser (Result Evergreen.V9.Discord.HttpError Evergreen.V9.Discord.User)
    | GotDiscordGuilds Effect.Time.Posix (Result Evergreen.V9.Discord.HttpError (List ( Evergreen.V9.Discord.Id.Id Evergreen.V9.Discord.Id.GuildId, ( Evergreen.V9.Discord.Guild, List Evergreen.V9.Discord.GuildMember, List Evergreen.V9.Discord.Channel2 ) )))
    | SentMessageToDiscord MessageId (Result Evergreen.V9.Discord.HttpError Evergreen.V9.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V9.AiChat.BackendMsg


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
    | AdminToFrontend Evergreen.V9.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V9.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V9.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V9.AiChat.ToFrontend
