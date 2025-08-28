module Evergreen.V38.Types exposing (..)

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
import Evergreen.V38.AiChat
import Evergreen.V38.ChannelName
import Evergreen.V38.Coord
import Evergreen.V38.CssPixels
import Evergreen.V38.Discord
import Evergreen.V38.Discord.Id
import Evergreen.V38.DmChannel
import Evergreen.V38.Editable
import Evergreen.V38.EmailAddress
import Evergreen.V38.Emoji
import Evergreen.V38.FileStatus
import Evergreen.V38.GuildName
import Evergreen.V38.Id
import Evergreen.V38.Local
import Evergreen.V38.LocalState
import Evergreen.V38.Log
import Evergreen.V38.LoginForm
import Evergreen.V38.MessageInput
import Evergreen.V38.MessageView
import Evergreen.V38.NonemptyDict
import Evergreen.V38.NonemptySet
import Evergreen.V38.OneToOne
import Evergreen.V38.Pages.Admin
import Evergreen.V38.PersonName
import Evergreen.V38.Ports
import Evergreen.V38.Postmark
import Evergreen.V38.RichText
import Evergreen.V38.Route
import Evergreen.V38.SecretId
import Evergreen.V38.Touch
import Evergreen.V38.TwoFactorAuthentication
import Evergreen.V38.Ui.Anim
import Evergreen.V38.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V38.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) Evergreen.V38.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.DmChannel.DmChannel
    , user : Evergreen.V38.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V38.Route.Route
    , windowSize : Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V38.Ports.NotificationPermission
    , pwaStatus : Evergreen.V38.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V38.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V38.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V38.RichText.RichText) Evergreen.V38.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Evergreen.V38.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) Evergreen.V38.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) Evergreen.V38.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V38.SecretId.SecretId Evergreen.V38.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V38.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V38.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V38.Id.GuildOrDmIdNoThread Evergreen.V38.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V38.RichText.RichText) (SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Evergreen.V38.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V38.Id.GuildOrDmIdNoThread Evergreen.V38.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V38.Id.GuildOrDmIdNoThread Evergreen.V38.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | Local_ViewChannel (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    | Local_SetName Evergreen.V38.PersonName.PersonName


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId
    , channelId : Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId
    , messageIndex : Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Effect.Time.Posix Evergreen.V38.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V38.RichText.RichText) Evergreen.V38.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Evergreen.V38.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) Evergreen.V38.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) Evergreen.V38.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.SecretId.SecretId Evergreen.V38.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) Evergreen.V38.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V38.LocalState.JoinGuildError
            { guildId : Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId
            , guild : Evergreen.V38.LocalState.FrontendGuild
            , owner : Evergreen.V38.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.Id.GuildOrDmIdNoThread Evergreen.V38.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V38.RichText.RichText) (SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Evergreen.V38.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.Id.GuildOrDmIdNoThread Evergreen.V38.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.MessageId) (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (List.Nonempty.Nonempty Evergreen.V38.RichText.RichText) (Maybe (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalMsg
    = LocalChange (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V38.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V38.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V38.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V38.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V38.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V38.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V38.Id.GuildOrDmId
    , isThreadStarter : Bool
    , messageIndex : Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Evergreen.V38.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V38.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Evergreen.V38.NonemptySet.NonemptySet Int)
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
    { name : Evergreen.V38.Editable.Model
    , botToken : Evergreen.V38.Editable.Model
    , publicVapidKey : Evergreen.V38.Editable.Model
    , privateVapidKey : Evergreen.V38.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V38.Local.Local LocalMsg Evergreen.V38.LocalState.LocalState
    , admin : Maybe Evergreen.V38.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V38.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId, Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId, Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId, Evergreen.V38.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V38.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V38.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V38.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.NonemptyDict.NonemptyDict (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Evergreen.V38.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V38.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V38.SecretId.SecretId Evergreen.V38.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V38.NonemptyDict.NonemptyDict Int Evergreen.V38.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V38.NonemptyDict.NonemptyDict Int Evergreen.V38.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V38.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V38.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V38.Ports.NotificationPermission
    , pwaStatus : Evergreen.V38.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V38.AiChat.FrontendModel
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
    , userId : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V38.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V38.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V38.NonemptyDict.NonemptyDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V38.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V38.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) Evergreen.V38.LocalState.BackendGuild
    , discordModel : Evergreen.V38.Discord.Model Effect.Websocket.Connection
    , discordNotConnected : Bool
    , discordGuilds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId)
    , discordUsers : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.UserId) (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
    , discordBotId : Maybe (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V38.DmChannel.DmChannelId Evergreen.V38.DmChannel.DmChannel
    , discordDms : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.ChannelId) Evergreen.V38.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V38.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V38.FileStatus.FileHash BackendFileData
    , privateVapidKey : String
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V38.Ports.PushSubscription
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V38.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V38.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V38.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V38.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V38.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V38.Id.GuildOrDmIdNoThread Evergreen.V38.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V38.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V38.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) Evergreen.V38.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) Evergreen.V38.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V38.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V38.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V38.Id.GuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | PressedEmojiSelectorEmoji Evergreen.V38.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V38.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V38.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V38.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V38.Id.GuildOrDmId Int
    | PressedPingUserForEditMessage Evergreen.V38.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V38.Id.GuildOrDmId
    | MessageMenu_PressedReply (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | MessageMenu_PressedOpenThread (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V38.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V38.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V38.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V38.Id.GuildOrDmId, Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId, Bool )) Effect.Time.Posix (Evergreen.V38.NonemptyDict.NonemptyDict Int Evergreen.V38.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V38.NonemptyDict.NonemptyDict Int Evergreen.V38.Touch.Touch)
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
    | MessageMenu_PressedDeleteMessage Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V38.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V38.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V38.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V38.Editable.Msg Evergreen.V38.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V38.Editable.Msg (Maybe Evergreen.V38.LocalState.DiscordBotToken))
    | PublicVapidKeyEditableMsg (Evergreen.V38.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V38.Editable.Msg String)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V38.FileStatus.FileHash, Maybe (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V38.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V38.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V38.FileStatus.FileHash, Maybe (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V38.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V38.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V38.Id.GuildOrDmId (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V38.Id.GuildOrDmId Evergreen.V38.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V38.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V38.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V38.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V38.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V38.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.SecretId.SecretId Evergreen.V38.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V38.PersonName.PersonName
    | AiChatToBackend Evergreen.V38.AiChat.ToBackend
    | ReloadDataRequest
    | RegisterPushSubscriptionRequest Evergreen.V38.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V38.EmailAddress.EmailAddress (Result Evergreen.V38.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V38.EmailAddress.EmailAddress (Result Evergreen.V38.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V38.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V38.LocalState.DiscordBotToken (Result Evergreen.V38.Discord.HttpError ( Evergreen.V38.Discord.User, List Evergreen.V38.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.UserId)
        (Result
            Evergreen.V38.Discord.HttpError
            (List
                ( Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.GuildId
                , { guild : Evergreen.V38.Discord.Guild
                  , members : List Evergreen.V38.Discord.GuildMember
                  , channels : List ( Evergreen.V38.Discord.Channel2, List Evergreen.V38.Discord.Message )
                  , icon : Maybe ( Evergreen.V38.FileStatus.FileHash, Maybe (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V38.Discord.Channel, List Evergreen.V38.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) Evergreen.V38.Id.ThreadRouteWithMessage (Result Evergreen.V38.Discord.HttpError Evergreen.V38.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V38.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V38.DmChannel.DmChannelId (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Result Evergreen.V38.Discord.HttpError Evergreen.V38.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V38.Discord.HttpError (List ( Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.UserId, Maybe ( Evergreen.V38.FileStatus.FileHash, Maybe (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels) ) )))
    | SentNotification (Result Effect.Http.Error ())


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
    | AdminToFrontend Evergreen.V38.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V38.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V38.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V38.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
