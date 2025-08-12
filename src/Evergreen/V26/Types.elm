module Evergreen.V26.Types exposing (..)

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
import Evergreen.V26.AiChat
import Evergreen.V26.ChannelName
import Evergreen.V26.Coord
import Evergreen.V26.CssPixels
import Evergreen.V26.Discord
import Evergreen.V26.Discord.Id
import Evergreen.V26.DmChannel
import Evergreen.V26.Editable
import Evergreen.V26.EmailAddress
import Evergreen.V26.Emoji
import Evergreen.V26.FileStatus
import Evergreen.V26.GuildName
import Evergreen.V26.Id
import Evergreen.V26.Local
import Evergreen.V26.LocalState
import Evergreen.V26.Log
import Evergreen.V26.LoginForm
import Evergreen.V26.MessageInput
import Evergreen.V26.NonemptyDict
import Evergreen.V26.NonemptySet
import Evergreen.V26.OneToOne
import Evergreen.V26.Pages.Admin
import Evergreen.V26.PersonName
import Evergreen.V26.Ports
import Evergreen.V26.Postmark
import Evergreen.V26.RichText
import Evergreen.V26.Route
import Evergreen.V26.SecretId
import Evergreen.V26.Touch
import Evergreen.V26.TwoFactorAuthentication
import Evergreen.V26.Ui.Anim
import Evergreen.V26.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V26.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) Evergreen.V26.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.DmChannel.DmChannel
    , user : Evergreen.V26.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V26.Route.Route
    , windowSize : Evergreen.V26.Coord.Coord Evergreen.V26.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V26.Ports.NotificationPermission
    , pwaStatus : Evergreen.V26.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V26.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V26.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V26.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) Evergreen.V26.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) Evergreen.V26.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId) Evergreen.V26.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V26.SecretId.SecretId Evergreen.V26.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V26.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V26.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V26.User.GuildOrDmId Int Evergreen.V26.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V26.User.GuildOrDmId Int Evergreen.V26.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V26.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V26.RichText.RichText) (SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) Evergreen.V26.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V26.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V26.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V26.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | Local_SetName Evergreen.V26.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId
    , channelId : Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Effect.Time.Posix Evergreen.V26.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V26.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) Evergreen.V26.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) Evergreen.V26.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId) Evergreen.V26.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.SecretId.SecretId Evergreen.V26.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) Evergreen.V26.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V26.LocalState.JoinGuildError
            { guildId : Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId
            , guild : Evergreen.V26.LocalState.FrontendGuild
            , owner : Evergreen.V26.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.GuildOrDmId Int Evergreen.V26.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.GuildOrDmId Int Evergreen.V26.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V26.RichText.RichText) (SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) Evergreen.V26.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.MessageId) (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (List.Nonempty.Nonempty Evergreen.V26.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V26.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V26.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V26.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V26.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V26.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V26.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V26.Coord.Coord Evergreen.V26.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V26.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V26.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V26.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) Evergreen.V26.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V26.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V26.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V26.Editable.Model
    , botToken : Evergreen.V26.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V26.Local.Local LocalMsg Evergreen.V26.LocalState.LocalState
    , admin : Maybe Evergreen.V26.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V26.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId, Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId, Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V26.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V26.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V26.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V26.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V26.User.GuildOrDmId (Evergreen.V26.NonemptyDict.NonemptyDict (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) Evergreen.V26.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V26.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V26.SecretId.SecretId Evergreen.V26.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V26.NonemptyDict.NonemptyDict Int Evergreen.V26.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V26.NonemptyDict.NonemptyDict Int Evergreen.V26.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V26.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V26.Coord.Coord Evergreen.V26.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V26.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V26.Ports.NotificationPermission
    , pwaStatus : Evergreen.V26.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V26.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V26.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V26.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V26.NonemptyDict.NonemptyDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V26.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V26.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) Evergreen.V26.LocalState.BackendGuild
    , discordModel : Evergreen.V26.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V26.OneToOne.OneToOne (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId)
    , discordUsers : Evergreen.V26.OneToOne.OneToOne (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.UserId) (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , discordBotId : Maybe (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V26.DmChannel.DmChannelId Evergreen.V26.DmChannel.DmChannel
    , discordDms : Evergreen.V26.OneToOne.OneToOne (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.ChannelId) Evergreen.V26.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V26.LocalState.DiscordBotToken
    , files :
        SeqDict.SeqDict
            Evergreen.V26.FileStatus.FileHash
            { fileSize : Int
            }
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V26.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V26.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V26.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V26.Route.Route
    | TypedMessage Evergreen.V26.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V26.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V26.User.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V26.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V26.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V26.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V26.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V26.Coord.Coord Evergreen.V26.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V26.Coord.Coord Evergreen.V26.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V26.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V26.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V26.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V26.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V26.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V26.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V26.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V26.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V26.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V26.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V26.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V26.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V26.NonemptyDict.NonemptyDict Int Evergreen.V26.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V26.NonemptyDict.NonemptyDict Int Evergreen.V26.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V26.Coord.Coord Evergreen.V26.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V26.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V26.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V26.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V26.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V26.Editable.Msg Evergreen.V26.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V26.Editable.Msg (Maybe Evergreen.V26.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V26.User.GuildOrDmId (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V26.FileStatus.FileHash)
    | PressedDeleteAttachedFile Evergreen.V26.User.GuildOrDmId (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V26.User.GuildOrDmId (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V26.User.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V26.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V26.User.GuildOrDmId Int (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V26.FileStatus.FileHash)
    | EditMessage_PastedFiles Evergreen.V26.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V26.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V26.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V26.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V26.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V26.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.SecretId.SecretId Evergreen.V26.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V26.PersonName.PersonName
    | AiChatToBackend Evergreen.V26.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V26.EmailAddress.EmailAddress (Result Evergreen.V26.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V26.EmailAddress.EmailAddress (Result Evergreen.V26.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V26.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V26.LocalState.DiscordBotToken (Result Evergreen.V26.Discord.HttpError ( Evergreen.V26.Discord.User, List Evergreen.V26.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.UserId)
        (Result
            Evergreen.V26.Discord.HttpError
            (List
                ( Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.GuildId
                , { guild : Evergreen.V26.Discord.Guild
                  , members : List Evergreen.V26.Discord.GuildMember
                  , channels : List Evergreen.V26.Discord.Channel2
                  , icon : Maybe Evergreen.V26.FileStatus.FileHash
                  }
                )
            )
        )
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V26.Discord.HttpError Evergreen.V26.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V26.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V26.DmChannel.DmChannelId Int (Result Evergreen.V26.Discord.HttpError Evergreen.V26.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V26.Discord.HttpError (List ( Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.UserId, Maybe Evergreen.V26.FileStatus.FileHash )))


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
    | AdminToFrontend Evergreen.V26.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V26.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V26.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V26.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
