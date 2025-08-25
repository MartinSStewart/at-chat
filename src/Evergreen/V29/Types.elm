module Evergreen.V29.Types exposing (..)

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
import Evergreen.V29.AiChat
import Evergreen.V29.ChannelName
import Evergreen.V29.Coord
import Evergreen.V29.CssPixels
import Evergreen.V29.Discord
import Evergreen.V29.Discord.Id
import Evergreen.V29.DmChannel
import Evergreen.V29.Editable
import Evergreen.V29.EmailAddress
import Evergreen.V29.Emoji
import Evergreen.V29.FileStatus
import Evergreen.V29.GuildName
import Evergreen.V29.Id
import Evergreen.V29.Local
import Evergreen.V29.LocalState
import Evergreen.V29.Log
import Evergreen.V29.LoginForm
import Evergreen.V29.MessageInput
import Evergreen.V29.NonemptyDict
import Evergreen.V29.NonemptySet
import Evergreen.V29.OneToOne
import Evergreen.V29.Pages.Admin
import Evergreen.V29.PersonName
import Evergreen.V29.Ports
import Evergreen.V29.Postmark
import Evergreen.V29.RichText
import Evergreen.V29.Route
import Evergreen.V29.SecretId
import Evergreen.V29.Touch
import Evergreen.V29.TwoFactorAuthentication
import Evergreen.V29.Ui.Anim
import Evergreen.V29.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V29.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.DmChannel.DmChannel
    , user : Evergreen.V29.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V29.Route.Route
    , windowSize : Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V29.Ports.NotificationPermission
    , pwaStatus : Evergreen.V29.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V29.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V29.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) Evergreen.V29.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) Evergreen.V29.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V29.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V29.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V29.User.GuildOrDmId Int Evergreen.V29.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V29.User.GuildOrDmId Int Evergreen.V29.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V29.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText) (SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) Evergreen.V29.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V29.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V29.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V29.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | Local_SetName Evergreen.V29.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId
    , channelId : Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Effect.Time.Posix Evergreen.V29.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) Evergreen.V29.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) Evergreen.V29.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V29.LocalState.JoinGuildError
            { guildId : Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId
            , guild : Evergreen.V29.LocalState.FrontendGuild
            , owner : Evergreen.V29.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.GuildOrDmId Int Evergreen.V29.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.GuildOrDmId Int Evergreen.V29.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText) (SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) Evergreen.V29.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.MessageId) (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (List.Nonempty.Nonempty Evergreen.V29.RichText.RichText) (Maybe Int)


type LocalMsg
    = LocalChange (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V29.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V29.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V29.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V29.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V29.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V29.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V29.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V29.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V29.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) Evergreen.V29.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V29.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V29.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V29.Editable.Model
    , botToken : Evergreen.V29.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V29.Local.Local LocalMsg Evergreen.V29.LocalState.LocalState
    , admin : Maybe Evergreen.V29.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V29.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V29.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V29.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V29.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V29.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V29.User.GuildOrDmId (Evergreen.V29.NonemptyDict.NonemptyDict (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) Evergreen.V29.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V29.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V29.NonemptyDict.NonemptyDict Int Evergreen.V29.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V29.NonemptyDict.NonemptyDict Int Evergreen.V29.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V29.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V29.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V29.Ports.NotificationPermission
    , pwaStatus : Evergreen.V29.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V29.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V29.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V29.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V29.NonemptyDict.NonemptyDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V29.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V29.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) Evergreen.V29.LocalState.BackendGuild
    , discordModel : Evergreen.V29.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V29.OneToOne.OneToOne (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId)
    , discordUsers : Evergreen.V29.OneToOne.OneToOne (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , discordBotId : Maybe (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V29.DmChannel.DmChannelId Evergreen.V29.DmChannel.DmChannel
    , discordDms : Evergreen.V29.OneToOne.OneToOne (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.ChannelId) Evergreen.V29.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V29.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V29.FileStatus.FileHash BackendFileData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V29.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V29.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V29.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V29.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V29.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V29.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V29.User.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V29.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V29.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V29.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V29.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V29.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V29.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V29.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V29.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V29.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V29.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V29.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V29.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V29.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V29.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V29.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V29.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V29.NonemptyDict.NonemptyDict Int Evergreen.V29.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V29.NonemptyDict.NonemptyDict Int Evergreen.V29.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V29.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V29.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V29.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V29.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V29.Editable.Msg Evergreen.V29.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V29.Editable.Msg (Maybe Evergreen.V29.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V29.User.GuildOrDmId (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V29.FileStatus.FileHash, Maybe (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V29.User.GuildOrDmId (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V29.User.GuildOrDmId (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V29.User.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V29.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V29.User.GuildOrDmId Int (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V29.FileStatus.FileHash, Maybe (Evergreen.V29.Coord.Coord Evergreen.V29.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V29.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V29.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V29.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V29.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V29.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V29.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V29.PersonName.PersonName
    | AiChatToBackend Evergreen.V29.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V29.EmailAddress.EmailAddress (Result Evergreen.V29.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V29.EmailAddress.EmailAddress (Result Evergreen.V29.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V29.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V29.LocalState.DiscordBotToken (Result Evergreen.V29.Discord.HttpError ( Evergreen.V29.Discord.User, List Evergreen.V29.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.UserId)
        (Result
            Evergreen.V29.Discord.HttpError
            (List
                ( Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.GuildId
                , { guild : Evergreen.V29.Discord.Guild
                  , members : List Evergreen.V29.Discord.GuildMember
                  , channels : List Evergreen.V29.Discord.Channel2
                  , icon : Maybe Evergreen.V29.FileStatus.FileHash
                  }
                )
            )
        )
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V29.Discord.HttpError Evergreen.V29.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V29.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V29.DmChannel.DmChannelId Int (Result Evergreen.V29.Discord.HttpError Evergreen.V29.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V29.Discord.HttpError (List ( Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.UserId, Maybe Evergreen.V29.FileStatus.FileHash )))


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
    | AdminToFrontend Evergreen.V29.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V29.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V29.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V29.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
