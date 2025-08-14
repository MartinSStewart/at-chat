module Evergreen.V31.Types exposing (..)

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
import Evergreen.V31.AiChat
import Evergreen.V31.ChannelName
import Evergreen.V31.Coord
import Evergreen.V31.CssPixels
import Evergreen.V31.Discord
import Evergreen.V31.Discord.Id
import Evergreen.V31.DmChannel
import Evergreen.V31.Editable
import Evergreen.V31.EmailAddress
import Evergreen.V31.Emoji
import Evergreen.V31.FileStatus
import Evergreen.V31.GuildName
import Evergreen.V31.Id
import Evergreen.V31.Local
import Evergreen.V31.LocalState
import Evergreen.V31.Log
import Evergreen.V31.LoginForm
import Evergreen.V31.MessageInput
import Evergreen.V31.NonemptyDict
import Evergreen.V31.NonemptySet
import Evergreen.V31.OneToOne
import Evergreen.V31.Pages.Admin
import Evergreen.V31.PersonName
import Evergreen.V31.Ports
import Evergreen.V31.Postmark
import Evergreen.V31.RichText
import Evergreen.V31.Route
import Evergreen.V31.SecretId
import Evergreen.V31.Touch
import Evergreen.V31.TwoFactorAuthentication
import Evergreen.V31.Ui.Anim
import Evergreen.V31.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V31.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) Evergreen.V31.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.DmChannel.DmChannel
    , user : Evergreen.V31.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V31.Route.Route
    , windowSize : Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V31.Ports.NotificationPermission
    , pwaStatus : Evergreen.V31.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V31.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V31.Id.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V31.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Evergreen.V31.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) Evergreen.V31.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId) Evergreen.V31.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V31.SecretId.SecretId Evergreen.V31.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V31.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V31.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V31.Id.GuildOrDmId Int Evergreen.V31.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V31.Id.GuildOrDmId Int Evergreen.V31.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V31.Id.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V31.RichText.RichText) (SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Evergreen.V31.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V31.Id.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V31.Id.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V31.Id.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | Local_SetName Evergreen.V31.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId
    , channelId : Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Effect.Time.Posix Evergreen.V31.Id.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V31.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Evergreen.V31.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) Evergreen.V31.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId) Evergreen.V31.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.SecretId.SecretId Evergreen.V31.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) Evergreen.V31.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V31.LocalState.JoinGuildError
            { guildId : Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId
            , guild : Evergreen.V31.LocalState.FrontendGuild
            , owner : Evergreen.V31.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.Id.GuildOrDmId Int Evergreen.V31.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.Id.GuildOrDmId Int Evergreen.V31.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.Id.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V31.RichText.RichText) (SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Evergreen.V31.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.Id.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.Id.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.MessageId) (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) (List.Nonempty.Nonempty Evergreen.V31.RichText.RichText) (Maybe Int)


type LocalMsg
    = LocalChange (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V31.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V31.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V31.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V31.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V31.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V31.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V31.Id.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V31.Id.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V31.Id.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Evergreen.V31.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V31.Id.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V31.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V31.Editable.Model
    , botToken : Evergreen.V31.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V31.Local.Local LocalMsg Evergreen.V31.LocalState.LocalState
    , admin : Maybe Evergreen.V31.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V31.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId, Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId, Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V31.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V31.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V31.Id.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V31.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V31.Id.GuildOrDmId (Evergreen.V31.NonemptyDict.NonemptyDict (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Evergreen.V31.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V31.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V31.SecretId.SecretId Evergreen.V31.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V31.NonemptyDict.NonemptyDict Int Evergreen.V31.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V31.NonemptyDict.NonemptyDict Int Evergreen.V31.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V31.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V31.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V31.Ports.NotificationPermission
    , pwaStatus : Evergreen.V31.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V31.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V31.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V31.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V31.NonemptyDict.NonemptyDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V31.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V31.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) Evergreen.V31.LocalState.BackendGuild
    , discordModel : Evergreen.V31.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V31.OneToOne.OneToOne (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId)
    , discordUsers : Evergreen.V31.OneToOne.OneToOne (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.UserId) (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)
    , discordBotId : Maybe (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V31.DmChannel.DmChannelId Evergreen.V31.DmChannel.DmChannel
    , discordDms : Evergreen.V31.OneToOne.OneToOne (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.ChannelId) Evergreen.V31.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V31.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V31.FileStatus.FileHash BackendFileData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V31.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V31.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V31.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V31.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V31.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V31.Id.GuildOrDmId
    | PressedAttachFiles Evergreen.V31.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V31.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V31.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V31.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V31.Id.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V31.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V31.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V31.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V31.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V31.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V31.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V31.Id.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V31.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V31.Id.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V31.Id.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V31.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V31.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V31.NonemptyDict.NonemptyDict Int Evergreen.V31.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V31.NonemptyDict.NonemptyDict Int Evergreen.V31.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V31.Id.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V31.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V31.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V31.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V31.Editable.Msg Evergreen.V31.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V31.Editable.Msg (Maybe Evergreen.V31.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V31.Id.GuildOrDmId (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V31.FileStatus.FileHash, Maybe (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V31.Id.GuildOrDmId (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V31.Id.GuildOrDmId (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V31.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V31.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V31.Id.GuildOrDmId Int (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V31.FileStatus.FileHash, Maybe (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V31.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V31.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V31.Id.GuildOrDmId (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Effect.Http.Progress


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V31.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V31.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V31.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V31.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.SecretId.SecretId Evergreen.V31.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V31.PersonName.PersonName
    | AiChatToBackend Evergreen.V31.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V31.EmailAddress.EmailAddress (Result Evergreen.V31.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V31.EmailAddress.EmailAddress (Result Evergreen.V31.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V31.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V31.LocalState.DiscordBotToken (Result Evergreen.V31.Discord.HttpError ( Evergreen.V31.Discord.User, List Evergreen.V31.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.UserId)
        (Result
            Evergreen.V31.Discord.HttpError
            (List
                ( Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.GuildId
                , { guild : Evergreen.V31.Discord.Guild
                  , members : List Evergreen.V31.Discord.GuildMember
                  , channels : List Evergreen.V31.Discord.Channel2
                  , icon : Maybe ( Evergreen.V31.FileStatus.FileHash, Maybe (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels) )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V31.Discord.HttpError Evergreen.V31.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V31.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V31.DmChannel.DmChannelId Int (Result Evergreen.V31.Discord.HttpError Evergreen.V31.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V31.Discord.HttpError (List ( Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.UserId, Maybe ( Evergreen.V31.FileStatus.FileHash, Maybe (Evergreen.V31.Coord.Coord Evergreen.V31.CssPixels.CssPixels) ) )))


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
    | AdminToFrontend Evergreen.V31.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V31.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V31.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V31.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
