module Evergreen.V17.Types exposing (..)

import Array
import Browser
import Bytes
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V17.AiChat
import Evergreen.V17.ChannelName
import Evergreen.V17.Coord
import Evergreen.V17.CssPixels
import Evergreen.V17.Discord
import Evergreen.V17.Discord.Id
import Evergreen.V17.DmChannel
import Evergreen.V17.Editable
import Evergreen.V17.EmailAddress
import Evergreen.V17.Emoji
import Evergreen.V17.GuildName
import Evergreen.V17.Id
import Evergreen.V17.Local
import Evergreen.V17.LocalState
import Evergreen.V17.Log
import Evergreen.V17.LoginForm
import Evergreen.V17.MessageInput
import Evergreen.V17.NonemptyDict
import Evergreen.V17.NonemptySet
import Evergreen.V17.OneToOne
import Evergreen.V17.Pages.Admin
import Evergreen.V17.PersonName
import Evergreen.V17.Ports
import Evergreen.V17.Postmark
import Evergreen.V17.RichText
import Evergreen.V17.Route
import Evergreen.V17.SecretId
import Evergreen.V17.Touch
import Evergreen.V17.TwoFactorAuthentication
import Evergreen.V17.Ui.Anim
import Evergreen.V17.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V17.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) Evergreen.V17.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.DmChannel.DmChannel
    , user : Evergreen.V17.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.FrontendUser
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V17.Route.Route
    , windowSize : Evergreen.V17.Coord.Coord Evergreen.V17.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V17.Ports.NotificationPermission
    , pwaStatus : Evergreen.V17.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V17.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V17.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V17.RichText.RichText) (Maybe Int)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) Evergreen.V17.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId) Evergreen.V17.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V17.SecretId.SecretId Evergreen.V17.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V17.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V17.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V17.User.GuildOrDmId Int Evergreen.V17.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V17.User.GuildOrDmId Int Evergreen.V17.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V17.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V17.RichText.RichText)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V17.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V17.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V17.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | Local_SetName Evergreen.V17.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId
    , channelId : Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Effect.Time.Posix Evergreen.V17.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V17.RichText.RichText) (Maybe Int)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) Evergreen.V17.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId) Evergreen.V17.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.SecretId.SecretId Evergreen.V17.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) Evergreen.V17.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V17.LocalState.JoinGuildError
            { guildId : Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId
            , guild : Evergreen.V17.LocalState.FrontendGuild
            , owner : Evergreen.V17.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.GuildOrDmId Int Evergreen.V17.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.GuildOrDmId Int Evergreen.V17.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V17.RichText.RichText)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.MessageId) (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) (List.Nonempty.Nonempty Evergreen.V17.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V17.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V17.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V17.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V17.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V17.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V17.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V17.Coord.Coord Evergreen.V17.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V17.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V17.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V17.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V17.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V17.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V17.Editable.Model
    , botToken : Evergreen.V17.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V17.Local.Local LocalMsg Evergreen.V17.LocalState.LocalState
    , admin : Maybe Evergreen.V17.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V17.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId, Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId, Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V17.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V17.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V17.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V17.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : List Effect.File.File
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V17.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V17.SecretId.SecretId Evergreen.V17.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V17.NonemptyDict.NonemptyDict Int Evergreen.V17.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V17.NonemptyDict.NonemptyDict Int Evergreen.V17.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V17.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V17.Coord.Coord Evergreen.V17.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V17.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V17.Ports.NotificationPermission
    , pwaStatus : Evergreen.V17.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V17.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V17.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V17.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V17.NonemptyDict.NonemptyDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V17.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V17.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) Evergreen.V17.LocalState.BackendGuild
    , discordModel : Evergreen.V17.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V17.OneToOne.OneToOne (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId)
    , discordUsers : Evergreen.V17.OneToOne.OneToOne (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.UserId) (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , discordBotId : Maybe (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V17.DmChannel.DmChannelId Evergreen.V17.DmChannel.DmChannel
    , discordDms : Evergreen.V17.OneToOne.OneToOne (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.ChannelId) Evergreen.V17.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V17.LocalState.DiscordBotToken
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V17.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V17.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V17.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V17.Route.Route
    | TypedMessage Evergreen.V17.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V17.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V17.User.GuildOrDmId
    | SelectedFilesToAttach Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V17.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V17.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V17.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V17.Coord.Coord Evergreen.V17.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V17.Coord.Coord Evergreen.V17.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V17.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V17.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V17.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V17.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V17.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V17.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V17.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V17.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V17.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V17.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V17.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V17.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V17.NonemptyDict.NonemptyDict Int Evergreen.V17.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V17.NonemptyDict.NonemptyDict Int Evergreen.V17.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V17.Coord.Coord Evergreen.V17.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V17.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V17.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V17.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V17.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V17.Editable.Msg Evergreen.V17.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V17.Editable.Msg (Maybe Evergreen.V17.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | TimeToUploadFile Effect.Time.Posix
    | GotAttachmentContents Bytes.Bytes


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V17.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V17.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V17.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V17.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.SecretId.SecretId Evergreen.V17.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V17.PersonName.PersonName
    | AiChatToBackend Evergreen.V17.AiChat.ToBackend
    | ReloadDataRequest
    | UploadFileRequest Bytes.Bytes


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V17.EmailAddress.EmailAddress (Result Evergreen.V17.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V17.EmailAddress.EmailAddress (Result Evergreen.V17.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V17.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V17.LocalState.DiscordBotToken (Result Evergreen.V17.Discord.HttpError ( Evergreen.V17.Discord.User, List Evergreen.V17.Discord.PartialGuild ))
    | GotDiscordGuilds Effect.Time.Posix (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.UserId) (Result Evergreen.V17.Discord.HttpError (List ( Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.GuildId, ( Evergreen.V17.Discord.Guild, List Evergreen.V17.Discord.GuildMember, List Evergreen.V17.Discord.Channel2 ) )))
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V17.Discord.HttpError Evergreen.V17.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V17.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V17.DmChannel.DmChannelId Int (Result Evergreen.V17.Discord.HttpError Evergreen.V17.Discord.Message)


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
    | AdminToFrontend Evergreen.V17.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V17.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V17.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V17.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
