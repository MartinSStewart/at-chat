module Evergreen.V42.Types exposing (..)

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
import Evergreen.V42.AiChat
import Evergreen.V42.ChannelName
import Evergreen.V42.Coord
import Evergreen.V42.CssPixels
import Evergreen.V42.Discord
import Evergreen.V42.Discord.Id
import Evergreen.V42.DmChannel
import Evergreen.V42.Editable
import Evergreen.V42.EmailAddress
import Evergreen.V42.Emoji
import Evergreen.V42.FileStatus
import Evergreen.V42.GuildName
import Evergreen.V42.Id
import Evergreen.V42.Local
import Evergreen.V42.LocalState
import Evergreen.V42.Log
import Evergreen.V42.LoginForm
import Evergreen.V42.MessageInput
import Evergreen.V42.MessageView
import Evergreen.V42.NonemptyDict
import Evergreen.V42.NonemptySet
import Evergreen.V42.OneToOne
import Evergreen.V42.Pages.Admin
import Evergreen.V42.PersonName
import Evergreen.V42.Ports
import Evergreen.V42.Postmark
import Evergreen.V42.RichText
import Evergreen.V42.Route
import Evergreen.V42.SecretId
import Evergreen.V42.Touch
import Evergreen.V42.TwoFactorAuthentication
import Evergreen.V42.Ui.Anim
import Evergreen.V42.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V42.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) Evergreen.V42.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.DmChannel.DmChannel
    , user : Evergreen.V42.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V42.Route.Route
    , windowSize : Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V42.Ports.NotificationPermission
    , pwaStatus : Evergreen.V42.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V42.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V42.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V42.RichText.RichText) Evergreen.V42.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Evergreen.V42.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) Evergreen.V42.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) Evergreen.V42.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V42.SecretId.SecretId Evergreen.V42.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V42.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V42.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V42.Id.GuildOrDmIdNoThread Evergreen.V42.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V42.RichText.RichText) (SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Evergreen.V42.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V42.Id.GuildOrDmIdNoThread Evergreen.V42.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V42.Id.GuildOrDmIdNoThread Evergreen.V42.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | Local_ViewChannel (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    | Local_SetName Evergreen.V42.PersonName.PersonName


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId
    , channelId : Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId
    , messageIndex : Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Effect.Time.Posix Evergreen.V42.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V42.RichText.RichText) Evergreen.V42.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Evergreen.V42.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) Evergreen.V42.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) Evergreen.V42.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.SecretId.SecretId Evergreen.V42.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) Evergreen.V42.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V42.LocalState.JoinGuildError
            { guildId : Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId
            , guild : Evergreen.V42.LocalState.FrontendGuild
            , owner : Evergreen.V42.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Id.GuildOrDmIdNoThread Evergreen.V42.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V42.RichText.RichText) (SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Evergreen.V42.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Id.GuildOrDmIdNoThread Evergreen.V42.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.MessageId) (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (List.Nonempty.Nonempty Evergreen.V42.RichText.RichText) (Maybe (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalMsg
    = LocalChange (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V42.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V42.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V42.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V42.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V42.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V42.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V42.Id.GuildOrDmId
    , isThreadStarter : Bool
    , messageIndex : Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Evergreen.V42.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V42.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Evergreen.V42.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V42.Editable.Model
    , botToken : Evergreen.V42.Editable.Model
    , publicVapidKey : Evergreen.V42.Editable.Model
    , privateVapidKey : Evergreen.V42.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V42.Local.Local LocalMsg Evergreen.V42.LocalState.LocalState
    , admin : Maybe Evergreen.V42.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V42.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId, Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId, Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId, Evergreen.V42.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V42.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V42.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V42.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.NonemptyDict.NonemptyDict (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Evergreen.V42.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V42.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V42.SecretId.SecretId Evergreen.V42.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V42.NonemptyDict.NonemptyDict Int Evergreen.V42.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V42.NonemptyDict.NonemptyDict Int Evergreen.V42.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V42.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V42.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V42.Ports.NotificationPermission
    , pwaStatus : Evergreen.V42.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V42.AiChat.FrontendModel
    , enabledPushNotifications : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V42.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V42.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V42.NonemptyDict.NonemptyDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V42.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V42.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) Evergreen.V42.LocalState.BackendGuild
    , discordModel : Evergreen.V42.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId)
    , discordUsers : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.UserId) (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    , discordBotId : Maybe (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V42.DmChannel.DmChannelId Evergreen.V42.DmChannel.DmChannel
    , discordDms : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.ChannelId) Evergreen.V42.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V42.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V42.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V42.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V42.Ports.PushSubscription
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V42.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V42.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V42.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V42.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V42.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V42.Id.GuildOrDmIdNoThread Evergreen.V42.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V42.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V42.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) Evergreen.V42.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) Evergreen.V42.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V42.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V42.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V42.Id.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | PressedEmojiSelectorEmoji Evergreen.V42.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V42.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V42.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V42.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V42.Id.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V42.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V42.Id.GuildOrDmId
    | MessageMenu_PressedReply (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | MessageMenu_PressedOpenThread (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V42.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V42.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V42.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V42.Id.GuildOrDmId, Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId, Bool )) Effect.Time.Posix (Evergreen.V42.NonemptyDict.NonemptyDict Int Evergreen.V42.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V42.NonemptyDict.NonemptyDict Int Evergreen.V42.Touch.Touch)
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
    | MessageMenu_PressedDeleteMessage Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V42.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V42.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V42.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V42.Editable.Msg Evergreen.V42.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V42.Editable.Msg (Maybe Evergreen.V42.LocalState.DiscordBotToken))
    | PublicVapidKeyEditableMsg (Evergreen.V42.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V42.Editable.Msg Evergreen.V42.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V42.FileStatus.FileHash, Maybe (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V42.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V42.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V42.FileStatus.FileHash, Maybe (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V42.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V42.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V42.Id.GuildOrDmId (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V42.Id.GuildOrDmId Evergreen.V42.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V42.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V42.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V42.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V42.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V42.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.SecretId.SecretId Evergreen.V42.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V42.PersonName.PersonName
    | AiChatToBackend Evergreen.V42.AiChat.ToBackend
    | ReloadDataRequest
    | RegisterPushSubscriptionRequest Evergreen.V42.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V42.EmailAddress.EmailAddress (Result Evergreen.V42.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V42.EmailAddress.EmailAddress (Result Evergreen.V42.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V42.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V42.LocalState.DiscordBotToken (Result Evergreen.V42.Discord.HttpError ( Evergreen.V42.Discord.User, List Evergreen.V42.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.UserId)
        (Result
            Evergreen.V42.Discord.HttpError
            (List
                ( Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.GuildId
                , { guild : Evergreen.V42.Discord.Guild
                  , members : List Evergreen.V42.Discord.GuildMember
                  , channels : List ( Evergreen.V42.Discord.Channel2, List Evergreen.V42.Discord.Message )
                  , icon : Maybe ( Evergreen.V42.FileStatus.FileHash, Maybe (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V42.Discord.Channel, List Evergreen.V42.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) Evergreen.V42.Id.ThreadRouteWithMessage (Result Evergreen.V42.Discord.HttpError Evergreen.V42.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V42.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V42.DmChannel.DmChannelId (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Result Evergreen.V42.Discord.HttpError Evergreen.V42.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V42.Discord.HttpError (List ( Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.UserId, Maybe ( Evergreen.V42.FileStatus.FileHash, Maybe (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels) ) )))
    | SentNotification Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)


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
    | AdminToFrontend Evergreen.V42.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V42.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V42.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V42.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
