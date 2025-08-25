module Evergreen.V33.Types exposing (..)

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
import Evergreen.V33.AiChat
import Evergreen.V33.ChannelName
import Evergreen.V33.Coord
import Evergreen.V33.CssPixels
import Evergreen.V33.Discord
import Evergreen.V33.Discord.Id
import Evergreen.V33.DmChannel
import Evergreen.V33.Editable
import Evergreen.V33.EmailAddress
import Evergreen.V33.Emoji
import Evergreen.V33.FileStatus
import Evergreen.V33.GuildName
import Evergreen.V33.Id
import Evergreen.V33.Local
import Evergreen.V33.LocalState
import Evergreen.V33.Log
import Evergreen.V33.LoginForm
import Evergreen.V33.MessageInput
import Evergreen.V33.MessageView
import Evergreen.V33.NonemptyDict
import Evergreen.V33.NonemptySet
import Evergreen.V33.OneToOne
import Evergreen.V33.Pages.Admin
import Evergreen.V33.PersonName
import Evergreen.V33.Ports
import Evergreen.V33.Postmark
import Evergreen.V33.RichText
import Evergreen.V33.Route
import Evergreen.V33.SecretId
import Evergreen.V33.Touch
import Evergreen.V33.TwoFactorAuthentication
import Evergreen.V33.Ui.Anim
import Evergreen.V33.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V33.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) Evergreen.V33.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.DmChannel.DmChannel
    , user : Evergreen.V33.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V33.Route.Route
    , windowSize : Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V33.Ports.NotificationPermission
    , pwaStatus : Evergreen.V33.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V33.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V33.Id.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V33.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Evergreen.V33.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) Evergreen.V33.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) Evergreen.V33.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V33.SecretId.SecretId Evergreen.V33.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V33.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V33.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V33.Id.GuildOrDmId Int Evergreen.V33.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V33.Id.GuildOrDmId Int Evergreen.V33.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V33.Id.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V33.RichText.RichText) (SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Evergreen.V33.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V33.Id.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V33.Id.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V33.Id.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    | Local_SetName Evergreen.V33.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId
    , channelId : Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Effect.Time.Posix Evergreen.V33.Id.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V33.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Evergreen.V33.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) Evergreen.V33.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) Evergreen.V33.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.SecretId.SecretId Evergreen.V33.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) Evergreen.V33.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V33.LocalState.JoinGuildError
            { guildId : Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId
            , guild : Evergreen.V33.LocalState.FrontendGuild
            , owner : Evergreen.V33.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.GuildOrDmId Int Evergreen.V33.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.GuildOrDmId Int Evergreen.V33.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V33.RichText.RichText) (SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Evergreen.V33.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.MessageId) (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (List.Nonempty.Nonempty Evergreen.V33.RichText.RichText) (Maybe Int)


type LocalMsg
    = LocalChange (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V33.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V33.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V33.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V33.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V33.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V33.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V33.Id.GuildOrDmId
    , isThreadStarter : Bool
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V33.Id.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V33.Id.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Evergreen.V33.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V33.Id.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V33.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V33.Editable.Model
    , botToken : Evergreen.V33.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V33.Local.Local LocalMsg Evergreen.V33.LocalState.LocalState
    , admin : Maybe Evergreen.V33.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V33.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId, Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId, Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId, Evergreen.V33.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V33.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V33.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V33.Id.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V33.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V33.Id.GuildOrDmId (Evergreen.V33.NonemptyDict.NonemptyDict (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Evergreen.V33.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V33.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V33.SecretId.SecretId Evergreen.V33.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V33.NonemptyDict.NonemptyDict Int Evergreen.V33.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V33.NonemptyDict.NonemptyDict Int Evergreen.V33.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V33.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V33.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V33.Ports.NotificationPermission
    , pwaStatus : Evergreen.V33.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V33.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V33.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V33.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V33.NonemptyDict.NonemptyDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V33.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V33.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) Evergreen.V33.LocalState.BackendGuild
    , discordModel : Evergreen.V33.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId)
    , discordUsers : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    , discordBotId : Maybe (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V33.DmChannel.DmChannelId Evergreen.V33.DmChannel.DmChannel
    , discordDms : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.ChannelId) Evergreen.V33.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V33.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V33.FileStatus.FileHash BackendFileData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V33.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V33.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V33.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V33.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V33.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V33.Id.GuildOrDmId
    | PressedAttachFiles Evergreen.V33.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V33.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) Evergreen.V33.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) Evergreen.V33.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V33.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V33.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V33.Id.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V33.Id.GuildOrDmId Int (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V33.Id.GuildOrDmId Int
    | PressedEmojiSelectorEmoji Evergreen.V33.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V33.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V33.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V33.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V33.Id.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V33.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V33.Id.GuildOrDmId
    | MessageMenu_PressedReply Int
    | MessageMenu_PressedOpenThread Int
    | PressedCloseReplyTo Evergreen.V33.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V33.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V33.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V33.Id.GuildOrDmId, Int, Bool )) Effect.Time.Posix (Evergreen.V33.NonemptyDict.NonemptyDict Int Evergreen.V33.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V33.NonemptyDict.NonemptyDict Int Evergreen.V33.Touch.Touch)
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
    | MessageMenu_PressedDeleteMessage Evergreen.V33.Id.GuildOrDmId Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V33.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V33.Id.GuildOrDmId Int Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V33.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V33.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V33.Editable.Msg Evergreen.V33.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V33.Editable.Msg (Maybe Evergreen.V33.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V33.Id.GuildOrDmId (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V33.FileStatus.FileHash, Maybe (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V33.Id.GuildOrDmId (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V33.Id.GuildOrDmId (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V33.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V33.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V33.Id.GuildOrDmId Int (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V33.FileStatus.FileHash, Maybe (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V33.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V33.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V33.Id.GuildOrDmId (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V33.Id.GuildOrDmId Evergreen.V33.MessageView.MessageViewMsg


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V33.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V33.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V33.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V33.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.SecretId.SecretId Evergreen.V33.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V33.PersonName.PersonName
    | AiChatToBackend Evergreen.V33.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V33.EmailAddress.EmailAddress (Result Evergreen.V33.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V33.EmailAddress.EmailAddress (Result Evergreen.V33.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V33.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V33.LocalState.DiscordBotToken (Result Evergreen.V33.Discord.HttpError ( Evergreen.V33.Discord.User, List Evergreen.V33.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.UserId)
        (Result
            Evergreen.V33.Discord.HttpError
            (List
                ( Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.GuildId
                , { guild : Evergreen.V33.Discord.Guild
                  , members : List Evergreen.V33.Discord.GuildMember
                  , channels : List ( Evergreen.V33.Discord.Channel2, List Evergreen.V33.Discord.Message )
                  , icon : Maybe ( Evergreen.V33.FileStatus.FileHash, Maybe (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V33.Discord.Channel, List Evergreen.V33.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord MessageId Evergreen.V33.Id.ThreadRoute (Result Evergreen.V33.Discord.HttpError Evergreen.V33.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V33.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V33.DmChannel.DmChannelId Evergreen.V33.Id.ThreadRoute Int (Result Evergreen.V33.Discord.HttpError Evergreen.V33.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V33.Discord.HttpError (List ( Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.UserId, Maybe ( Evergreen.V33.FileStatus.FileHash, Maybe (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels) ) )))


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
    | AdminToFrontend Evergreen.V33.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V33.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V33.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V33.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
