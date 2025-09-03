module Types exposing
    ( AdminStatusLoginData(..)
    , BackendFileData
    , BackendModel
    , BackendMsg(..)
    , ChannelSidebarMode(..)
    , Drag(..)
    , EditMessage
    , EmojiSelector(..)
    , FrontendModel(..)
    , FrontendMsg(..)
    , GuildChannelAndMessageId
    , LastRequest(..)
    , LoadStatus(..)
    , LoadedFrontend
    , LoadingFrontend
    , LocalChange(..)
    , LocalMsg(..)
    , LoggedIn2
    , LoginData
    , LoginResult(..)
    , LoginStatus(..)
    , LoginTokenData(..)
    , MessageHover(..)
    , MessageHoverMobileMode(..)
    , MessageMenuExtraOptions
    , NewChannelForm
    , NewGuildForm
    , RevealedSpoilers
    , ScrollPosition(..)
    , ServerChange(..)
    , ToBackend(..)
    , ToBeFilledInByBackend(..)
    , ToFrontend(..)
    , UserOptionsModel
    , WaitingForLoginTokenData
    , messageMenuMobileOffset
    )

import AiChat
import Array exposing (Array)
import Browser exposing (UrlRequest)
import ChannelName exposing (ChannelName)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import Discord.Id
import DmChannel exposing (DmChannel, DmChannelId, FrontendDmChannel)
import Duration exposing (Duration)
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events exposing (Visibility)
import Effect.Browser.Navigation exposing (Key)
import Effect.File exposing (File)
import Effect.Http as Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import Effect.Websocket as Websocket
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileHash, FileId, FileStatus)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmId, GuildOrDmIdNoThread, Id, InviteLinkId, ThreadMessageId, ThreadRoute, ThreadRouteWithMaybeMessage, ThreadRouteWithMessage, UserId)
import List.Nonempty exposing (Nonempty)
import Local exposing (ChangeId, Local)
import LocalState exposing (BackendGuild, DiscordBotToken, FrontendGuild, JoinGuildError, LocalState, PrivateVapidKey)
import Log exposing (Log)
import LoginForm exposing (LoginForm)
import Message exposing (Message)
import MessageInput exposing (MentionUserDropdown)
import MessageView
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import Pages.Admin exposing (AdminChange, InitAdminData)
import PersonName exposing (PersonName)
import Ports exposing (NotificationPermission, PushSubscription, PwaStatus)
import Postmark
import Quantity exposing (Quantity)
import RichText exposing (RichText)
import Route exposing (Route)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import Slack
import String.Nonempty exposing (NonemptyString)
import Touch exposing (Touch)
import TwoFactorAuthentication exposing (TwoFactorAuthentication, TwoFactorAuthenticationSetup, TwoFactorState)
import Ui.Anim
import Url exposing (Url)
import User exposing (BackendUser, FrontendUser)


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias LoadingFrontend =
    { navigationKey : Key
    , route : Route
    , windowSize : Coord CssPixels
    , time : Maybe Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : NotificationPermission
    , pwaStatus : PwaStatus
    , timezone : Time.Zone
    , enabledPushNotifications : Bool
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadedFrontend =
    { navigationKey : Key
    , route : Route
    , time : Time.Posix
    , timezone : Time.Zone
    , windowSize : Coord CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Ui.Anim.State
    , lastCopied : Maybe { copiedAt : Time.Posix, copiedText : String }
    , textInputFocus : Maybe HtmlId
    , notificationPermission : NotificationPermission
    , pwaStatus : PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : AiChat.FrontendModel
    , enabledPushNotifications : Bool
    }


type Drag
    = NoDrag
    | DragStart Time.Posix (NonemptyDict Int Touch)
    | Dragging { horizontalStart : Bool, touches : NonemptyDict Int Touch }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn { loginForm : Maybe LoginForm, useInviteAfterLoggedIn : Maybe (SecretId InviteLinkId) }


type alias LoggedIn2 =
    { localState : Local LocalMsg LocalState
    , admin : Maybe Pages.Admin.Model
    , drafts : SeqDict GuildOrDmId NonemptyString
    , newChannelForm : SeqDict (Id GuildId) NewChannelForm
    , editChannelForm : SeqDict ( Id GuildId, Id ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : Maybe ( Id GuildId, Id ChannelId, ThreadRoute )
    , typingDebouncer : Bool
    , pingUser : Maybe MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict GuildOrDmId EditMessage
    , replyTo : SeqDict GuildOrDmId (Id ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : TwoFactorState
    , filesToUpload : SeqDict GuildOrDmId (NonemptyDict (Id FileId) FileStatus)
    , -- Only should be use for making requests to the Rust server
      sessionId : SessionId
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    }


type alias UserOptionsModel =
    { name : Editable.Model
    , botToken : Editable.Model
    , publicVapidKey : Editable.Model
    , privateVapidKey : Editable.Model
    }


type ChannelSidebarMode
    = ChannelSidebarClosed
    | ChannelSidebarOpened
    | ChannelSidebarClosing { offset : Float }
    | ChannelSidebarOpening { offset : Float }
    | ChannelSidebarDragging { offset : Float, previousOffset : Float, time : Time.Posix }


type MessageHover
    = NoMessageHover
    | MessageHover GuildOrDmIdNoThread ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type alias MessageMenuExtraOptions =
    { position : Coord CssPixels
    , guildOrDmId : GuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity Float CssPixels)
    | MessageMenuOpening { offset : Quantity Float CssPixels, targetOffset : Quantity Float CssPixels }
    | MessageMenuDragging
        { offset : Quantity Float CssPixels
        , previousOffset : Quantity Float CssPixels
        , time : Time.Posix
        }
    | MessageMenuFixed (Quantity Float CssPixels)


messageMenuMobileOffset : MessageHoverMobileMode -> Quantity Float CssPixels
messageMenuMobileOffset mobileMode =
    case mobileMode of
        MessageMenuClosing offset ->
            offset

        MessageMenuOpening { offset } ->
            offset

        MessageMenuDragging { offset } ->
            offset

        MessageMenuFixed offset ->
            offset


type alias RevealedSpoilers =
    { guildOrDmId : GuildOrDmId
    , messages : SeqDict (Id ChannelMessageId) (NonemptySet Int)
    , threadMessages : SeqDict (Id ChannelMessageId) (SeqDict (Id ThreadMessageId) (NonemptySet Int))
    }


type alias EditMessage =
    { messageIndex : Id ChannelMessageId, text : String, attachedFiles : SeqDict (Id FileId) FileStatus }


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction GuildOrDmIdNoThread ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias BackendModel =
    { users : NonemptyDict (Id UserId) BackendUser
    , sessions : SeqDict SessionId (Id UserId)
    , connections : SeqDict SessionId (NonemptyDict ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict SessionId LoginTokenData
    , logs : Array { time : Time.Posix, log : Log }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Time.Posix
    , -- This could be part of BackendUser but having it separate reduces the chances of leaking 2FA secrets to other users. We could also just derive a secret key from `Env.secretKey ++ Id.toString userId` but this would cause problems if we ever changed Env.secretKey for some reason.
      twoFactorAuthentication : SeqDict (Id UserId) TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict (Id UserId) TwoFactorAuthenticationSetup
    , guilds : SeqDict (Id GuildId) BackendGuild
    , discordModel : Discord.Model Websocket.Connection
    , backendInitialized : Bool
    , discordGuilds : OneToOne (Discord.Id.Id Discord.Id.GuildId) (Id GuildId)
    , discordUsers : OneToOne (Discord.Id.Id Discord.Id.UserId) (Id UserId)
    , discordBotId : Maybe (Discord.Id.Id Discord.Id.UserId)
    , dmChannels : SeqDict DmChannelId DmChannel
    , discordDms : OneToOne (Discord.Id.Id Discord.Id.ChannelId) DmChannelId
    , botToken : Maybe DiscordBotToken
    , slackWorkspaces : OneToOne String (Id GuildId)
    , slackUsers : OneToOne String (Id UserId)
    , slackToken : Maybe Slack.SlackAuth
    , files : SeqDict FileHash BackendFileData
    , privateVapidKey : PrivateVapidKey
    , publicVapidKey : String
    , pushSubscriptions : SeqDict SessionId PushSubscription
    , slackClientSecret : String
    }


type alias BackendFileData =
    { fileSize : Int, imageSize : Maybe (Coord CssPixels) }


type LastRequest
    = NoRequestsMade
    | LastRequest Time.Posix


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Time.Posix
        , userId : Id UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Time.Posix
        , emailAddress : EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Time.Posix
        , emailAddress : EmailAddress
        }


type alias WaitingForLoginTokenData =
    { creationTime : Time.Posix
    , userId : Id UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | GotTime Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Time.Zone
    | LoginFormMsg LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Route
    | PressedTextInput
    | TypedMessage GuildOrDmId String
    | PressedSendMessage GuildOrDmIdNoThread ThreadRoute
    | PressedAttachFiles GuildOrDmId
    | SelectedFilesToAttach GuildOrDmId File (List File)
    | NewChannelFormChanged (Id GuildId) NewChannelForm
    | PressedSubmitNewChannel (Id GuildId) NewChannelForm
    | MouseEnteredChannelName (Id GuildId) (Id ChannelId) ThreadRoute
    | MouseExitedChannelName (Id GuildId) (Id ChannelId) ThreadRoute
    | EditChannelFormChanged (Id GuildId) (Id ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Id GuildId) (Id ChannelId)
    | PressedSubmitEditChannelChanges (Id GuildId) (Id ChannelId) NewChannelForm
    | PressedDeleteChannel (Id GuildId) (Id ChannelId)
    | PressedCreateInviteLink (Id GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Dom.Error MentionUserDropdown)
    | PressedPingUser GuildOrDmId Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown GuildOrDmIdNoThread Int
    | TextInputGotFocus HtmlId
    | TextInputLostFocus HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector GuildOrDmIdNoThread ThreadRouteWithMessage (Coord CssPixels)
    | MessageMenu_PressedEditMessage GuildOrDmIdNoThread ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Emoji
    | GotPingUserPositionForEditMessage (Result Dom.Error MentionUserDropdown)
    | TypedEditMessage GuildOrDmId String
    | PressedSendEditMessage GuildOrDmId
    | PressedArrowInDropdownForEditMessage GuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage GuildOrDmId Int
    | PressedArrowUpInEmptyInput GuildOrDmId
    | MessageMenu_PressedReply ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Id ChannelMessageId)
    | PressedCloseReplyTo GuildOrDmId
    | VisibilityChanged Visibility
    | CheckedNotificationPermission NotificationPermission
    | CheckedPwaStatus PwaStatus
    | TouchStart (Maybe ( GuildOrDmIdNoThread, ThreadRouteWithMessage, Bool )) Time.Posix (NonemptyDict Int Touch)
    | TouchMoved Time.Posix (NonemptyDict Int Touch)
    | TouchEnd Time.Posix
    | TouchCancel Time.Posix
    | ChannelSidebarAnimated Duration
    | MessageMenuAnimated Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | UserScrolled GuildOrDmIdNoThread ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage GuildOrDmIdNoThread ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit GuildOrDmId
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Time.Posix GuildOrDmIdNoThread ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg TwoFactorAuthentication.Msg
    | AiChatMsg AiChat.Msg
    | UserNameEditableMsg (Editable.Msg PersonName)
    | BotTokenEditableMsg (Editable.Msg (Maybe DiscordBotToken))
    | PublicVapidKeyEditableMsg (Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Editable.Msg PrivateVapidKey)
    | OneFrameAfterDragEnd
    | GotFileHashName GuildOrDmId (Id FileId) (Result Http.Error ( FileHash, Maybe (Coord CssPixels) ))
    | PressedDeleteAttachedFile GuildOrDmId (Id FileId)
    | EditMessage_PressedDeleteAttachedFile GuildOrDmId (Id FileId)
    | EditMessage_PressedAttachFiles GuildOrDmId
    | EditMessage_SelectedFilesToAttach GuildOrDmId File (List File)
    | EditMessage_GotFileHashName GuildOrDmId (Id ChannelMessageId) (Id FileId) (Result Http.Error ( FileHash, Maybe (Coord CssPixels) ))
    | EditMessage_PastedFiles GuildOrDmId (Nonempty File)
    | PastedFiles GuildOrDmId (Nonempty File)
    | FileUploadProgress GuildOrDmId (Id FileId) Http.Progress
    | MessageViewMsg GuildOrDmIdNoThread ThreadRouteWithMessage MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String PushSubscription)
    | ToggledEnablePushNotifications Bool
    | GotIsPushNotificationsRegistered Bool


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias GuildChannelAndMessageId =
    { guildId : Id GuildId, channelId : Id ChannelId, messageIndex : Id ChannelMessageId }


type ToBackend
    = CheckLoginRequest (Maybe ( GuildOrDmIdNoThread, ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( GuildOrDmIdNoThread, ThreadRoute )) Int
    | LoginWithTwoFactorRequest (Maybe ( GuildOrDmIdNoThread, ThreadRoute )) Int
    | GetLoginTokenRequest EmailAddress
    | AdminToBackend Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest ChangeId LocalChange
    | TwoFactorToBackend TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Id GuildId) (SecretId InviteLinkId)
    | FinishUserCreationRequest (Maybe ( GuildOrDmIdNoThread, ThreadRoute )) PersonName
    | AiChatToBackend AiChat.ToBackend
    | ReloadDataRequest (Maybe ( GuildOrDmIdNoThread, ThreadRoute ))
    | RegisterPushSubscriptionRequest PushSubscription
    | UnregisterPushSubscriptionRequest
    | LinkSlackOAuthCode Slack.OAuthCode


type BackendMsg
    = SentLoginEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())
    | UserConnected SessionId ClientId
    | UserDisconnected SessionId ClientId
    | BackendGotTime SessionId ClientId ToBackend Time.Posix
    | SentLogErrorEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())
    | WebsocketCreatedHandle Websocket.Connection
    | WebsocketSentData (Result Websocket.SendError ())
    | WebsocketClosedByBackend Bool
    | DiscordWebsocketMsg Discord.Msg
    | GotCurrentUserGuilds Time.Posix DiscordBotToken (Result Discord.HttpError ( Discord.User, List Discord.PartialGuild ))
    | GotDiscordGuilds
        Time.Posix
        (Discord.Id.Id Discord.Id.UserId)
        (Result
            Discord.HttpError
            (List
                ( Discord.Id.Id Discord.Id.GuildId
                , { guild : Discord.Guild
                  , members : List Discord.GuildMember
                  , channels : List ( Discord.Channel2, List Discord.Message )
                  , icon : Maybe ( FileHash, Maybe (Coord CssPixels) )
                  , threads : List ( Discord.Channel, List Discord.Message )
                  }
                )
            )
        )
    | SentGuildMessageToDiscord (Id GuildId) (Id ChannelId) ThreadRouteWithMessage (Result Discord.HttpError Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg AiChat.BackendMsg
    | SentDirectMessageToDiscord DmChannelId (Id ChannelMessageId) (Result Discord.HttpError Discord.Message)
    | GotDiscordUserAvatars (Result Discord.HttpError (List ( Discord.Id.Id Discord.Id.UserId, Maybe ( FileHash, Maybe (Coord CssPixels) ) )))
    | SentNotification Time.Posix (Result Http.Error ())
    | GotVapidKeys (Result Http.Error String)
    | GotSlackWorkspaces Time.Posix (Result Slack.HttpError (List Slack.SlackWorkspace))
    | GotSlackWorkspaceDetails Time.Posix String (Result Slack.HttpError ( Slack.SlackWorkspace, List Slack.SlackChannel ))
    | GotSlackOAuth SessionId (Result Slack.HttpError Slack.TokenResponse)


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
    | AdminToFrontend Pages.Admin.ToFrontend
    | LocalChangeResponse ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)


type alias LoginData =
    { userId : Id UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Time.Posix
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , dmChannels : SeqDict (Id UserId) FrontendDmChannel
    , user : BackendUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    , sessionId : SessionId
    , publicVapidKey : String
    }


type AdminStatusLoginData
    = IsAdminLoginData InitAdminData
    | IsNotAdminLoginData


type LocalMsg
    = LocalChange (Id UserId) LocalChange
    | ServerChange ServerChange


type ServerChange
    = Server_SendMessage (Id UserId) Time.Posix GuildOrDmIdNoThread (Nonempty RichText) ThreadRouteWithMaybeMessage (SeqDict (Id FileId) FileData)
    | Server_NewChannel Time.Posix (Id GuildId) ChannelName
    | Server_EditChannel (Id GuildId) (Id ChannelId) ChannelName
    | Server_DeleteChannel (Id GuildId) (Id ChannelId)
    | Server_NewInviteLink Time.Posix (Id UserId) (Id GuildId) (SecretId InviteLinkId)
    | Server_MemberJoined Time.Posix (Id UserId) (Id GuildId) FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            JoinGuildError
            { guildId : Id GuildId
            , guild : FrontendGuild
            , owner : FrontendUser
            , members : SeqDict (Id UserId) FrontendUser
            }
        )
    | Server_MemberTyping Time.Posix (Id UserId) GuildOrDmId
    | Server_AddReactionEmoji (Id UserId) GuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Server_RemoveReactionEmoji (Id UserId) GuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Server_SendEditMessage Time.Posix (Id UserId) GuildOrDmIdNoThread ThreadRouteWithMessage (Nonempty RichText) (SeqDict (Id FileId) FileData)
    | Server_MemberEditTyping Time.Posix (Id UserId) GuildOrDmIdNoThread ThreadRouteWithMessage
    | Server_DeleteMessage (Id UserId) GuildOrDmIdNoThread ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Id UserId) PersonName
    | Server_DiscordDirectMessage Time.Posix (Id UserId) (Nonempty RichText) (Maybe (Id ChannelMessageId))
    | Server_PushNotificationsReset String


type LocalChange
    = Local_Invalid
    | Local_Admin AdminChange
    | Local_SendMessage Time.Posix GuildOrDmIdNoThread (Nonempty RichText) ThreadRouteWithMaybeMessage (SeqDict (Id FileId) FileData)
    | Local_NewChannel Time.Posix (Id GuildId) ChannelName
    | Local_EditChannel (Id GuildId) (Id ChannelId) ChannelName
    | Local_DeleteChannel (Id GuildId) (Id ChannelId)
    | Local_NewInviteLink Time.Posix (Id GuildId) (ToBeFilledInByBackend (SecretId InviteLinkId))
    | Local_NewGuild Time.Posix GuildName (ToBeFilledInByBackend (Id GuildId))
    | Local_MemberTyping Time.Posix GuildOrDmId
    | Local_AddReactionEmoji GuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Local_RemoveReactionEmoji GuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Local_SendEditMessage Time.Posix GuildOrDmIdNoThread ThreadRouteWithMessage (Nonempty RichText) (SeqDict (Id FileId) FileData)
    | Local_MemberEditTyping Time.Posix GuildOrDmIdNoThread ThreadRouteWithMessage
    | Local_SetLastViewed GuildOrDmIdNoThread ThreadRouteWithMessage
    | Local_DeleteMessage GuildOrDmIdNoThread ThreadRouteWithMessage
    | Local_ViewChannel (Id GuildId) (Id ChannelId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId)))
    | Local_ViewThread (Id GuildId) (Id ChannelId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId)))
    | Local_SetName PersonName
    | Local_LoadChannelMessages GuildOrDmIdNoThread (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId)))
    | Local_LoadThreadMessages GuildOrDmIdNoThread (Id ChannelMessageId) (Id ThreadMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId)))


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a
