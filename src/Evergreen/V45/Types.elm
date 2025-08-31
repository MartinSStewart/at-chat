module Evergreen.V45.Types exposing (..)

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
import Evergreen.V45.AiChat
import Evergreen.V45.ChannelName
import Evergreen.V45.Coord
import Evergreen.V45.CssPixels
import Evergreen.V45.Discord
import Evergreen.V45.Discord.Id
import Evergreen.V45.DmChannel
import Evergreen.V45.Editable
import Evergreen.V45.EmailAddress
import Evergreen.V45.Emoji
import Evergreen.V45.FileStatus
import Evergreen.V45.GuildName
import Evergreen.V45.Id
import Evergreen.V45.Local
import Evergreen.V45.LocalState
import Evergreen.V45.Log
import Evergreen.V45.LoginForm
import Evergreen.V45.MessageInput
import Evergreen.V45.MessageView
import Evergreen.V45.NonemptyDict
import Evergreen.V45.NonemptySet
import Evergreen.V45.OneToOne
import Evergreen.V45.Pages.Admin
import Evergreen.V45.PersonName
import Evergreen.V45.Ports
import Evergreen.V45.Postmark
import Evergreen.V45.RichText
import Evergreen.V45.Route
import Evergreen.V45.SecretId
import Evergreen.V45.Touch
import Evergreen.V45.TwoFactorAuthentication
import Evergreen.V45.Ui.Anim
import Evergreen.V45.User
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V45.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) Evergreen.V45.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.DmChannel.DmChannel
    , user : Evergreen.V45.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.User.FrontendUser
    , sessionId : Effect.Lamdera.SessionId
    , publicVapidKey : String
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V45.Route.Route
    , windowSize : Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V45.Ports.NotificationPermission
    , pwaStatus : Evergreen.V45.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , enabledPushNotifications : Bool
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V45.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V45.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V45.RichText.RichText) Evergreen.V45.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Evergreen.V45.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) Evergreen.V45.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) Evergreen.V45.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (ToBeFilledInByBackend (Evergreen.V45.SecretId.SecretId Evergreen.V45.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V45.GuildName.GuildName (ToBeFilledInByBackend (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix Evergreen.V45.Id.GuildOrDmId
    | Local_AddReactionEmoji Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Evergreen.V45.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Evergreen.V45.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V45.Id.GuildOrDmIdNoThread Evergreen.V45.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V45.RichText.RichText) (SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Evergreen.V45.FileStatus.FileData)
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V45.Id.GuildOrDmIdNoThread Evergreen.V45.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V45.Id.GuildOrDmIdNoThread Evergreen.V45.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | Local_ViewChannel (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    | Local_SetName Evergreen.V45.PersonName.PersonName


type alias GuildChannelAndMessageId =
    { guildId : Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId
    , channelId : Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId
    , messageIndex : Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId
    }


type ServerChange
    = Server_SendMessage (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Effect.Time.Posix Evergreen.V45.Id.GuildOrDmIdNoThread (List.Nonempty.Nonempty Evergreen.V45.RichText.RichText) Evergreen.V45.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Evergreen.V45.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) Evergreen.V45.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) Evergreen.V45.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.SecretId.SecretId Evergreen.V45.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) Evergreen.V45.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V45.LocalState.JoinGuildError
            { guildId : Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId
            , guild : Evergreen.V45.LocalState.FrontendGuild
            , owner : Evergreen.V45.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Id.GuildOrDmId
    | Server_AddReactionEmoji (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Evergreen.V45.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Evergreen.V45.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Id.GuildOrDmIdNoThread Evergreen.V45.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty Evergreen.V45.RichText.RichText) (SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Evergreen.V45.FileStatus.FileData)
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Id.GuildOrDmIdNoThread Evergreen.V45.Id.ThreadRouteWithMessage
    | Server_DeleteMessage (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.PersonName.PersonName
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.MessageId) (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (List.Nonempty.Nonempty Evergreen.V45.RichText.RichText) (Maybe (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalMsg
    = LocalChange (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) LocalChange
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
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V45.CssPixels.CssPixels)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V45.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V45.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V45.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V45.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V45.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V45.Id.GuildOrDmId
    , isThreadStarter : Bool
    , messageIndex : Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | EmojiSelectorForMessage


type alias EditMessage =
    { messageIndex : Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Evergreen.V45.FileStatus.FileStatus
    }


type alias RevealedSpoilers =
    { guildOrDmId : Evergreen.V45.Id.GuildOrDmId
    , messages : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) (Evergreen.V45.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ThreadMessageId) (Evergreen.V45.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V45.Editable.Model
    , botToken : Evergreen.V45.Editable.Model
    , publicVapidKey : Evergreen.V45.Editable.Model
    , privateVapidKey : Evergreen.V45.Editable.Model
    }


type alias LoggedIn2 =
    { localState : Evergreen.V45.Local.Local LocalMsg Evergreen.V45.LocalState.LocalState
    , admin : Maybe Evergreen.V45.Pages.Admin.Model
    , drafts : SeqDict.SeqDict Evergreen.V45.Id.GuildOrDmId String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId, Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId, Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId, Evergreen.V45.Id.ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V45.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict Evergreen.V45.Id.GuildOrDmId EditMessage
    , replyTo : SeqDict.SeqDict Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V45.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.NonemptyDict.NonemptyDict (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Evergreen.V45.FileStatus.FileStatus)
    , sessionId : Effect.Lamdera.SessionId
    , isReloading : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V45.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V45.SecretId.SecretId Evergreen.V45.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V45.NonemptyDict.NonemptyDict Int Evergreen.V45.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V45.NonemptyDict.NonemptyDict Int Evergreen.V45.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V45.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V45.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V45.Ports.NotificationPermission
    , pwaStatus : Evergreen.V45.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , scrolledToBottomOfChannel : Bool
    , aiChatModel : Evergreen.V45.AiChat.FrontendModel
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
    , userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V45.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V45.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels)
    }


type alias BackendModel =
    { users : Evergreen.V45.NonemptyDict.NonemptyDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V45.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V45.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) Evergreen.V45.LocalState.BackendGuild
    , discordModel : Evergreen.V45.Discord.Model Effect.Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId)
    , discordUsers : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.UserId) (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    , discordBotId : Maybe (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.UserId)
    , dmChannels : SeqDict.SeqDict Evergreen.V45.DmChannel.DmChannelId Evergreen.V45.DmChannel.DmChannel
    , discordDms : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.ChannelId) Evergreen.V45.DmChannel.DmChannelId
    , botToken : Maybe Evergreen.V45.LocalState.DiscordBotToken
    , files : SeqDict.SeqDict Evergreen.V45.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V45.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V45.Ports.PushSubscription
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V45.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V45.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V45.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V45.Route.Route
    | PressedTextInput
    | TypedMessage Evergreen.V45.Id.GuildOrDmId String
    | PressedSendMessage Evergreen.V45.Id.GuildOrDmIdNoThread Evergreen.V45.Id.ThreadRoute
    | PressedAttachFiles Evergreen.V45.Id.GuildOrDmId
    | SelectedFilesToAttach Evergreen.V45.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) Evergreen.V45.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) Evergreen.V45.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V45.MessageInput.MentionUserDropdown)
    | PressedPingUser Evergreen.V45.Id.GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V45.Id.GuildOrDmIdNoThread Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | PressedEmojiSelectorEmoji Evergreen.V45.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V45.MessageInput.MentionUserDropdown)
    | TypedEditMessage Evergreen.V45.Id.GuildOrDmId String
    | PressedSendEditMessage Evergreen.V45.Id.GuildOrDmId
    | PressedArrowInDropdownForEditMessage Evergreen.V45.Id.GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage Evergreen.V45.Id.GuildOrDmId Int
    | PressedArrowUpInEmptyInput Evergreen.V45.Id.GuildOrDmId
    | MessageMenu_PressedReply (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | MessageMenu_PressedOpenThread (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | PressedCloseReplyTo Evergreen.V45.Id.GuildOrDmId
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V45.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V45.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V45.Id.GuildOrDmId, Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId, Bool )) Effect.Time.Posix (Evergreen.V45.NonemptyDict.NonemptyDict Int Evergreen.V45.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V45.NonemptyDict.NonemptyDict Int Evergreen.V45.Touch.Touch)
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
    | MessageMenu_PressedDeleteMessage Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit Evergreen.V45.Id.GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V45.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V45.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V45.Editable.Msg Evergreen.V45.PersonName.PersonName)
    | BotTokenEditableMsg (Evergreen.V45.Editable.Msg (Maybe Evergreen.V45.LocalState.DiscordBotToken))
    | PublicVapidKeyEditableMsg (Evergreen.V45.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V45.Editable.Msg Evergreen.V45.LocalState.PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V45.FileStatus.FileHash, Maybe (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels) ))
    | PressedDeleteAttachedFile Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId)
    | EditMessage_PressedAttachFiles Evergreen.V45.Id.GuildOrDmId
    | EditMessage_SelectedFilesToAttach Evergreen.V45.Id.GuildOrDmId Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) (Result Effect.Http.Error ( Evergreen.V45.FileStatus.FileHash, Maybe (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels) ))
    | EditMessage_PastedFiles Evergreen.V45.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles Evergreen.V45.Id.GuildOrDmId (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress Evergreen.V45.Id.GuildOrDmId (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V45.Id.GuildOrDmIdNoThread Evergreen.V45.Id.ThreadRouteWithMessage Evergreen.V45.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V45.Ports.PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest Evergreen.V45.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V45.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V45.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V45.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.SecretId.SecretId Evergreen.V45.Id.InviteLinkId)
    | FinishUserCreationRequest Evergreen.V45.PersonName.PersonName
    | AiChatToBackend Evergreen.V45.AiChat.ToBackend
    | ReloadDataRequest
    | RegisterPushSubscriptionRequest Evergreen.V45.Ports.PushSubscription
    | UnregisterPushSubscriptionRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V45.EmailAddress.EmailAddress (Result Evergreen.V45.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V45.EmailAddress.EmailAddress (Result Evergreen.V45.Postmark.SendEmailError ())
    | WebsocketCreatedHandle Effect.Websocket.Connection
    | WebsocketSentData (Result Effect.Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Evergreen.V45.Discord.Msg
    | GotCurrentUserGuilds Effect.Time.Posix Evergreen.V45.LocalState.DiscordBotToken (Result Evergreen.V45.Discord.HttpError ( Evergreen.V45.Discord.User, List Evergreen.V45.Discord.PartialGuild ))
    | GotDiscordGuilds
        Effect.Time.Posix
        (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.UserId)
        (Result
            Evergreen.V45.Discord.HttpError
            (List
                ( Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.GuildId
                , { guild : Evergreen.V45.Discord.Guild
                  , members : List Evergreen.V45.Discord.GuildMember
                  , channels : List ( Evergreen.V45.Discord.Channel2, List Evergreen.V45.Discord.Message )
                  , icon : Maybe ( Evergreen.V45.FileStatus.FileHash, Maybe (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels) )
                  , threads : List ( Evergreen.V45.Discord.Channel, List Evergreen.V45.Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) Evergreen.V45.Id.ThreadRouteWithMessage (Result Evergreen.V45.Discord.HttpError Evergreen.V45.Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg Evergreen.V45.AiChat.BackendMsg
    | SentDirectMessageToDiscord Evergreen.V45.DmChannel.DmChannelId (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) (Result Evergreen.V45.Discord.HttpError Evergreen.V45.Discord.Message)
    | GotDiscordUserAvatars (Result Evergreen.V45.Discord.HttpError (List ( Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.UserId, Maybe ( Evergreen.V45.FileStatus.FileHash, Maybe (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels) ) )))
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
    | AdminToFrontend Evergreen.V45.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V45.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V45.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V45.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
