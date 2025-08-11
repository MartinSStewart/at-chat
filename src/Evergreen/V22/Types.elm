module Evergreen.V22.Types exposing (..)

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
import Evergreen.V22.AiChat
import Evergreen.V22.ChannelName
import Evergreen.V22.Coord
import Evergreen.V22.CssPixels
import Evergreen.V22.Discord
import Evergreen.V22.Discord.Id
import Evergreen.V22.DmChannel
import Evergreen.V22.Editable
import Evergreen.V22.EmailAddress
import Evergreen.V22.Emoji
import Evergreen.V22.FileStatus
import Evergreen.V22.GuildName
import Evergreen.V22.Id
import Evergreen.V22.Local
import Evergreen.V22.LocalState
import Evergreen.V22.Log
import Evergreen.V22.LoginForm
import Evergreen.V22.MessageInput
import Evergreen.V22.NonemptyDict
import Evergreen.V22.NonemptySet
import Evergreen.V22.OneToOne
import Evergreen.V22.Pages.Admin
import Evergreen.V22.PersonName
import Evergreen.V22.Ports
import Evergreen.V22.Postmark
import Evergreen.V22.RichText
import Evergreen.V22.Route
import Evergreen.V22.SecretId
import Evergreen.V22.Touch
import Evergreen.V22.TwoFactorAuthentication
import Evergreen.V22.Ui.Anim
import Evergreen.V22.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V22.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.DmChannel.DmChannel
    , user : Evergreen.V22.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V22.Route.Route
    , windowSize : Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V22.Ports.NotificationPermission
    , pwaStatus : Evergreen.V22.Ports.PwaStatus
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V22.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V22.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) Evergreen.V22.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) Evergreen.V22.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V22.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V22.User.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V22.User.GuildOrDmId Int Evergreen.V22.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V22.User.GuildOrDmId Int Evergreen.V22.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V22.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText) (SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) Evergreen.V22.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V22.User.GuildOrDmId Int
    | Local_SetLastViewed Evergreen.V22.User.GuildOrDmId Int
    | Local_DeleteMessage Evergreen.V22.User.GuildOrDmId Int
    | Local_ViewChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | Local_SetName Evergreen.V22.PersonName.PersonName


type alias MessageId =
    { guildId : Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId
    , channelId : Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId
    , messageIndex : Int
    }


type ServerChange
    = Server_SendMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Effect.Time.Posix Evergreen.V22.User.GuildOrDmId (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText) (Maybe Int) (SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) Evergreen.V22.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) Evergreen.V22.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V22.LocalState.JoinGuildError
            { guildId : Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId
            , guild : Evergreen.V22.LocalState.FrontendGuild
            , owner : Evergreen.V22.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.GuildOrDmId Int Evergreen.V22.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.GuildOrDmId Int Evergreen.V22.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.GuildOrDmId Int (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText) (SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) Evergreen.V22.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.GuildOrDmId Int
    | Server_DeleteMessage (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.GuildOrDmId Int
    | Server_DiscordDeleteMessage MessageId
    | Server_SetName (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.MessageId) (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (List.Nonempty.Nonempty Evergreen.V22.RichText.RichText)


type LocalMsg
    = LocalChange (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V22.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V22.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V22.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V22.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V22.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V22.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V22.User.GuildOrDmId
    , messageIndex : Int
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V22.User.GuildOrDmId Int
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V22.User.GuildOrDmId Int
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Int
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) Evergreen.V22.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V22.User.GuildOrDmId
    , messages : SeqDict.SeqDict Int (Evergreen.V22.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V22.Editable.Model
    , botToken : Evergreen.V22.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V22.Local.Local LocalMsg Evergreen.V22.LocalState.LocalState
    , admin : Maybe Evergreen.V22.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V22.User.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId, Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId, Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V22.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V22.User.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V22.User.GuildOrDmId Int
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V22.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V22.User.GuildOrDmId (Evergreen.V22.NonemptyDict.NonemptyDict (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) Evergreen.V22.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V22.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V22.NonemptyDict.NonemptyDict Int Evergreen.V22.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V22.NonemptyDict.NonemptyDict Int Evergreen.V22.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V22.Route.Route
    , time : Effect.Time.Posix
    , windowSize : Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V22.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V22.Ports.NotificationPermission
    , pwaStatus : Evergreen.V22.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V22.AiChat.FrontendModel
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V22.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V22.EmailAddress.EmailAddress
        }


type alias BackendModel =
    { users : Evergreen.V22.NonemptyDict.NonemptyDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V22.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V22.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) Evergreen.V22.LocalState.BackendGuild
    , discordModel : Evergreen.V22.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V22.OneToOne.OneToOne (Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId)
    , discordUsers : Evergreen.V22.OneToOne.OneToOne (Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.UserId) (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    , discordBotId : Maybe (Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V22.DmChannel.DmChannelId Evergreen.V22.DmChannel.DmChannel
    , discordDms : Evergreen.V22.OneToOne.OneToOne (Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.ChannelId) Evergreen.V22.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V22.LocalState.DiscordBotToken
    , files :
        SeqDict.SeqDict
            Evergreen.V22.FileStatus.FileHash
            { fileSize : Int
            }
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V22.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V22.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V22.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V22.Route.Route
    | TypedMessage Evergreen.V22.User.GuildOrDmId String
    | PressedSendMessage Evergreen.V22.User.GuildOrDmId
    | PressedAttachFiles Evergreen.V22.User.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V22.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | MouseExitedChannelName (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | EditChannelFormChanged (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V22.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V22.User.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V22.User.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MouseEnteredMessage Int
    | MouseExitedMessage Int
    | AltPressedMessage Int (Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels)
    | MessageMenu_PressedShowReactionEmojiSelector Int (Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Int
    | PressedEmojiSelectorEmoji Evergreen.V22.Emoji.Emoji
    | PressedReactionEmoji_Add Int Evergreen.V22.Emoji.Emoji
    | PressedReactionEmoji_Remove Int Evergreen.V22.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V22.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V22.User.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V22.User.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V22.User.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V22.User.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V22.User.GuildOrDmId
    | MessageMenu_PressedReply Int
    | PressedCloseReplyTo Evergreen.V22.User.GuildOrDmId
    | PressedSpoiler Int Int
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V22.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V22.Ports.PwaStatus
    | TouchStart Effect.Time.Posix (Evergreen.V22.NonemptyDict.NonemptyDict Int Evergreen.V22.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V22.NonemptyDict.NonemptyDict Int Evergreen.V22.Touch.Touch)
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
    | MessageMenu_PressedShowFullMenu Int (Evergreen.V22.Coord.Coord Evergreen.V22.CssPixels.CssPixels)
    | MessageMenu_PressedDeleteMessage Evergreen.V22.User.GuildOrDmId Int
    | PressedReplyLink Int
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V22.User.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Int
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V22.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V22.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V22.Editable.Msg Evergreen.V22.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V22.Editable.Msg (Maybe Evergreen.V22.LocalState.DiscordBotToken))
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V22.User.GuildOrDmId (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) (Result Effect.Http.Error String)
    | PressedDeleteAttachedFile Evergreen.V22.User.GuildOrDmId (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V22.User.GuildOrDmId (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V22.User.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V22.User.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V22.User.GuildOrDmId Int (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) (Result Effect.Http.Error String)
    | EditMessage_PastedFiles Evergreen.V22.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V22.User.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V22.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V22.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V22.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V22.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V22.PersonName.PersonName
    | AiChatToBackend Evergreen.V22.AiChat.ToBackend
    | ReloadDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V22.EmailAddress.EmailAddress (Result Evergreen.V22.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V22.EmailAddress.EmailAddress (Result Evergreen.V22.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V22.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V22.LocalState.DiscordBotToken (Result Evergreen.V22.Discord.HttpError ( Evergreen.V22.Discord.User, List Evergreen.V22.Discord.PartialGuild ))
    | GotDiscordGuilds Effect.Time.Posix (Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.UserId) (Result Evergreen.V22.Discord.HttpError (List ( Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.GuildId, ( Evergreen.V22.Discord.Guild, List Evergreen.V22.Discord.GuildMember, List Evergreen.V22.Discord.Channel2 ) )))
    | SentGuildMessageToDiscord MessageId (Result Evergreen.V22.Discord.HttpError Evergreen.V22.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V22.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V22.DmChannel.DmChannelId Int (Result Evergreen.V22.Discord.HttpError Evergreen.V22.Discord.Message)


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
    | AdminToFrontend Evergreen.V22.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V22.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V22.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V22.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
