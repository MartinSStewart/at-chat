module Evergreen.V3.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V3.AiChat
import Evergreen.V3.ChannelName
import Evergreen.V3.Coord
import Evergreen.V3.CssPixels
import Evergreen.V3.Discord
import Evergreen.V3.Discord.Id
import Evergreen.V3.EmailAddress
import Evergreen.V3.Emoji
import Evergreen.V3.GuildName
import Evergreen.V3.Id
import Evergreen.V3.Local
import Evergreen.V3.LocalState
import Evergreen.V3.Log
import Evergreen.V3.LoginForm
import Evergreen.V3.MessageInput
import Evergreen.V3.NonemptyDict
import Evergreen.V3.NonemptySet
import Evergreen.V3.OneToOne
import Evergreen.V3.Pages.Admin
import Evergreen.V3.PersonName
import Evergreen.V3.Ports
import Evergreen.V3.Postmark
import Evergreen.V3.RichText
import Evergreen.V3.Route
import Evergreen.V3.SecretId
import Evergreen.V3.Touch
import Evergreen.V3.TwoFactorAuthentication
import Evergreen.V3.Ui.Anim
import Evergreen.V3.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V3.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) Evergreen.V3.LocalState.FrontendGuild
    , user : Evergreen.V3.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V3.Route.Route
    , windowSize : Evergreen.V3.Coord.Coord Evergreen.V3.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V3.Ports.NotificationPermission
    , pwaStatus : Evergreen.V3.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias MessageId =
    { guildId : Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId
    , channelId : Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId
    , messageIndex : Int
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V3.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V3.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) Evergreen.V3.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) Evergreen.V3.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V3.SecretId.SecretId Evergreen.V3.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V3.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | Local_AddReactionEmoji MessageId Evergreen.V3.Emoji.Emoji
    | Local_RemoveReactionEmoji MessageId Evergreen.V3.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix MessageId (List.Nonempty.Nonempty Evergreen.V3.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix MessageId
    | Local_SetLastViewed (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) Int
    | Local_DeleteMessage MessageId
    | Local_SetDiscordWebsocket Evergreen.V3.LocalState.IsEnabled
    | Local_ViewChannel (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)


type ServerChange
    = Server_SendMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) (List.Nonempty.Nonempty Evergreen.V3.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) Evergreen.V3.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) Evergreen.V3.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.SecretId.SecretId Evergreen.V3.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) Evergreen.V3.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V3.LocalState.JoinGuildError
            { guildId : Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId
            , guild : Evergreen.V3.LocalState.FrontendGuild
            , owner : Evergreen.V3.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | Server_AddReactionEmoji (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) MessageId Evergreen.V3.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) MessageId Evergreen.V3.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) MessageId (List.Nonempty.Nonempty Evergreen.V3.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) MessageId
    | Server_DeleteMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) MessageId
    | Server_DiscordDeleteMessage MessageId
    | Server_SetWebsocketToggled Evergreen.V3.LocalState.IsEnabled


type LocalMsg
    = LocalChange (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V3.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V3.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V3.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V3.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V3.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V3.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V3.Coord.Coord Evergreen.V3.CssPixels.CssPixels
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
    { guildId : Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId
    , channelId : Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId
    , messages : SeqDict.SeqDict Int (Evergreen.V3.NonemptySet.NonemptySet Int)
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
    { localState : Evergreen.V3.Local.Local LocalMsg Evergreen.V3.LocalState.LocalState
    , admin : Maybe Evergreen.V3.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId, Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId, Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId, Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V3.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId, Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId, Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId ) Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , showUserOptions : Bool
    , twoFactor : Evergreen.V3.TwoFactorAuthentication.TwoFactorState
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V3.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V3.SecretId.SecretId Evergreen.V3.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V3.NonemptyDict.NonemptyDict Int Evergreen.V3.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V3.NonemptyDict.NonemptyDict Int Evergreen.V3.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V3.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V3.Coord.Coord Evergreen.V3.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V3.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V3.Ports.NotificationPermission
    , pwaStatus : Evergreen.V3.Ports.PwaStatus
    , drag : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V3.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V3.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V3.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V3.NonemptyDict.NonemptyDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V3.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V3.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) Evergreen.V3.LocalState.BackendGuild
    , discordModel : Evergreen.V3.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V3.OneToOne.OneToOne (Evergreen.V3.Discord.Id.Id Evergreen.V3.Discord.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId)
    , discordUsers : Evergreen.V3.OneToOne.OneToOne (Evergreen.V3.Discord.Id.Id Evergreen.V3.Discord.Id.UserId) (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
    , discordBotId : Maybe (Evergreen.V3.Discord.Id.Id Evergreen.V3.Discord.Id.UserId)
    , websocketEnabled : Evergreen.V3.LocalState.IsEnabled
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V3.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V3.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V3.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V3.Route.Route
    | TypedMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) String
    | PressedSendMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | NewChannelFormChanged (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V3.MessageInput.MentionUserDropdown)
    | PressedPingUser (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V3.Coord.Coord Evergreen.V3.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V3.Coord.Coord Evergreen.V3.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V3.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V3.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V3.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V3.MessageInput.MentionUserDropdown)
    | TypedEditMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) String
    | PressedSendEditMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | PressedArrowInDropdownForEditMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) Int
    | PressedPingUserForEditMessage (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) Int
    | PressedArrowUpInEmptyInput (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V3.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V3.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V3.NonemptyDict.NonemptyDict Int Evergreen.V3.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V3.NonemptyDict.NonemptyDict Int Evergreen.V3.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V3.Coord.Coord Evergreen.V3.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage MessageId
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedSetDiscordWebsocket Evergreen.V3.LocalState.IsEnabled
    | TwoFactorMsg Evergreen.V3.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V3.AiChat.FrontendMsg


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V3.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V3.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V3.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V3.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) (Evergreen.V3.SecretId.SecretId Evergreen.V3.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V3.PersonName.PersonName
    | AiChatToBackend Evergreen.V3.AiChat.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V3.EmailAddress.EmailAddress (Result Evergreen.V3.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V3.EmailAddress.EmailAddress (Result Evergreen.V3.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V3.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix (Result Evergreen.V3.Discord.HttpError (List Evergreen.V3.Discord.PartialGuild))
    | GotCurrentUser (Result Evergreen.V3.Discord.HttpError Evergreen.V3.Discord.User)
    | GotDiscordGuilds Effect.Time.Posix (Result Evergreen.V3.Discord.HttpError (List ( Evergreen.V3.Discord.Id.Id Evergreen.V3.Discord.Id.GuildId, ( Evergreen.V3.Discord.Guild, List Evergreen.V3.Discord.GuildMember, List Evergreen.V3.Discord.Channel2 ) )))
    | SentMessageToDiscord MessageId (Result Evergreen.V3.Discord.HttpError Evergreen.V3.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V3.AiChat.BackendMsg


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
    | AdminToFrontend Evergreen.V3.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V3.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V3.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V3.AiChat.ToFrontend
