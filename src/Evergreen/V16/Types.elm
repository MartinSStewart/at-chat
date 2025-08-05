module Evergreen.V16.Types exposing (..)

import Array
import Browser
import Bytes
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V16.AiChat
import Evergreen.V16.ChannelName
import Evergreen.V16.Coord
import Evergreen.V16.CssPixels
import Evergreen.V16.Discord
import Evergreen.V16.Discord.Id
import Evergreen.V16.DmChannel
import Evergreen.V16.Editable
import Evergreen.V16.EmailAddress
import Evergreen.V16.Emoji
import Evergreen.V16.GuildName
import Evergreen.V16.Id
import Evergreen.V16.Local
import Evergreen.V16.LocalState
import Evergreen.V16.Log
import Evergreen.V16.LoginForm
import Evergreen.V16.MessageInput
import Evergreen.V16.NonemptyDict
import Evergreen.V16.NonemptySet
import Evergreen.V16.OneToOne
import Evergreen.V16.Pages.Admin
import Evergreen.V16.PersonName
import Evergreen.V16.Ports
import Evergreen.V16.Postmark
import Evergreen.V16.RichText
import Evergreen.V16.Route
import Evergreen.V16.SecretId
import Evergreen.V16.Touch
import Evergreen.V16.TwoFactorAuthentication
import Evergreen.V16.Ui.Anim
import Evergreen.V16.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V16.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) Evergreen.V16.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.DmChannel.DmChannel
    , user : Evergreen.V16.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V16.Route.Route
    , windowSize : Evergreen.V16.Coord.Coord Evergreen.V16.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V16.Ports.NotificationPermission
    , pwaStatus : Evergreen.V16.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V16.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V16.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V16.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) Evergreen.V16.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId) Evergreen.V16.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V16.SecretId.SecretId Evergreen.V16.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V16.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V16.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V16.User.GuildOrDmId Int Evergreen.V16.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V16.User.GuildOrDmId Int Evergreen.V16.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V16.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V16.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V16.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V16.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V16.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | Local_SetName Evergreen.V16.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId
    , channelId : Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Effect.Time.Posix Evergreen.V16.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V16.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) Evergreen.V16.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId) Evergreen.V16.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.SecretId.SecretId Evergreen.V16.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) Evergreen.V16.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V16.LocalState.JoinGuildError
            { guildId : Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId
            , guild : Evergreen.V16.LocalState.FrontendGuild
            , owner : Evergreen.V16.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.GuildOrDmId Int Evergreen.V16.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.GuildOrDmId Int Evergreen.V16.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V16.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.MessageId) (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (List.Nonempty.Nonempty Evergreen.V16.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V16.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V16.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V16.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V16.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V16.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V16.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V16.Coord.Coord Evergreen.V16.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V16.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V16.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V16.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V16.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V16.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V16.Editable.Model
    , botToken : Evergreen.V16.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V16.Local.Local LocalMsg Evergreen.V16.LocalState.LocalState
    , admin : Maybe Evergreen.V16.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V16.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId, Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId, Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V16.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V16.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V16.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V16.TwoFactorAuthentication.TwoFactorState
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V16.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V16.SecretId.SecretId Evergreen.V16.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V16.NonemptyDict.NonemptyDict Int Evergreen.V16.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V16.NonemptyDict.NonemptyDict Int Evergreen.V16.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V16.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V16.Coord.Coord Evergreen.V16.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V16.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V16.Ports.NotificationPermission
    , pwaStatus : Evergreen.V16.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V16.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V16.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V16.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V16.NonemptyDict.NonemptyDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V16.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V16.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) Evergreen.V16.LocalState.BackendGuild
    , discordModel : Evergreen.V16.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V16.OneToOne.OneToOne (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId)
    , discordUsers : Evergreen.V16.OneToOne.OneToOne (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.UserId) (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , discordBotId : Maybe (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V16.DmChannel.DmChannelId Evergreen.V16.DmChannel.DmChannel
    , discordDms : Evergreen.V16.OneToOne.OneToOne (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.ChannelId) Evergreen.V16.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V16.LocalState.DiscordBotToken
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V16.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V16.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V16.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V16.Route.Route
    | TypedMessage Evergreen.V16.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V16.User.GuildOrDmId
    | NewChannelFormChanged (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V16.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V16.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V16.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V16.Coord.Coord Evergreen.V16.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V16.Coord.Coord Evergreen.V16.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V16.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V16.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V16.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V16.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V16.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V16.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V16.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V16.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V16.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V16.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V16.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V16.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V16.NonemptyDict.NonemptyDict Int Evergreen.V16.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V16.NonemptyDict.NonemptyDict Int Evergreen.V16.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V16.Coord.Coord Evergreen.V16.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V16.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V16.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V16.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V16.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V16.Editable.Msg Evergreen.V16.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V16.Editable.Msg (Maybe Evergreen.V16.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V16.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V16.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V16.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V16.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.SecretId.SecretId Evergreen.V16.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V16.PersonName.PersonName
    | AiChatToBackend Evergreen.V16.AiChat.ToBackend
    | ReloadDataRequest
    | UploadImageRequest Bytes.Bytes


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V16.EmailAddress.EmailAddress (Result Evergreen.V16.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V16.EmailAddress.EmailAddress (Result Evergreen.V16.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V16.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V16.LocalState.DiscordBotToken (Result Evergreen.V16.Discord.HttpError ( Evergreen.V16.Discord.User, List Evergreen.V16.Discord.PartialGuild ))
    | GotDiscordGuilds Effect.Time.Posix (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.UserId) (Result Evergreen.V16.Discord.HttpError (List ( Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.GuildId, ( Evergreen.V16.Discord.Guild, List Evergreen.V16.Discord.GuildMember, List Evergreen.V16.Discord.Channel2 ) )))
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V16.Discord.HttpError Evergreen.V16.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V16.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V16.DmChannel.DmChannelId Int (Result Evergreen.V16.Discord.HttpError Evergreen.V16.Discord.Message)


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
    | AdminToFrontend Evergreen.V16.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V16.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V16.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V16.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
