module Evergreen.V30.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V30.AiChat
import Evergreen.V30.ChannelName
import Evergreen.V30.Coord
import Evergreen.V30.CssPixels
import Evergreen.V30.Discord
import Evergreen.V30.Discord.Id
import Evergreen.V30.DmChannel
import Evergreen.V30.Editable
import Evergreen.V30.EmailAddress
import Evergreen.V30.Emoji
import Evergreen.V30.FileStatus
import Evergreen.V30.GuildName
import Evergreen.V30.Id
import Evergreen.V30.Local
import Evergreen.V30.LocalState
import Evergreen.V30.Log
import Evergreen.V30.LoginForm
import Evergreen.V30.MessageInput
import Evergreen.V30.NonemptyDict
import Evergreen.V30.NonemptySet
import Evergreen.V30.OneToOne
import Evergreen.V30.Pages.Admin
import Evergreen.V30.PersonName
import Evergreen.V30.Ports
import Evergreen.V30.Postmark
import Evergreen.V30.RichText
import Evergreen.V30.Route
import Evergreen.V30.SecretId
import Evergreen.V30.Touch
import Evergreen.V30.TwoFactorAuthentication
import Evergreen.V30.Ui.Anim
import Evergreen.V30.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V30.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) Evergreen.V30.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.DmChannel.DmChannel
    , user : Evergreen.V30.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V30.Route.Route
    , windowSize : Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V30.Ports.NotificationPermission
    , pwaStatus : Evergreen.V30.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V30.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V30.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V30.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) Evergreen.V30.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) Evergreen.V30.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId) Evergreen.V30.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V30.SecretId.SecretId Evergreen.V30.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V30.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V30.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V30.User.GuildOrDmId Int Evergreen.V30.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V30.User.GuildOrDmId Int Evergreen.V30.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V30.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V30.RichText.RichText) (SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) Evergreen.V30.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V30.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V30.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V30.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | Local_SetName Evergreen.V30.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId
    , channelId : Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Effect.Time.Posix Evergreen.V30.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V30.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) Evergreen.V30.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) Evergreen.V30.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId) Evergreen.V30.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.SecretId.SecretId Evergreen.V30.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) Evergreen.V30.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V30.LocalState.JoinGuildError
            { guildId : Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId
            , guild : Evergreen.V30.LocalState.FrontendGuild
            , owner : Evergreen.V30.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.GuildOrDmId Int Evergreen.V30.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.GuildOrDmId Int Evergreen.V30.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V30.RichText.RichText) (SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) Evergreen.V30.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.MessageId) (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (List.Nonempty.Nonempty Evergreen.V30.RichText.RichText) (Maybe Int)


type LocalMsg
    = LocalChange (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V30.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V30.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V30.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V30.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V30.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V30.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V30.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V30.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V30.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) Evergreen.V30.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V30.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V30.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V30.Editable.Model
    , botToken : Evergreen.V30.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V30.Local.Local LocalMsg Evergreen.V30.LocalState.LocalState
    , admin : Maybe Evergreen.V30.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V30.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId, Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId, Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V30.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V30.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V30.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V30.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V30.User.GuildOrDmId (Evergreen.V30.NonemptyDict.NonemptyDict (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) Evergreen.V30.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V30.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V30.SecretId.SecretId Evergreen.V30.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V30.NonemptyDict.NonemptyDict Int Evergreen.V30.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V30.NonemptyDict.NonemptyDict Int Evergreen.V30.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V30.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V30.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V30.Ports.NotificationPermission
    , pwaStatus : Evergreen.V30.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V30.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V30.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V30.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V30.NonemptyDict.NonemptyDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V30.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V30.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) Evergreen.V30.LocalState.BackendGuild
    , discordModel : Evergreen.V30.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V30.OneToOne.OneToOne (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId)
    , discordUsers : Evergreen.V30.OneToOne.OneToOne (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , discordBotId : Maybe (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V30.DmChannel.DmChannelId Evergreen.V30.DmChannel.DmChannel
    , discordDms : Evergreen.V30.OneToOne.OneToOne (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.ChannelId) Evergreen.V30.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V30.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V30.FileStatus.FileHash BackendFileData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V30.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V30.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V30.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V30.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V30.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V30.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V30.User.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V30.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V30.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V30.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V30.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V30.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V30.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V30.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V30.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V30.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V30.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V30.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V30.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V30.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V30.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V30.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V30.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V30.NonemptyDict.NonemptyDict Int Evergreen.V30.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V30.NonemptyDict.NonemptyDict Int Evergreen.V30.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V30.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V30.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V30.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V30.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V30.Editable.Msg Evergreen.V30.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V30.Editable.Msg (Maybe Evergreen.V30.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V30.User.GuildOrDmId (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V30.FileStatus.FileHash, Maybe (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V30.User.GuildOrDmId (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V30.User.GuildOrDmId (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V30.User.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V30.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V30.User.GuildOrDmId Int (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V30.FileStatus.FileHash, Maybe (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V30.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V30.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V30.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V30.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V30.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V30.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.SecretId.SecretId Evergreen.V30.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V30.PersonName.PersonName
    | AiChatToBackend Evergreen.V30.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V30.EmailAddress.EmailAddress (Result Evergreen.V30.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V30.EmailAddress.EmailAddress (Result Evergreen.V30.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V30.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V30.LocalState.DiscordBotToken (Result Evergreen.V30.Discord.HttpError ( Evergreen.V30.Discord.User, List Evergreen.V30.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.UserId)
        (Result
            Evergreen.V30.Discord.HttpError
            (List
                ( Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.GuildId
                , { guild : Evergreen.V30.Discord.Guild
                  , members : List Evergreen.V30.Discord.GuildMember
                  , channels : List Evergreen.V30.Discord.Channel2
                  , icon : Maybe ( Evergreen.V30.FileStatus.FileHash, Maybe (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels) )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V30.Discord.HttpError Evergreen.V30.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V30.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V30.DmChannel.DmChannelId Int (Result Evergreen.V30.Discord.HttpError Evergreen.V30.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V30.Discord.HttpError (List ( Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.UserId, Maybe ( Evergreen.V30.FileStatus.FileHash, Maybe (Evergreen.V30.Coord.Coord Evergreen.V30.CssPixels.CssPixels) ) )))


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
    | AdminToFrontend Evergreen.V30.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V30.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V30.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V30.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
