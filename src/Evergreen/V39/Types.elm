module Evergreen.V39.Types exposing (..)

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
import Evergreen.V39.AiChat
import Evergreen.V39.ChannelName
import Evergreen.V39.Coord
import Evergreen.V39.CssPixels
import Evergreen.V39.Discord
import Evergreen.V39.Discord.Id
import Evergreen.V39.DmChannel
import Evergreen.V39.Editable
import Evergreen.V39.EmailAddress
import Evergreen.V39.Emoji
import Evergreen.V39.FileStatus
import Evergreen.V39.GuildName
import Evergreen.V39.Id
import Evergreen.V39.Local
import Evergreen.V39.LocalState
import Evergreen.V39.Log
import Evergreen.V39.LoginForm
import Evergreen.V39.MessageInput
import Evergreen.V39.MessageView
import Evergreen.V39.NonemptyDict
import Evergreen.V39.NonemptySet
import Evergreen.V39.OneToOne
import Evergreen.V39.Pages.Admin
import Evergreen.V39.PersonName
import Evergreen.V39.Ports
import Evergreen.V39.Postmark
import Evergreen.V39.RichText
import Evergreen.V39.Route
import Evergreen.V39.SecretId
import Evergreen.V39.Touch
import Evergreen.V39.TwoFactorAuthentication
import Evergreen.V39.Ui.Anim
import Evergreen.V39.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V39.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) Evergreen.V39.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.DmChannel.DmChannel
    , user : Evergreen.V39.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V39.Route.Route
    , windowSize : Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V39.Ports.NotificationPermission
    , pwaStatus : Evergreen.V39.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V39.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V39.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V39.RichText.RichText) Evergreen.V39.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Evergreen.V39.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) Evergreen.V39.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) Evergreen.V39.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V39.SecretId.SecretId Evergreen.V39.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V39.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V39.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V39.Id.GuildOrDmIdNoThread Evergreen.V39.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V39.RichText.RichText) (SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Evergreen.V39.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V39.Id.GuildOrDmIdNoThread Evergreen.V39.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V39.Id.GuildOrDmIdNoThread Evergreen.V39.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | Local_ViewChannel (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    | Local_SetName Evergreen.V39.PersonName.PersonName


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId
    , channelId : Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId
    , messageIndex : Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Effect.Time.Posix Evergreen.V39.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V39.RichText.RichText) Evergreen.V39.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Evergreen.V39.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) Evergreen.V39.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) Evergreen.V39.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.SecretId.SecretId Evergreen.V39.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) Evergreen.V39.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V39.LocalState.JoinGuildError
            { guildId : Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId
            , guild : Evergreen.V39.LocalState.FrontendGuild
            , owner : Evergreen.V39.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.Id.GuildOrDmIdNoThread Evergreen.V39.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V39.RichText.RichText) (SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Evergreen.V39.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.Id.GuildOrDmIdNoThread Evergreen.V39.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.MessageId) (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (List.Nonempty.Nonempty Evergreen.V39.RichText.RichText) (Maybe (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalMsg
    = LocalChange (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V39.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V39.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V39.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V39.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V39.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V39.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V39.Id.GuildOrDmId
    , isThreadStarter : Bool
    , messageIndex : Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Evergreen.V39.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V39.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Evergreen.V39.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V39.Editable.Model
    , botToken : Evergreen.V39.Editable.Model
    , publicVapidKey : Evergreen.V39.Editable.Model
    , privateVapidKey : Evergreen.V39.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V39.Local.Local LocalMsg Evergreen.V39.LocalState.LocalState
    , admin : Maybe Evergreen.V39.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V39.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId, Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId, Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId, Evergreen.V39.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V39.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V39.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V39.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.NonemptyDict.NonemptyDict (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Evergreen.V39.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V39.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V39.SecretId.SecretId Evergreen.V39.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V39.NonemptyDict.NonemptyDict Int Evergreen.V39.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V39.NonemptyDict.NonemptyDict Int Evergreen.V39.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V39.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V39.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V39.Ports.NotificationPermission
    , pwaStatus : Evergreen.V39.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V39.AiChat.FrontendModel
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
    , userId : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V39.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V39.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V39.NonemptyDict.NonemptyDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V39.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V39.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) Evergreen.V39.LocalState.BackendGuild
    , discordModel : Evergreen.V39.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId)
    , discordUsers : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.UserId) (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
    , discordBotId : Maybe (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V39.DmChannel.DmChannelId Evergreen.V39.DmChannel.DmChannel
    , discordDms : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.ChannelId) Evergreen.V39.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V39.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V39.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V39.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V39.Ports.PushSubscription
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V39.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V39.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V39.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V39.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V39.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V39.Id.GuildOrDmIdNoThread Evergreen.V39.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V39.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V39.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) Evergreen.V39.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) Evergreen.V39.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V39.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V39.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V39.Id.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | PressedEmojiSelectorEmoji Evergreen.V39.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V39.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V39.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V39.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V39.Id.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V39.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V39.Id.GuildOrDmId
    | MessageMenu_PressedReply (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | MessageMenu_PressedOpenThread (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V39.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V39.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V39.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V39.Id.GuildOrDmId, Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId, Bool )) Effect.Time.Posix (Evergreen.V39.NonemptyDict.NonemptyDict Int Evergreen.V39.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V39.NonemptyDict.NonemptyDict Int Evergreen.V39.Touch.Touch)
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
    | MessageMenu_PressedDeleteMessage Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V39.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V39.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V39.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V39.Editable.Msg Evergreen.V39.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V39.Editable.Msg (Maybe Evergreen.V39.LocalState.DiscordBotToken))
    | PublicVapidKeyEditableMsg (Evergreen.V39.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V39.Editable.Msg Evergreen.V39.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V39.FileStatus.FileHash, Maybe (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V39.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V39.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V39.FileStatus.FileHash, Maybe (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V39.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V39.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V39.Id.GuildOrDmId (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V39.Id.GuildOrDmId Evergreen.V39.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V39.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V39.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V39.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V39.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V39.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.SecretId.SecretId Evergreen.V39.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V39.PersonName.PersonName
    | AiChatToBackend Evergreen.V39.AiChat.ToBackend
    | ReloadDataRequest
    | RegisterPushSubscriptionRequest Evergreen.V39.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V39.EmailAddress.EmailAddress (Result Evergreen.V39.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V39.EmailAddress.EmailAddress (Result Evergreen.V39.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V39.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V39.LocalState.DiscordBotToken (Result Evergreen.V39.Discord.HttpError ( Evergreen.V39.Discord.User, List Evergreen.V39.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.UserId)
        (Result
            Evergreen.V39.Discord.HttpError
            (List
                ( Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.GuildId
                , { guild : Evergreen.V39.Discord.Guild
                  , members : List Evergreen.V39.Discord.GuildMember
                  , channels : List ( Evergreen.V39.Discord.Channel2, List Evergreen.V39.Discord.Message )
                  , icon : Maybe ( Evergreen.V39.FileStatus.FileHash, Maybe (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V39.Discord.Channel, List Evergreen.V39.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) Evergreen.V39.Id.ThreadRouteWithMessage (Result Evergreen.V39.Discord.HttpError Evergreen.V39.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V39.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V39.DmChannel.DmChannelId (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Result Evergreen.V39.Discord.HttpError Evergreen.V39.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V39.Discord.HttpError (List ( Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.UserId, Maybe ( Evergreen.V39.FileStatus.FileHash, Maybe (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels) ) )))
    | SentNotification (Result Effect.Http.Error ())
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
    | AdminToFrontend Evergreen.V39.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V39.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V39.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V39.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
