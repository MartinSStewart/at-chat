module Evergreen.V24.Types exposing (..)

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
import Evergreen.V24.AiChat
import Evergreen.V24.ChannelName
import Evergreen.V24.Coord
import Evergreen.V24.CssPixels
import Evergreen.V24.Discord
import Evergreen.V24.Discord.Id
import Evergreen.V24.DmChannel
import Evergreen.V24.Editable
import Evergreen.V24.EmailAddress
import Evergreen.V24.Emoji
import Evergreen.V24.FileStatus
import Evergreen.V24.GuildName
import Evergreen.V24.Id
import Evergreen.V24.Local
import Evergreen.V24.LocalState
import Evergreen.V24.Log
import Evergreen.V24.LoginForm
import Evergreen.V24.MessageInput
import Evergreen.V24.NonemptyDict
import Evergreen.V24.NonemptySet
import Evergreen.V24.OneToOne
import Evergreen.V24.Pages.Admin
import Evergreen.V24.PersonName
import Evergreen.V24.Ports
import Evergreen.V24.Postmark
import Evergreen.V24.RichText
import Evergreen.V24.Route
import Evergreen.V24.SecretId
import Evergreen.V24.Touch
import Evergreen.V24.TwoFactorAuthentication
import Evergreen.V24.Ui.Anim
import Evergreen.V24.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V24.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) Evergreen.V24.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.DmChannel.DmChannel
    , user : Evergreen.V24.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V24.Route.Route
    , windowSize : Evergreen.V24.Coord.Coord Evergreen.V24.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V24.Ports.NotificationPermission
    , pwaStatus : Evergreen.V24.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V24.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V24.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V24.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) Evergreen.V24.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) Evergreen.V24.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) Evergreen.V24.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V24.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V24.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V24.User.GuildOrDmId Int Evergreen.V24.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V24.User.GuildOrDmId Int Evergreen.V24.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V24.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V24.RichText.RichText) (SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) Evergreen.V24.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V24.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V24.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V24.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | Local_SetName Evergreen.V24.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId
    , channelId : Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Effect.Time.Posix Evergreen.V24.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V24.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) Evergreen.V24.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) Evergreen.V24.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) Evergreen.V24.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) Evergreen.V24.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V24.LocalState.JoinGuildError
            { guildId : Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId
            , guild : Evergreen.V24.LocalState.FrontendGuild
            , owner : Evergreen.V24.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.GuildOrDmId Int Evergreen.V24.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.GuildOrDmId Int Evergreen.V24.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V24.RichText.RichText) (SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) Evergreen.V24.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.MessageId) (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) (List.Nonempty.Nonempty Evergreen.V24.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V24.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V24.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V24.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V24.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V24.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V24.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V24.Coord.Coord Evergreen.V24.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V24.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V24.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V24.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) Evergreen.V24.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V24.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V24.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V24.Editable.Model
    , botToken : Evergreen.V24.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V24.Local.Local LocalMsg Evergreen.V24.LocalState.LocalState
    , admin : Maybe Evergreen.V24.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V24.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId, Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId, Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V24.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V24.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V24.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V24.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V24.User.GuildOrDmId (Evergreen.V24.NonemptyDict.NonemptyDict (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) Evergreen.V24.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V24.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V24.NonemptyDict.NonemptyDict Int Evergreen.V24.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V24.NonemptyDict.NonemptyDict Int Evergreen.V24.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V24.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V24.Coord.Coord Evergreen.V24.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V24.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V24.Ports.NotificationPermission
    , pwaStatus : Evergreen.V24.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V24.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V24.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V24.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V24.NonemptyDict.NonemptyDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V24.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V24.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) Evergreen.V24.LocalState.BackendGuild
    , discordModel : Evergreen.V24.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V24.OneToOne.OneToOne (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId)
    , discordUsers : Evergreen.V24.OneToOne.OneToOne (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId) (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , discordBotId : Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V24.DmChannel.DmChannelId Evergreen.V24.DmChannel.DmChannel
    , discordDms : Evergreen.V24.OneToOne.OneToOne (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId) Evergreen.V24.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V24.LocalState.DiscordBotToken
    , files :
        SeqDict.SeqDict
            Evergreen.V24.FileStatus.FileHash
            { fileSize : Int
            }
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V24.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V24.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V24.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V24.Route.Route
    | TypedMessage Evergreen.V24.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V24.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V24.User.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V24.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V24.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V24.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V24.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V24.Coord.Coord Evergreen.V24.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V24.Coord.Coord Evergreen.V24.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V24.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V24.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V24.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V24.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V24.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V24.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V24.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V24.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V24.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V24.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V24.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V24.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V24.NonemptyDict.NonemptyDict Int Evergreen.V24.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V24.NonemptyDict.NonemptyDict Int Evergreen.V24.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V24.Coord.Coord Evergreen.V24.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V24.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V24.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V24.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V24.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V24.Editable.Msg Evergreen.V24.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V24.Editable.Msg (Maybe Evergreen.V24.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V24.User.GuildOrDmId (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V24.FileStatus.FileHash)
    | PressedDeleteAttachedFile Evergreen.V24.User.GuildOrDmId (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V24.User.GuildOrDmId (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V24.User.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V24.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V24.User.GuildOrDmId Int (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V24.FileStatus.FileHash)
    | EditMessage_PastedFiles Evergreen.V24.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V24.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V24.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V24.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V24.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V24.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V24.PersonName.PersonName
    | AiChatToBackend Evergreen.V24.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V24.EmailAddress.EmailAddress (Result Evergreen.V24.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V24.EmailAddress.EmailAddress (Result Evergreen.V24.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V24.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V24.LocalState.DiscordBotToken (Result Evergreen.V24.Discord.HttpError ( Evergreen.V24.Discord.User, List Evergreen.V24.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId)
        (Result
            Evergreen.V24.Discord.HttpError
            (List
                ( Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.GuildId
                , { guild : Evergreen.V24.Discord.Guild
                  , members : List Evergreen.V24.Discord.GuildMember
                  , channels : List Evergreen.V24.Discord.Channel2
                  , icon : Maybe Evergreen.V24.FileStatus.FileHash
                  }
                )
            )
        )
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V24.Discord.HttpError Evergreen.V24.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V24.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V24.DmChannel.DmChannelId Int (Result Evergreen.V24.Discord.HttpError Evergreen.V24.Discord.Message)
    | GotDiscordUserAvatars Effect.Time.Posix (Result Evergreen.V24.Discord.HttpError (List ( Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId, Maybe Evergreen.V24.FileStatus.FileHash )))


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
    | AdminToFrontend Evergreen.V24.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V24.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V24.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V24.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
