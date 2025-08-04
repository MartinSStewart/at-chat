module Evergreen.V15.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V15.AiChat
import Evergreen.V15.ChannelName
import Evergreen.V15.Coord
import Evergreen.V15.CssPixels
import Evergreen.V15.Discord
import Evergreen.V15.Discord.Id
import Evergreen.V15.DmChannel
import Evergreen.V15.Editable
import Evergreen.V15.EmailAddress
import Evergreen.V15.Emoji
import Evergreen.V15.GuildName
import Evergreen.V15.Id
import Evergreen.V15.Local
import Evergreen.V15.LocalState
import Evergreen.V15.Log
import Evergreen.V15.LoginForm
import Evergreen.V15.MessageInput
import Evergreen.V15.NonemptyDict
import Evergreen.V15.NonemptySet
import Evergreen.V15.OneToOne
import Evergreen.V15.Pages.Admin
import Evergreen.V15.PersonName
import Evergreen.V15.Ports
import Evergreen.V15.Postmark
import Evergreen.V15.RichText
import Evergreen.V15.Route
import Evergreen.V15.SecretId
import Evergreen.V15.Touch
import Evergreen.V15.TwoFactorAuthentication
import Evergreen.V15.Ui.Anim
import Evergreen.V15.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V15.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) Evergreen.V15.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.DmChannel.DmChannel
    , user : Evergreen.V15.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V15.Route.Route
    , windowSize : Evergreen.V15.Coord.Coord Evergreen.V15.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V15.Ports.NotificationPermission
    , pwaStatus : Evergreen.V15.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V15.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V15.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V15.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) Evergreen.V15.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId) Evergreen.V15.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V15.SecretId.SecretId Evergreen.V15.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V15.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V15.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V15.User.GuildOrDmId Int Evergreen.V15.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V15.User.GuildOrDmId Int Evergreen.V15.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V15.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V15.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V15.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V15.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V15.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | Local_SetName Evergreen.V15.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId
    , channelId : Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Effect.Time.Posix Evergreen.V15.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V15.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) Evergreen.V15.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId) Evergreen.V15.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.SecretId.SecretId Evergreen.V15.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) Evergreen.V15.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V15.LocalState.JoinGuildError
            { guildId : Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId
            , guild : Evergreen.V15.LocalState.FrontendGuild
            , owner : Evergreen.V15.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.GuildOrDmId Int Evergreen.V15.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.GuildOrDmId Int Evergreen.V15.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V15.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.MessageId) (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) (List.Nonempty.Nonempty Evergreen.V15.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V15.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V15.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V15.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V15.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V15.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V15.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V15.Coord.Coord Evergreen.V15.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V15.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V15.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V15.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V15.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V15.NonemptySet.NonemptySet Int)
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


type alias UserOptionsModel =
    { name : Evergreen.V15.Editable.Model
    , botToken : Evergreen.V15.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V15.Local.Local LocalMsg Evergreen.V15.LocalState.LocalState
    , admin : Maybe Evergreen.V15.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V15.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId, Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId, Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V15.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V15.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V15.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V15.TwoFactorAuthentication.TwoFactorState
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V15.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V15.SecretId.SecretId Evergreen.V15.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V15.NonemptyDict.NonemptyDict Int Evergreen.V15.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V15.NonemptyDict.NonemptyDict Int Evergreen.V15.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V15.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V15.Coord.Coord Evergreen.V15.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V15.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V15.Ports.NotificationPermission
    , pwaStatus : Evergreen.V15.Ports.PwaStatus
    , drag : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V15.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V15.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V15.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V15.NonemptyDict.NonemptyDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V15.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V15.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) Evergreen.V15.LocalState.BackendGuild
    , discordModel : Evergreen.V15.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V15.OneToOne.OneToOne (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId)
    , discordUsers : Evergreen.V15.OneToOne.OneToOne (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.UserId) (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , discordBotId : Maybe (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V15.DmChannel.DmChannelId Evergreen.V15.DmChannel.DmChannel
    , discordDms : Evergreen.V15.OneToOne.OneToOne (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.ChannelId) Evergreen.V15.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V15.LocalState.DiscordBotToken
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V15.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V15.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V15.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V15.Route.Route
    | TypedMessage Evergreen.V15.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V15.User.GuildOrDmId
    | NewChannelFormChanged (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V15.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V15.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V15.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V15.Coord.Coord Evergreen.V15.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V15.Coord.Coord Evergreen.V15.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V15.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V15.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V15.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V15.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V15.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V15.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V15.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V15.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V15.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V15.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V15.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V15.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V15.NonemptyDict.NonemptyDict Int Evergreen.V15.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V15.NonemptyDict.NonemptyDict Int Evergreen.V15.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V15.Coord.Coord Evergreen.V15.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V15.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V15.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V15.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V15.AiChat.FrontendMsg
    | UserNameEditableMsg (Evergreen.V15.Editable.Msg Evergreen.V15.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V15.Editable.Msg (Maybe Evergreen.V15.LocalState.DiscordBotToken))


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V15.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V15.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V15.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V15.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.SecretId.SecretId Evergreen.V15.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V15.PersonName.PersonName
    | AiChatToBackend Evergreen.V15.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V15.EmailAddress.EmailAddress (Result Evergreen.V15.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V15.EmailAddress.EmailAddress (Result Evergreen.V15.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V15.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V15.LocalState.DiscordBotToken (Result Evergreen.V15.Discord.HttpError ( Evergreen.V15.Discord.User, List Evergreen.V15.Discord.PartialGuild ))
    | GotDiscordGuilds Effect.Time.Posix (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.UserId) (Result Evergreen.V15.Discord.HttpError (List ( Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.GuildId, ( Evergreen.V15.Discord.Guild, List Evergreen.V15.Discord.GuildMember, List Evergreen.V15.Discord.Channel2 ) )))
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V15.Discord.HttpError Evergreen.V15.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V15.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V15.DmChannel.DmChannelId Int (Result Evergreen.V15.Discord.HttpError Evergreen.V15.Discord.Message)


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
    | AdminToFrontend Evergreen.V15.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V15.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V15.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V15.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
