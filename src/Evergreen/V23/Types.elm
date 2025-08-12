module Evergreen.V23.Types exposing (..)

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
import Evergreen.V23.AiChat
import Evergreen.V23.ChannelName
import Evergreen.V23.Coord
import Evergreen.V23.CssPixels
import Evergreen.V23.Discord
import Evergreen.V23.Discord.Id
import Evergreen.V23.DmChannel
import Evergreen.V23.Editable
import Evergreen.V23.EmailAddress
import Evergreen.V23.Emoji
import Evergreen.V23.FileStatus
import Evergreen.V23.GuildName
import Evergreen.V23.Id
import Evergreen.V23.Local
import Evergreen.V23.LocalState
import Evergreen.V23.Log
import Evergreen.V23.LoginForm
import Evergreen.V23.MessageInput
import Evergreen.V23.NonemptyDict
import Evergreen.V23.NonemptySet
import Evergreen.V23.OneToOne
import Evergreen.V23.Pages.Admin
import Evergreen.V23.PersonName
import Evergreen.V23.Ports
import Evergreen.V23.Postmark
import Evergreen.V23.RichText
import Evergreen.V23.Route
import Evergreen.V23.SecretId
import Evergreen.V23.Touch
import Evergreen.V23.TwoFactorAuthentication
import Evergreen.V23.Ui.Anim
import Evergreen.V23.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V23.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) Evergreen.V23.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.DmChannel.DmChannel
    , user : Evergreen.V23.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V23.Route.Route
    , windowSize : Evergreen.V23.Coord.Coord Evergreen.V23.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V23.Ports.NotificationPermission
    , pwaStatus : Evergreen.V23.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V23.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V23.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V23.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) Evergreen.V23.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) Evergreen.V23.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId) Evergreen.V23.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V23.SecretId.SecretId Evergreen.V23.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V23.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V23.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V23.User.GuildOrDmId Int Evergreen.V23.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V23.User.GuildOrDmId Int Evergreen.V23.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V23.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V23.RichText.RichText) (SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) Evergreen.V23.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V23.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V23.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V23.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | Local_SetName Evergreen.V23.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId
    , channelId : Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Effect.Time.Posix Evergreen.V23.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V23.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) Evergreen.V23.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) Evergreen.V23.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId) Evergreen.V23.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.SecretId.SecretId Evergreen.V23.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) Evergreen.V23.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V23.LocalState.JoinGuildError
            { guildId : Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId
            , guild : Evergreen.V23.LocalState.FrontendGuild
            , owner : Evergreen.V23.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.GuildOrDmId Int Evergreen.V23.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.GuildOrDmId Int Evergreen.V23.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V23.RichText.RichText) (SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) Evergreen.V23.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.MessageId) (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) (List.Nonempty.Nonempty Evergreen.V23.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V23.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V23.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V23.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V23.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V23.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V23.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V23.Coord.Coord Evergreen.V23.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V23.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V23.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V23.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) Evergreen.V23.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V23.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V23.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V23.Editable.Model
    , botToken : Evergreen.V23.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V23.Local.Local LocalMsg Evergreen.V23.LocalState.LocalState
    , admin : Maybe Evergreen.V23.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V23.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId, Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId, Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V23.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V23.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V23.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V23.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V23.User.GuildOrDmId (Evergreen.V23.NonemptyDict.NonemptyDict (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) Evergreen.V23.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V23.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V23.SecretId.SecretId Evergreen.V23.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V23.NonemptyDict.NonemptyDict Int Evergreen.V23.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V23.NonemptyDict.NonemptyDict Int Evergreen.V23.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V23.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V23.Coord.Coord Evergreen.V23.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V23.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V23.Ports.NotificationPermission
    , pwaStatus : Evergreen.V23.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V23.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V23.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V23.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V23.NonemptyDict.NonemptyDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V23.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V23.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) Evergreen.V23.LocalState.BackendGuild
    , discordModel : Evergreen.V23.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V23.OneToOne.OneToOne (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId)
    , discordUsers : Evergreen.V23.OneToOne.OneToOne (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.UserId) (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , discordBotId : Maybe (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V23.DmChannel.DmChannelId Evergreen.V23.DmChannel.DmChannel
    , discordDms : Evergreen.V23.OneToOne.OneToOne (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.ChannelId) Evergreen.V23.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V23.LocalState.DiscordBotToken
    , files :
        SeqDict.SeqDict
            Evergreen.V23.FileStatus.FileHash
            { fileSize : Int
            }
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V23.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V23.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V23.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V23.Route.Route
    | TypedMessage Evergreen.V23.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V23.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V23.User.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V23.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V23.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V23.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V23.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V23.Coord.Coord Evergreen.V23.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V23.Coord.Coord Evergreen.V23.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V23.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V23.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V23.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V23.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V23.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V23.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V23.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V23.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V23.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V23.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V23.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V23.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V23.NonemptyDict.NonemptyDict Int Evergreen.V23.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V23.NonemptyDict.NonemptyDict Int Evergreen.V23.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V23.Coord.Coord Evergreen.V23.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V23.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V23.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V23.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V23.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V23.Editable.Msg Evergreen.V23.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V23.Editable.Msg (Maybe Evergreen.V23.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V23.User.GuildOrDmId (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) (Result Effect.Http.Error String)
    | PressedDeleteAttachedFile Evergreen.V23.User.GuildOrDmId (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V23.User.GuildOrDmId (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V23.User.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V23.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V23.User.GuildOrDmId Int (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) (Result Effect.Http.Error String)
    | EditMessage_PastedFiles Evergreen.V23.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V23.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V23.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V23.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V23.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V23.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.SecretId.SecretId Evergreen.V23.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V23.PersonName.PersonName
    | AiChatToBackend Evergreen.V23.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V23.EmailAddress.EmailAddress (Result Evergreen.V23.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V23.EmailAddress.EmailAddress (Result Evergreen.V23.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V23.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V23.LocalState.DiscordBotToken (Result Evergreen.V23.Discord.HttpError ( Evergreen.V23.Discord.User, List Evergreen.V23.Discord.PartialGuild ))
    | GotDiscordGuilds Effect.Time.Posix (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.UserId) (Result Evergreen.V23.Discord.HttpError (List ( Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.GuildId, ( Evergreen.V23.Discord.Guild, List Evergreen.V23.Discord.GuildMember, List Evergreen.V23.Discord.Channel2 ) )))
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V23.Discord.HttpError Evergreen.V23.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V23.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V23.DmChannel.DmChannelId Int (Result Evergreen.V23.Discord.HttpError Evergreen.V23.Discord.Message)


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
    | AdminToFrontend Evergreen.V23.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V23.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V23.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V23.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
