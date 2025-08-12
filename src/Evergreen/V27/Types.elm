module Evergreen.V27.Types exposing (..)

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
import Evergreen.V27.AiChat
import Evergreen.V27.ChannelName
import Evergreen.V27.Coord
import Evergreen.V27.CssPixels
import Evergreen.V27.Discord
import Evergreen.V27.Discord.Id
import Evergreen.V27.DmChannel
import Evergreen.V27.Editable
import Evergreen.V27.EmailAddress
import Evergreen.V27.Emoji
import Evergreen.V27.FileStatus
import Evergreen.V27.GuildName
import Evergreen.V27.Id
import Evergreen.V27.Local
import Evergreen.V27.LocalState
import Evergreen.V27.Log
import Evergreen.V27.LoginForm
import Evergreen.V27.MessageInput
import Evergreen.V27.NonemptyDict
import Evergreen.V27.NonemptySet
import Evergreen.V27.OneToOne
import Evergreen.V27.Pages.Admin
import Evergreen.V27.PersonName
import Evergreen.V27.Ports
import Evergreen.V27.Postmark
import Evergreen.V27.RichText
import Evergreen.V27.Route
import Evergreen.V27.SecretId
import Evergreen.V27.Touch
import Evergreen.V27.TwoFactorAuthentication
import Evergreen.V27.Ui.Anim
import Evergreen.V27.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V27.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.DmChannel.DmChannel
    , user : Evergreen.V27.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V27.Route.Route
    , windowSize : Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V27.Ports.NotificationPermission
    , pwaStatus : Evergreen.V27.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V27.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V27.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) Evergreen.V27.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) Evergreen.V27.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V27.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V27.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V27.User.GuildOrDmId Int Evergreen.V27.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V27.User.GuildOrDmId Int Evergreen.V27.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V27.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText) (SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) Evergreen.V27.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V27.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V27.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V27.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | Local_SetName Evergreen.V27.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId
    , channelId : Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Effect.Time.Posix Evergreen.V27.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) Evergreen.V27.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) Evergreen.V27.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V27.LocalState.JoinGuildError
            { guildId : Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId
            , guild : Evergreen.V27.LocalState.FrontendGuild
            , owner : Evergreen.V27.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.GuildOrDmId Int Evergreen.V27.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.GuildOrDmId Int Evergreen.V27.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText) (SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) Evergreen.V27.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.MessageId) (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (List.Nonempty.Nonempty Evergreen.V27.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V27.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V27.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V27.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V27.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V27.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V27.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V27.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V27.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V27.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) Evergreen.V27.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V27.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V27.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V27.Editable.Model
    , botToken : Evergreen.V27.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V27.Local.Local LocalMsg Evergreen.V27.LocalState.LocalState
    , admin : Maybe Evergreen.V27.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V27.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V27.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V27.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V27.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V27.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V27.User.GuildOrDmId (Evergreen.V27.NonemptyDict.NonemptyDict (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) Evergreen.V27.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V27.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V27.NonemptyDict.NonemptyDict Int Evergreen.V27.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V27.NonemptyDict.NonemptyDict Int Evergreen.V27.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V27.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V27.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V27.Ports.NotificationPermission
    , pwaStatus : Evergreen.V27.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V27.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V27.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V27.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V27.NonemptyDict.NonemptyDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V27.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V27.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) Evergreen.V27.LocalState.BackendGuild
    , discordModel : Evergreen.V27.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V27.OneToOne.OneToOne (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId)
    , discordUsers : Evergreen.V27.OneToOne.OneToOne (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , discordBotId : Maybe (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V27.DmChannel.DmChannelId Evergreen.V27.DmChannel.DmChannel
    , discordDms : Evergreen.V27.OneToOne.OneToOne (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.ChannelId) Evergreen.V27.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V27.LocalState.DiscordBotToken
    , files :
        SeqDict.SeqDict
            Evergreen.V27.FileStatus.FileHash
            { fileSize : Int
            }
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V27.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V27.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V27.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V27.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V27.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V27.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V27.User.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V27.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V27.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V27.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V27.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V27.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V27.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V27.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V27.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V27.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V27.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V27.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V27.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V27.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V27.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V27.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V27.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V27.NonemptyDict.NonemptyDict Int Evergreen.V27.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V27.NonemptyDict.NonemptyDict Int Evergreen.V27.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V27.Coord.Coord Evergreen.V27.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V27.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V27.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V27.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V27.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V27.Editable.Msg Evergreen.V27.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V27.Editable.Msg (Maybe Evergreen.V27.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V27.User.GuildOrDmId (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V27.FileStatus.FileHash)
    | PressedDeleteAttachedFile Evergreen.V27.User.GuildOrDmId (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V27.User.GuildOrDmId (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V27.User.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V27.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V27.User.GuildOrDmId Int (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V27.FileStatus.FileHash)
    | EditMessage_PastedFiles Evergreen.V27.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V27.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V27.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V27.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V27.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V27.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V27.PersonName.PersonName
    | AiChatToBackend Evergreen.V27.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V27.EmailAddress.EmailAddress (Result Evergreen.V27.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V27.EmailAddress.EmailAddress (Result Evergreen.V27.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V27.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V27.LocalState.DiscordBotToken (Result Evergreen.V27.Discord.HttpError ( Evergreen.V27.Discord.User, List Evergreen.V27.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.UserId)
        (Result
            Evergreen.V27.Discord.HttpError
            (List
                ( Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.GuildId
                , { guild : Evergreen.V27.Discord.Guild
                  , members : List Evergreen.V27.Discord.GuildMember
                  , channels : List Evergreen.V27.Discord.Channel2
                  , icon : Maybe Evergreen.V27.FileStatus.FileHash
                  }
                )
            )
        )
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V27.Discord.HttpError Evergreen.V27.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V27.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V27.DmChannel.DmChannelId Int (Result Evergreen.V27.Discord.HttpError Evergreen.V27.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V27.Discord.HttpError (List ( Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.UserId, Maybe Evergreen.V27.FileStatus.FileHash )))


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
    | AdminToFrontend Evergreen.V27.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V27.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V27.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V27.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
