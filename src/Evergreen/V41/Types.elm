module Evergreen.V41.Types exposing (..)

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
import Evergreen.V41.AiChat
import Evergreen.V41.ChannelName
import Evergreen.V41.Coord
import Evergreen.V41.CssPixels
import Evergreen.V41.Discord
import Evergreen.V41.Discord.Id
import Evergreen.V41.DmChannel
import Evergreen.V41.Editable
import Evergreen.V41.EmailAddress
import Evergreen.V41.Emoji
import Evergreen.V41.FileStatus
import Evergreen.V41.GuildName
import Evergreen.V41.Id
import Evergreen.V41.Local
import Evergreen.V41.LocalState
import Evergreen.V41.Log
import Evergreen.V41.LoginForm
import Evergreen.V41.MessageInput
import Evergreen.V41.MessageView
import Evergreen.V41.NonemptyDict
import Evergreen.V41.NonemptySet
import Evergreen.V41.OneToOne
import Evergreen.V41.Pages.Admin
import Evergreen.V41.PersonName
import Evergreen.V41.Ports
import Evergreen.V41.Postmark
import Evergreen.V41.RichText
import Evergreen.V41.Route
import Evergreen.V41.SecretId
import Evergreen.V41.Touch
import Evergreen.V41.TwoFactorAuthentication
import Evergreen.V41.Ui.Anim
import Evergreen.V41.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V41.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) Evergreen.V41.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.DmChannel.DmChannel
    , user : Evergreen.V41.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V41.Route.Route
    , windowSize : Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V41.Ports.NotificationPermission
    , pwaStatus : Evergreen.V41.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V41.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V41.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V41.RichText.RichText) Evergreen.V41.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Evergreen.V41.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) Evergreen.V41.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) Evergreen.V41.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V41.SecretId.SecretId Evergreen.V41.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V41.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V41.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V41.Id.GuildOrDmIdNoThread Evergreen.V41.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V41.RichText.RichText) (SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Evergreen.V41.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V41.Id.GuildOrDmIdNoThread Evergreen.V41.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V41.Id.GuildOrDmIdNoThread Evergreen.V41.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | Local_ViewChannel (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    | Local_SetName Evergreen.V41.PersonName.PersonName


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId
    , channelId : Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId
    , messageIndex : Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Effect.Time.Posix Evergreen.V41.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V41.RichText.RichText) Evergreen.V41.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Evergreen.V41.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) Evergreen.V41.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) Evergreen.V41.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.SecretId.SecretId Evergreen.V41.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) Evergreen.V41.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V41.LocalState.JoinGuildError
            { guildId : Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId
            , guild : Evergreen.V41.LocalState.FrontendGuild
            , owner : Evergreen.V41.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.Id.GuildOrDmIdNoThread Evergreen.V41.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V41.RichText.RichText) (SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Evergreen.V41.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.Id.GuildOrDmIdNoThread Evergreen.V41.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.MessageId) (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (List.Nonempty.Nonempty Evergreen.V41.RichText.RichText) (Maybe (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalMsg
    = LocalChange (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V41.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V41.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V41.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V41.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V41.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V41.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V41.Id.GuildOrDmId
    , isThreadStarter : Bool
    , messageIndex : Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Evergreen.V41.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V41.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Evergreen.V41.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V41.Editable.Model
    , botToken : Evergreen.V41.Editable.Model
    , publicVapidKey : Evergreen.V41.Editable.Model
    , privateVapidKey : Evergreen.V41.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V41.Local.Local LocalMsg Evergreen.V41.LocalState.LocalState
    , admin : Maybe Evergreen.V41.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V41.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId, Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId, Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId, Evergreen.V41.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V41.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V41.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V41.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.NonemptyDict.NonemptyDict (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Evergreen.V41.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V41.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V41.SecretId.SecretId Evergreen.V41.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V41.NonemptyDict.NonemptyDict Int Evergreen.V41.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V41.NonemptyDict.NonemptyDict Int Evergreen.V41.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V41.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V41.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V41.Ports.NotificationPermission
    , pwaStatus : Evergreen.V41.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V41.AiChat.FrontendModel
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
    , userId : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V41.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V41.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V41.NonemptyDict.NonemptyDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V41.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V41.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) Evergreen.V41.LocalState.BackendGuild
    , discordModel : Evergreen.V41.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId)
    , discordUsers : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.UserId) (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
    , discordBotId : Maybe (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V41.DmChannel.DmChannelId Evergreen.V41.DmChannel.DmChannel
    , discordDms : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.ChannelId) Evergreen.V41.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V41.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V41.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V41.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V41.Ports.PushSubscription
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V41.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V41.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V41.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V41.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V41.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V41.Id.GuildOrDmIdNoThread Evergreen.V41.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V41.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V41.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) Evergreen.V41.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) Evergreen.V41.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V41.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V41.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V41.Id.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | PressedEmojiSelectorEmoji Evergreen.V41.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V41.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V41.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V41.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V41.Id.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V41.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V41.Id.GuildOrDmId
    | MessageMenu_PressedReply (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | MessageMenu_PressedOpenThread (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V41.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V41.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V41.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V41.Id.GuildOrDmId, Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId, Bool )) Effect.Time.Posix (Evergreen.V41.NonemptyDict.NonemptyDict Int Evergreen.V41.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V41.NonemptyDict.NonemptyDict Int Evergreen.V41.Touch.Touch)
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
    | MessageMenu_PressedDeleteMessage Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V41.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V41.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V41.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V41.Editable.Msg Evergreen.V41.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V41.Editable.Msg (Maybe Evergreen.V41.LocalState.DiscordBotToken))
    | PublicVapidKeyEditableMsg (Evergreen.V41.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V41.Editable.Msg Evergreen.V41.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V41.FileStatus.FileHash, Maybe (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V41.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V41.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V41.FileStatus.FileHash, Maybe (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V41.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V41.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V41.Id.GuildOrDmId (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V41.Id.GuildOrDmId Evergreen.V41.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V41.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V41.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V41.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V41.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V41.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.SecretId.SecretId Evergreen.V41.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V41.PersonName.PersonName
    | AiChatToBackend Evergreen.V41.AiChat.ToBackend
    | ReloadDataRequest
    | RegisterPushSubscriptionRequest Evergreen.V41.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V41.EmailAddress.EmailAddress (Result Evergreen.V41.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V41.EmailAddress.EmailAddress (Result Evergreen.V41.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V41.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V41.LocalState.DiscordBotToken (Result Evergreen.V41.Discord.HttpError ( Evergreen.V41.Discord.User, List Evergreen.V41.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.UserId)
        (Result
            Evergreen.V41.Discord.HttpError
            (List
                ( Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.GuildId
                , { guild : Evergreen.V41.Discord.Guild
                  , members : List Evergreen.V41.Discord.GuildMember
                  , channels : List ( Evergreen.V41.Discord.Channel2, List Evergreen.V41.Discord.Message )
                  , icon : Maybe ( Evergreen.V41.FileStatus.FileHash, Maybe (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V41.Discord.Channel, List Evergreen.V41.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) Evergreen.V41.Id.ThreadRouteWithMessage (Result Evergreen.V41.Discord.HttpError Evergreen.V41.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V41.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V41.DmChannel.DmChannelId (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Result Evergreen.V41.Discord.HttpError Evergreen.V41.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V41.Discord.HttpError (List ( Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.UserId, Maybe ( Evergreen.V41.FileStatus.FileHash, Maybe (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels) ) )))
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
    | AdminToFrontend Evergreen.V41.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V41.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V41.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V41.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
