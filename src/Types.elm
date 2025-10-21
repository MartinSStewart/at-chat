module Types exposing
    ( AdminStatusLoginData(..)
    , BackendFileData
    , BackendModel
    , BackendMsg(..)
    , ChannelSidebarMode(..)
    , DiscordBasicUserData
    , DiscordFullUserData
    , DiscordUserData(..)
    , Drag(..)
    , EditMessage
    , EmojiSelector(..)
    , FrontendModel(..)
    , FrontendMsg(..)
    , GuildChannelAndMessageId
    , GuildChannelNameHover(..)
    , LastRequest(..)
    , LinkDiscordSubmitStatus(..)
    , LoadStatus(..)
    , LoadedFrontend
    , LoadingFrontend
    , LocalChange(..)
    , LocalDiscordChange(..)
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
    , ServerDiscordChange(..)
    , ToBackend(..)
    , ToFrontend(..)
    , UserOptionsModel
    , WaitingForLoginTokenData
    , messageMenuMobileOffset
    )

import AiChat
import Array exposing (Array)
import Browser exposing (UrlRequest)
import ChannelName exposing (ChannelName)
import Codec exposing (Codec)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord exposing (CaptchaChallengeData)
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
import FileStatus exposing (FileData, FileDataWithImage, FileHash, FileId, FileStatus)
import GuildName exposing (GuildName)
import Id exposing (AnyGuildOrDmIdNoThread, AnyGuildOrDmIdNoThread_WithCurrentUserId, ChannelId, ChannelMessageId, DiscordGuildOrDmId, GuildId, GuildOrDmId, Id, InviteLinkId, ThreadMessageId, ThreadRoute, ThreadRouteWithMaybeMessage, ThreadRouteWithMessage, UserId)
import List.Nonempty exposing (Nonempty)
import Local exposing (ChangeId, Local)
import LocalState exposing (BackendGuild, DiscordBackendGuild, DiscordFrontendGuild, FrontendGuild, JoinGuildError, LocalState, PrivateVapidKey)
import Log exposing (Log)
import LoginForm exposing (LoginForm)
import Maybe exposing (Maybe)
import Message exposing (Message)
import MessageInput exposing (MentionUserDropdown)
import MessageView
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import Pages.Admin exposing (AdminChange, InitAdminData)
import PersonName exposing (PersonName)
import Ports exposing (NotificationPermission, PwaStatus)
import Postmark
import Quantity exposing (Quantity)
import RichText exposing (RichText)
import Route exposing (Route)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SessionIdHash exposing (SessionIdHash)
import Slack
import String.Nonempty exposing (NonemptyString)
import TextEditor
import Touch exposing (Touch)
import TwoFactorAuthentication exposing (TwoFactorAuthentication, TwoFactorAuthenticationSetup, TwoFactorState)
import Ui.Anim
import Url exposing (Url)
import User exposing (BackendUser, DiscordFrontendCurrentUser, DiscordFrontendUser, FrontendCurrentUser, FrontendUser, NotificationLevel)
import UserAgent exposing (UserAgent)
import UserSession exposing (FrontendUserSession, NotificationMode, SetViewing, SubscribeData, ToBeFilledInByBackend, UserSession)


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
    , scrollbarWidth : Int
    , userAgent : Maybe UserAgent
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
    , scrollbarWidth : Int
    , userAgent : UserAgent
    , pageHasFocus : Bool
    }


type Drag
    = NoDrag
    | DragStart Time.Posix (NonemptyDict Int Touch)
    | Dragging { horizontalStart : Bool, touches : NonemptyDict Int Touch }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn { loginForm : Maybe LoginForm, useInviteAfterLoggedIn : Maybe (SecretId InviteLinkId) }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Id GuildId) (Id ChannelId) ThreadRoute
    | DiscordGuildChannelNameHover (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ThreadRoute


type alias LoggedIn2 =
    { localState : Local LocalMsg LocalState
    , admin : Maybe Pages.Admin.Model
    , drafts : SeqDict ( AnyGuildOrDmIdNoThread, ThreadRoute ) NonemptyString
    , newChannelForm : SeqDict (Id GuildId) NewChannelForm
    , editChannelForm : SeqDict ( Id GuildId, Id ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict ( AnyGuildOrDmIdNoThread, ThreadRoute ) EditMessage
    , replyTo : SeqDict ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : TwoFactorState
    , filesToUpload : SeqDict ( AnyGuildOrDmIdNoThread, ThreadRoute ) (NonemptyDict (Id FileId) FileStatus)
    , showFileToUploadInfo : Maybe FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : TextEditor.Model
    }


type alias UserOptionsModel =
    { name : Editable.Model
    , slackClientSecret : Editable.Model
    , publicVapidKey : Editable.Model
    , privateVapidKey : Editable.Model
    , openRouterKey : Editable.Model
    , showLinkDiscordSetup : Bool
    , linkDiscordSubmit : LinkDiscordSubmitStatus
    }


type LinkDiscordSubmitStatus
    = LinkDiscordNotSubmitted { attemptCount : Int }
    | LinkDiscordSubmitting
    | LinkDiscordSubmitted


type ChannelSidebarMode
    = ChannelSidebarClosed
    | ChannelSidebarOpened
    | ChannelSidebarClosing { offset : Float }
    | ChannelSidebarOpening { offset : Float }
    | ChannelSidebarDragging { offset : Float, previousOffset : Float, time : Time.Posix }


type MessageHover
    = NoMessageHover
    | MessageHover AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type alias MessageMenuExtraOptions =
    { position : Coord CssPixels
    , guildOrDmId : AnyGuildOrDmIdNoThread
    , isThreadStarter : Bool
    , threadRoute : ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity Float CssPixels) (Maybe EditMessage)
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
        MessageMenuClosing offset _ ->
            offset

        MessageMenuOpening { offset } ->
            offset

        MessageMenuDragging { offset } ->
            offset

        MessageMenuFixed offset ->
            offset


type alias RevealedSpoilers =
    { guildOrDmId : ( AnyGuildOrDmIdNoThread, ThreadRoute )
    , messages : SeqDict (Id ChannelMessageId) (NonemptySet Int)
    , threadMessages : SeqDict (Id ChannelMessageId) (SeqDict (Id ThreadMessageId) (NonemptySet Int))
    }


type alias EditMessage =
    { messageIndex : Id ChannelMessageId, text : String, attachedFiles : SeqDict (Id FileId) FileStatus }


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias BackendModel =
    { users : NonemptyDict (Id UserId) BackendUser
    , sessions : SeqDict SessionId UserSession
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
    , backendInitialized : Bool
    , discordGuilds : SeqDict (Discord.Id.Id Discord.Id.GuildId) DiscordBackendGuild
    , dmChannels : SeqDict DmChannelId DmChannel
    , discordDms : OneToOne (Discord.Id.Id Discord.Id.ChannelId) DmChannelId
    , slackDms : OneToOne (Slack.Id Slack.ChannelId) DmChannelId
    , slackWorkspaces : OneToOne String (Id GuildId)
    , slackUsers : OneToOne (Slack.Id Slack.UserId) (Id UserId)
    , slackServers : OneToOne (Slack.Id Slack.TeamId) (Id GuildId)
    , slackToken : Maybe Slack.AuthToken
    , files : SeqDict FileHash BackendFileData
    , privateVapidKey : PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : TextEditor.LocalState
    , discordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordUserData
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData


type alias DiscordFullUserData =
    { auth : Discord.UserAuth
    , data : Discord.User
    , connection : Discord.Model Websocket.Connection
    , linkedTo : Id UserId
    , icon : Maybe FileHash
    }


type alias DiscordBasicUserData =
    { user : Discord.User, icon : Maybe FileHash }


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
    | TypedMessage ( AnyGuildOrDmIdNoThread, ThreadRoute ) String
    | PressedSendMessage AnyGuildOrDmIdNoThread ThreadRoute
    | PressedAttachFiles ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | SelectedFilesToAttach ( AnyGuildOrDmIdNoThread, ThreadRoute ) File (List File)
    | NewChannelFormChanged (Id GuildId) NewChannelForm
    | PressedSubmitNewChannel (Id GuildId) NewChannelForm
    | MouseEnteredChannelName (Id GuildId) (Id ChannelId) ThreadRoute
    | MouseExitedChannelName (Id GuildId) (Id ChannelId) ThreadRoute
    | MouseEnteredDiscordChannelName (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ThreadRoute
    | MouseExitedDiscordChannelName (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ThreadRoute
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
    | PressedPingUser ( AnyGuildOrDmIdNoThread, ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown AnyGuildOrDmIdNoThread Int
    | TextInputGotFocus HtmlId
    | TextInputLostFocus HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector AnyGuildOrDmIdNoThread ThreadRouteWithMessage (Coord CssPixels)
    | MessageMenu_PressedEditMessage AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Emoji
    | GotPingUserPositionForEditMessage (Result Dom.Error MentionUserDropdown)
    | TypedEditMessage ( AnyGuildOrDmIdNoThread, ThreadRoute ) String
    | PressedSendEditMessage ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | PressedArrowInDropdownForEditMessage AnyGuildOrDmIdNoThread Int
    | PressedPingUserForEditMessage ( AnyGuildOrDmIdNoThread, ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | MessageMenu_PressedReply ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Id ChannelMessageId)
    | PressedCloseReplyTo ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | VisibilityChanged Visibility
    | CheckedNotificationPermission NotificationPermission
    | CheckedPwaStatus PwaStatus
    | TouchStart (Maybe ( AnyGuildOrDmIdNoThread, ThreadRouteWithMessage, Bool )) Time.Posix (NonemptyDict Int Touch)
    | TouchMoved Time.Posix (NonemptyDict Int Touch)
    | TouchEnd Time.Posix
    | TouchCancel Time.Posix
    | ChannelSidebarAnimated Duration
    | MessageMenuAnimated Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled AnyGuildOrDmIdNoThread ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Time.Posix AnyGuildOrDmIdNoThread ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg TwoFactorAuthentication.Msg
    | AiChatMsg AiChat.Msg
    | UserNameEditableMsg (Editable.Msg PersonName)
    | SlackClientSecretEditableMsg (Editable.Msg (Maybe Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Editable.Msg PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Editable.Msg (Maybe String))
    | OneFrameAfterDragEnd
    | GotFileHashName ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id FileId) (Result Http.Error FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id FileId)
    | PressedViewAttachedFileInfo ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id FileId)
    | EditMessage_PressedDeleteAttachedFile ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id FileId)
    | EditMessage_PressedViewAttachedFileInfo ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id FileId)
    | EditMessage_PressedAttachFiles ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( AnyGuildOrDmIdNoThread, ThreadRoute ) File (List File)
    | EditMessage_GotFileHashName ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id ChannelMessageId) (Id FileId) (Result Http.Error FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Nonempty File)
    | PastedFiles ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Nonempty File)
    | FileUploadProgress ( AnyGuildOrDmIdNoThread, ThreadRoute ) (Id FileId) Http.Progress
    | MessageViewMsg AnyGuildOrDmIdNoThread ThreadRouteWithMessage MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String SubscribeData)
    | SelectedNotificationMode NotificationMode
    | PressedGuildNotificationLevel (Id GuildId) NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg TextEditor.Msg
    | PressedLinkDiscord
    | TypedBookmarkletData String


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
    = CheckLoginRequest (Maybe ( AnyGuildOrDmIdNoThread, ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( AnyGuildOrDmIdNoThread, ThreadRoute )) Int UserAgent
    | LoginWithTwoFactorRequest (Maybe ( AnyGuildOrDmIdNoThread, ThreadRoute )) Int UserAgent
    | GetLoginTokenRequest EmailAddress
    | AdminToBackend Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest ChangeId LocalChange
    | TwoFactorToBackend TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Id GuildId) (SecretId InviteLinkId)
    | FinishUserCreationRequest (Maybe ( AnyGuildOrDmIdNoThread, ThreadRoute )) PersonName UserAgent
    | AiChatToBackend AiChat.ToBackend
    | ReloadDataRequest (Maybe ( AnyGuildOrDmIdNoThread, ThreadRoute ))
    | LinkSlackOAuthCode Slack.OAuthCode SessionIdHash
    | LinkDiscordRequest Discord.UserAuth


type BackendMsg
    = SentLoginEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())
    | UserConnected SessionId ClientId
    | UserDisconnected SessionId ClientId
    | BackendGotTime SessionId ClientId ToBackend Time.Posix
    | SentLogErrorEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Discord.Id.Id Discord.Id.UserId) Discord.Msg
    | SentGuildMessageToDiscord (Id GuildId) (Id ChannelId) ThreadRouteWithMessage (Result Discord.HttpError Discord.Message)
    | DeletedDiscordMessage
    | EditedDiscordMessage
    | AiChatBackendMsg AiChat.BackendMsg
    | SentDirectMessageToDiscord DmChannelId (Id ChannelMessageId) (Result Discord.HttpError Discord.Message)
    | GotDiscordUserAvatars (Result Discord.HttpError (List ( Discord.Id.Id Discord.Id.UserId, Maybe FileStatus.UploadResponse )))
    | SentNotification SessionId (Id UserId) Time.Posix (Result Http.Error ())
    | GotVapidKeys (Result Http.Error String)
    | GotSlackChannels
        Time.Posix
        (Id UserId)
        (Result
            Http.Error
            { currentUser : Slack.CurrentUser
            , team : Slack.Team
            , users : List Slack.User
            , channels : List ( Slack.Channel, List Slack.Message )
            }
        )
    | GotSlackOAuth Time.Posix (Id UserId) (Result Http.Error Slack.TokenResponse)
    | LinkDiscordUserStep1 ClientId (Id UserId) Discord.UserAuth (Result Discord.HttpError Discord.User)
    | LinkDiscordUserStep2
        (Discord.Id.Id Discord.Id.UserId)
        (Result
            Discord.HttpError
            (List
                ( Discord.Id.Id Discord.Id.GuildId
                , { guild : Discord.GatewayGuild
                  , channels : List ( Discord.Channel, List Discord.Message )
                  , icon : Maybe FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Discord.Id.Id Discord.Id.UserId) Websocket.Connection
    | WebsocketClosedByBackendForUser (Discord.Id.Id Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Discord.Id.Id Discord.Id.UserId) (Result Websocket.SendError ())


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
    | LinkDiscordResponse (Result Discord.HttpError Discord.User)


type alias LoginData =
    { session : UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Time.Posix
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , dmChannels : SeqDict (Id UserId) FrontendDmChannel
    , discordGuilds : SeqDict (Discord.Id.Id Discord.Id.GuildId) DiscordFrontendGuild
    , user : FrontendCurrentUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    , otherDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordFrontendCurrentUser
    , otherSessions : SeqDict SessionIdHash FrontendUserSession
    , publicVapidKey : String
    , textEditor : TextEditor.LocalState
    }


type AdminStatusLoginData
    = IsAdminLoginData InitAdminData
    | IsNotAdminLoginData


type LocalMsg
    = LocalChange (Id UserId) LocalChange
    | ServerChange ServerChange


type ServerChange
    = Server_SendMessage (Id UserId) Time.Posix GuildOrDmId (Nonempty (RichText (Id UserId))) ThreadRouteWithMaybeMessage (SeqDict (Id FileId) FileData)
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
    | Server_MemberTyping Time.Posix (Id UserId) ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | Server_AddReactionEmoji (Id UserId) AnyGuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Server_RemoveReactionEmoji (Id UserId) AnyGuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Server_SendEditMessage Time.Posix (Id UserId) GuildOrDmId ThreadRouteWithMessage (Nonempty (RichText (Id UserId))) (SeqDict (Id FileId) FileData)
    | Server_MemberEditTyping Time.Posix (Id UserId) AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | Server_DeleteMessage (Id UserId) AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | Server_DiscordDeleteMessage GuildChannelAndMessageId
    | Server_SetName (Id UserId) PersonName
    | Server_DiscordDirectMessage Time.Posix (Id UserId) (Nonempty (RichText (Id UserId))) (Maybe (Id ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Id GuildId) NotificationLevel
    | Server_PushNotificationFailed Http.Error
    | Server_NewSession SessionIdHash FrontendUserSession
    | Server_LoggedOut SessionIdHash
    | Server_CurrentlyViewing SessionIdHash (Maybe ( AnyGuildOrDmIdNoThread, ThreadRoute ))
    | Server_TextEditor TextEditor.ServerChange
    | Server_LinkDiscordUser (Discord.Id.Id Discord.Id.UserId) String
    | Server_DiscordChange (Discord.Id.Id Discord.Id.UserId) ServerDiscordChange


type ServerDiscordChange
    = Server_Discord_SendMessage Time.Posix DiscordGuildOrDmId (Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))) ThreadRouteWithMaybeMessage (SeqDict (Id FileId) FileData)
    | Server_Discord_NewChannel Time.Posix (Discord.Id.Id Discord.Id.GuildId) ChannelName
    | Server_Discord_EditChannel (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ChannelName
    | Server_Discord_DeleteChannel (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId)
    | Server_Discord_SendEditMessage Time.Posix DiscordGuildOrDmId ThreadRouteWithMessage (Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))) (SeqDict (Id FileId) FileData)
    | Server_Discord_SetName PersonName
    | Server_Discord_LoadChannelMessages DiscordGuildOrDmId (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id.Id Discord.Id.UserId))))
    | Server_Discord_LoadThreadMessages DiscordGuildOrDmId (Id ChannelMessageId) (Id ThreadMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Discord.Id.Id Discord.Id.UserId))))
    | Server_Discord_SetGuildNotificationLevel (Id GuildId) NotificationLevel


type LocalChange
    = Local_Invalid
    | Local_Admin AdminChange
    | Local_SendMessage Time.Posix GuildOrDmId (Nonempty (RichText (Id UserId))) ThreadRouteWithMaybeMessage (SeqDict (Id FileId) FileData)
    | Local_NewChannel Time.Posix (Id GuildId) ChannelName
    | Local_EditChannel (Id GuildId) (Id ChannelId) ChannelName
    | Local_DeleteChannel (Id GuildId) (Id ChannelId)
    | Local_NewInviteLink Time.Posix (Id GuildId) (ToBeFilledInByBackend (SecretId InviteLinkId))
    | Local_NewGuild Time.Posix GuildName (ToBeFilledInByBackend (Id GuildId))
    | Local_MemberTyping Time.Posix ( AnyGuildOrDmIdNoThread, ThreadRoute )
    | Local_AddReactionEmoji AnyGuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Local_RemoveReactionEmoji AnyGuildOrDmIdNoThread ThreadRouteWithMessage Emoji
    | Local_SendEditMessage Time.Posix GuildOrDmId ThreadRouteWithMessage (Nonempty (RichText (Id UserId))) (SeqDict (Id FileId) FileData)
    | Local_MemberEditTyping Time.Posix AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | Local_SetLastViewed AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | Local_DeleteMessage AnyGuildOrDmIdNoThread ThreadRouteWithMessage
    | Local_CurrentlyViewing SetViewing
    | Local_SetName PersonName
    | Local_LoadChannelMessages GuildOrDmId (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | Local_LoadThreadMessages GuildOrDmId (Id ChannelMessageId) (Id ThreadMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | Local_SetGuildNotificationLevel (Id GuildId) NotificationLevel
    | Local_SetNotificationMode NotificationMode
    | Local_RegisterPushSubscription SubscribeData
    | Local_TextEditor TextEditor.LocalChange
    | Local_DiscordChange (Discord.Id.Id Discord.Id.UserId) LocalDiscordChange


type LocalDiscordChange
    = Local_Discord_SendMessage Time.Posix DiscordGuildOrDmId (Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))) ThreadRouteWithMaybeMessage (SeqDict (Id FileId) FileData)
    | Local_Discord_NewChannel Time.Posix (Discord.Id.Id Discord.Id.GuildId) ChannelName
    | Local_Discord_EditChannel (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ChannelName
    | Local_Discord_DeleteChannel (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId)
    | Local_Discord_SendEditMessage Time.Posix DiscordGuildOrDmId ThreadRouteWithMessage (Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))) (SeqDict (Id FileId) FileData)
    | Local_Discord_SetName PersonName
    | Local_Discord_LoadChannelMessages DiscordGuildOrDmId (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id.Id Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages DiscordGuildOrDmId (Id ChannelMessageId) (Id ThreadMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Discord.Id.Id Discord.Id.UserId))))
    | Local_Discord_SetGuildNotificationLevel (Id GuildId) NotificationLevel
