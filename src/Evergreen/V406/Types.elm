module Evergreen.V406.Types exposing (..)

import Array
import Browser
import Bytes
import Duration
import Effect.Browser.Dom
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V406.AiChat
import Evergreen.V406.Audio
import Evergreen.V406.BackendMsgLog
import Evergreen.V406.Call
import Evergreen.V406.ChannelDescription
import Evergreen.V406.ChannelName
import Evergreen.V406.Coord
import Evergreen.V406.CssPixels
import Evergreen.V406.CustomEmoji
import Evergreen.V406.Discord
import Evergreen.V406.DiscordAttachmentId
import Evergreen.V406.DiscordUserData
import Evergreen.V406.DmChannel
import Evergreen.V406.DmChannelId
import Evergreen.V406.Drawing
import Evergreen.V406.Editable
import Evergreen.V406.EmailAddress
import Evergreen.V406.Embed
import Evergreen.V406.Emoji
import Evergreen.V406.Encryption
import Evergreen.V406.FileStatus
import Evergreen.V406.Game
import Evergreen.V406.Go
import Evergreen.V406.GuildName
import Evergreen.V406.Id
import Evergreen.V406.IdArray
import Evergreen.V406.ImageEditor
import Evergreen.V406.ImageViewer
import Evergreen.V406.LinkedAndOtherDiscordUsers
import Evergreen.V406.Local
import Evergreen.V406.LocalState
import Evergreen.V406.Log
import Evergreen.V406.LoginForm
import Evergreen.V406.MembersAndOwner
import Evergreen.V406.Message
import Evergreen.V406.MessageInput
import Evergreen.V406.MessageView
import Evergreen.V406.MuteSettings
import Evergreen.V406.MyUi
import Evergreen.V406.NonemptyDict
import Evergreen.V406.NonemptySet
import Evergreen.V406.OneOrGreater
import Evergreen.V406.OneToOne
import Evergreen.V406.Pages.Admin
import Evergreen.V406.Pagination
import Evergreen.V406.PersonName
import Evergreen.V406.Ports
import Evergreen.V406.Postmark
import Evergreen.V406.Range
import Evergreen.V406.RateLimit
import Evergreen.V406.RecoveryLogin
import Evergreen.V406.RichText
import Evergreen.V406.Route
import Evergreen.V406.Scroll
import Evergreen.V406.SecretId
import Evergreen.V406.SessionIdHash
import Evergreen.V406.SetViewing
import Evergreen.V406.SheepGame
import Evergreen.V406.Slack
import Evergreen.V406.Sticker
import Evergreen.V406.TextEditor
import Evergreen.V406.ToBackendLog
import Evergreen.V406.Touch
import Evergreen.V406.TwoFactorAuthentication
import Evergreen.V406.Ui.Anim
import Evergreen.V406.User
import Evergreen.V406.UserAgent
import Evergreen.V406.UserColor
import Evergreen.V406.UserSession
import Evergreen.V406.VisibleMessages
import Evergreen.V406.WordSpellingGame
import Evergreen.V406.X25519
import List.Nonempty
import Quantity
import SeqDict
import SeqSet
import String.Nonempty
import Url


type alias NewChannelForm =
    { name : String
    , description : String
    , pressedSubmit : Bool
    }


type alias EditChannelForm =
    { name : String
    , description : String
    , deleteConfirmation : String
    , showDeleteConfirmation : Bool
    , pressedSubmit : Bool
    }


type ImportChannelError
    = NotAChannelExport


type ImportChannelStatus
    = NotImportingChannel
    | ImportingChannel
    | ImportChannelFailed ImportChannelError
    | ImportedChannel
        { encryptedMessages : Int
        }


type alias EditGuildForm =
    { name : String
    , deleteConfirmation : String
    , showDeleteConfirmation : Bool
    , showLeaveConfirmation : Bool
    , pressedSubmit : Bool
    , importChannel : ImportChannelStatus
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type E2eeKeysValid
    = E2eeKeys_NotChecked
    | E2eeKeys_Error String
    | E2eeKeys_Valid


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V406.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V406.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V406.Pages.Admin.Msg
    | PressedLogOut Evergreen.V406.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V406.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V406.Route.Route
    | SelectedFilesToAttach ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | PressedImportChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V406.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V406.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V406.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V406.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V406.NonemptyDict.NonemptyDict Int Evergreen.V406.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V406.NonemptyDict.NonemptyDict Int Evergreen.V406.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRoute Evergreen.V406.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V406.NonemptySet.NonemptySet (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V406.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V406.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V406.AiChat.Msg
    | GameMsg Evergreen.V406.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V406.Id.GuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V406.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V406.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V406.Editable.Msg Evergreen.V406.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V406.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) (Maybe Evergreen.V406.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute )
        { fileId : Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute )
        { fileId : Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage Evergreen.V406.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V406.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V406.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V406.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V406.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V406.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V406.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V406.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | PressedDisableE2ee (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | TypedPrivateKey (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) String
    | PageHasFocusChanged Bool
    | PageFocusSettled
    | GotServiceWorkerMessage String
    | PressedNotification String
    | VisualViewportChanged
        { height : Float
        , top : Float
        }
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V406.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId
        , otherUserId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V406.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRoute Evergreen.V406.MessageInput.Msg
    | MessageInputMsg Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRoute Evergreen.V406.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V406.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V406.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V406.Range.Range, Evergreen.V406.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V406.Range.Range, Evergreen.V406.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V406.Call.FromJs)
    | VoiceChatMsg Evergreen.V406.Call.Msg
    | PressedChannelHeaderTab Evergreen.V406.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V406.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V406.Audio.LoadError Evergreen.V406.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V406.Route.Route
    | PressedMuteChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V406.Id.AnyGuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V406.Id.AnyGuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) Evergreen.V406.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V406.Encryption.FromJs (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V406.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V406.UserSession.UserSession
    , currentlyViewing : Evergreen.V406.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) Evergreen.V406.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId) Evergreen.V406.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId) Evergreen.V406.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) Evergreen.V406.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId)
    , user : Evergreen.V406.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.User.FrontendUser
    , discordUsers : Evergreen.V406.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V406.SessionIdHash.SessionIdHash Evergreen.V406.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V406.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId) Evergreen.V406.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId) Evergreen.V406.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V406.Call.CallId (Evergreen.V406.NonemptyDict.NonemptyDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V406.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type LoginType
    = LoginWithEmail
    | LoginWithRecoveryPassword


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V406.Go.PublicGoMatchData Evergreen.V406.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V406.Route.Route
    , windowSize : Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V406.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V406.Audio.LoadError Evergreen.V406.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Encryption.EncryptedData (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.NonemptyDict.NonemptyDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Encryption.EncryptedData (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V406.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V406.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V406.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileData) (List Evergreen.V406.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V406.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V406.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V406.Id.SlackGuildOrDmId String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.ChannelName.ChannelName Evergreen.V406.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.ChannelName.ChannelName Evergreen.V406.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V406.GuildName.GuildName (Evergreen.V406.UserSession.ToBeFilledInByBackend (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V406.Id.Viewing_DiscordDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V406.SetViewing.SetViewing
    | Local_SetName Evergreen.V406.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V406.Id.GuildOrDmId (Evergreen.V406.VisibleMessages.PageRequest Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend Evergreen.V406.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V406.Id.GuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.VisibleMessages.PageRequest Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V406.Id.SlackGuildOrDmId (Evergreen.V406.VisibleMessages.PageRequest Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V406.Id.DiscordGuildOrDmId (Evergreen.V406.VisibleMessages.PageRequest Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V406.Id.DiscordGuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.VisibleMessages.PageRequest Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V406.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V406.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V406.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.QuestionId Evergreen.V406.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V406.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V406.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V406.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V406.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V406.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V406.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V406.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V406.NonemptySet.NonemptySet (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V406.Call.LocalChange
    | Local_Game Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Game.LocalChange
    | Local_Drawing Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Drawing.AnchorType Evergreen.V406.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V406.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V406.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V406.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V406.X25519.PublicKey (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V406.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V406.Id.Viewing_DmId (List ( Evergreen.V406.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V406.FileStatus.FileHash, Evergreen.V406.Encryption.EncryptedData (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V406.Id.Viewing_DmId (Evergreen.V406.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V406.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V406.Id.ThreadRouteWithMessage, Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V406.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V406.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V406.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V406.FileStatus.FileHash) (Evergreen.V406.Encryption.EncryptedData (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))) (Evergreen.V406.Encryption.EncryptedData String) Evergreen.V406.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V406.Id.Viewing_DmId Evergreen.V406.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V406.FileStatus.FileHash) (Evergreen.V406.Encryption.EncryptedData (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    | RepliedToGame Evergreen.V406.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
        , sender : Evergreen.V406.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V406.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
        , threadRoute : Evergreen.V406.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId) Evergreen.V406.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V406.Id.SlackGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix Evergreen.V406.Id.SlackGuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V406.Id.SlackGuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    | Server_Slack_UnlinkUser (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V406.Id.DiscordGuildOrDmId Evergreen.V406.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))) Evergreen.V406.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId) Evergreen.V406.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.ChannelName.ChannelName Evergreen.V406.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.ChannelName.ChannelName Evergreen.V406.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.User.FrontendUser
    | Server_MemberLeft (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V406.LocalState.JoinGuildError
            { guildId : Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId
            , guild : Evergreen.V406.LocalState.FrontendGuild
            , owner : Evergreen.V406.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V406.Id.Viewing_DiscordDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Maybe Evergreen.V406.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Maybe Evergreen.V406.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V406.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V406.SessionIdHash.SessionIdHash Evergreen.V406.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V406.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V406.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V406.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V406.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V406.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Bool Evergreen.V406.ChannelName.ChannelName (Evergreen.V406.Discord.OptionalData (Maybe String)) (List Evergreen.V406.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
        (Evergreen.V406.NonemptyDict.NonemptyDict
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) Evergreen.V406.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Maybe (Evergreen.V406.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V406.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V406.Log.Log
    | Server_BackupGenerated Evergreen.V406.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V406.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V406.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V406.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V406.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (Evergreen.V406.Discord.OptionalData (Maybe String)) (Evergreen.V406.Discord.OptionalData (Maybe String)) (List Evergreen.V406.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.GuildName.GuildName (Maybe Evergreen.V406.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId) Evergreen.V406.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId) Evergreen.V406.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
        (Evergreen.V406.MembersAndOwner.MembersAndOwner
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.PersonName.PersonName Evergreen.V406.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId) Evergreen.V406.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId) Evergreen.V406.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V406.Call.ServerChange
    | Server_Game (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Game.LocalChange
    | Server_Drawing (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Drawing.AnchorType Evergreen.V406.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V406.Id.Viewing_DmId ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V406.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V406.Id.Viewing_DmId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | Server_E2eeAccepted Evergreen.V406.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
        , sender : Evergreen.V406.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V406.Id.Viewing_DmId
        , content : Evergreen.V406.Encryption.EncryptedData (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
        , threadRoute : Evergreen.V406.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V406.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.Viewing_DmId Evergreen.V406.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V406.FileStatus.FileHash) (Evergreen.V406.Encryption.EncryptedData (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V406.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V406.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V406.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V406.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V406.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V406.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V406.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V406.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V406.Id.AnyGuildOrDmId Evergreen.V406.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V406.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels) (Maybe Evergreen.V406.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V406.SheepGame.Input (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels) (Maybe Evergreen.V406.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V406.Id.GuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V406.Id.GuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.NonemptySet.NonemptySet Int))
    }


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result Evergreen.V406.Slack.HttpError String))


type alias UserOptionsModel =
    { name : Evergreen.V406.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V406.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V406.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , threadRoute : Evergreen.V406.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V406.Encryption.BytesHash
    , id : Evergreen.V406.Id.Viewing_DmId
    , senderId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , threadRoute : Evergreen.V406.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V406.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V406.Id.Viewing_DmId
    , messages : List Evergreen.V406.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V406.Id.Viewing_DmId
    , messages : List ( Evergreen.V406.Id.ThreadRouteWithMessage, Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V406.Id.Viewing_DmId
    , threadRoute : Evergreen.V406.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute )
    , fileId : Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V406.Id.Id Evergreen.V406.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V406.Id.Id Evergreen.V406.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V406.Id.Id Evergreen.V406.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V406.Id.Id Evergreen.V406.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V406.Id.Id Evergreen.V406.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V406.Local.Local LocalMsg Evergreen.V406.LocalState.LocalState
    , admin : Evergreen.V406.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V406.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V406.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.Message.RepliedTo Evergreen.V406.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V406.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V406.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V406.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.ThreadRoute ) (Evergreen.V406.NonemptyDict.NonemptyDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V406.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V406.Scroll.ScrollPosition
    , textEditor : Evergreen.V406.TextEditor.Model
    , profilePictureEditor : Evergreen.V406.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId, Evergreen.V406.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V406.Emoji.Model
    , voiceChat : Evergreen.V406.Call.Model
    , games : SeqDict.SeqDict Evergreen.V406.Id.GuildOrDmId Evergreen.V406.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V406.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V406.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V406.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V406.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V406.Range.Range
                , direction : Evergreen.V406.Range.SelectionDirection
                }
        }


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup
    | RecoveryPasswordInvalid
    | UserIsDeleted


type LinkDiscordFailure
    = LinkDiscordHttpError Evergreen.V406.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V406.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V406.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V406.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V406.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V406.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V406.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V406.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V406.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V406.MyUi.LastCopy
    , drag : Evergreen.V406.Touch.Drag
    , dragPrevious : Evergreen.V406.Touch.Drag
    , aiChatModel : Evergreen.V406.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V406.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V406.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V406.Audio.LoadError Evergreen.V406.Audio.Source
    , startupData : Evergreen.V406.Ports.StartupData
    , homePagePreview :
        { index : Int
        , changedAt : Effect.Time.Posix
        , rotate : Bool
        }
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V406.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V406.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V406.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V406.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
    , messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V406.OneToOne.OneToOne (Evergreen.V406.Slack.Id Evergreen.V406.Slack.MessageId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : String
    , channels : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId) SlackBackendChannel
    }


type alias SlackLinkedUser =
    { user : Evergreen.V406.Slack.User
    , linkedTo : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V406.Slack.SlackToken
    , cookie : Evergreen.V406.Slack.SlackCookie
    , websocket : Maybe Effect.Websocket.Connection
    , reconnect :
        { failedAttempts : Int
        , seed : Int
        }
    }


type SlackUserData
    = SlackBasicData Evergreen.V406.Slack.User
    | SlackFullData SlackLinkedUser


type alias SlackDmChannel =
    { teamId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId
    , members : Evergreen.V406.NonemptySet.NonemptySet (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
    , messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V406.OneToOne.OneToOne (Evergreen.V406.Slack.Id Evergreen.V406.Slack.MessageId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V406.FileStatus.FileHash
    , metadata : Maybe Evergreen.V406.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId, Evergreen.V406.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId, Evergreen.V406.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V406.DmChannelId.DmChannelId, Evergreen.V406.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId, Evergreen.V406.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId, Evergreen.V406.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId, Evergreen.V406.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V406.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V406.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V406.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias UploadBackupState =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    , clientId : Effect.Lamdera.ClientId
    }


type BackupTransfer
    = BackupDownload DownloadBackupState
    | BackupUpload UploadBackupState


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V406.NonemptyDict.NonemptyDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V406.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V406.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V406.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V406.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V406.DmChannelId.DmChannelId Evergreen.V406.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) Evergreen.V406.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) SlackUserData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId) SlackDmChannel
    , files : SeqDict.SeqDict Evergreen.V406.FileStatus.FileHash Evergreen.V406.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V406.FileStatus.FileHash
    , privateVapidKey : Evergreen.V406.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V406.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId, Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V406.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V406.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V406.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V406.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.LocalState.LoadingDiscordChannel Evergreen.V406.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , slackLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V406.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V406.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V406.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId) Evergreen.V406.Sticker.StickerData
    , discordStickers : Evergreen.V406.OneToOne.OneToOne (Evergreen.V406.Discord.Id Evergreen.V406.Discord.StickerId) (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId) Evergreen.V406.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V406.OneToOne.OneToOne Evergreen.V406.RichText.DiscordCustomEmojiIdAndName (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V406.Postmark.ApiKey
    , serverSecret : Evergreen.V406.SecretId.SecretId Evergreen.V406.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V406.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V406.OneToOne.OneToOne (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.GamePublicId) ( Evergreen.V406.DmChannelId.GuildOrFullDmId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V406.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V406.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId, String ) Int
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) Duration.Duration
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V406.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.Id.ThreadRoute (Maybe Evergreen.V406.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V406.DmChannelId.DmChannelId Evergreen.V406.Id.ThreadRoute (Maybe Evergreen.V406.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V406.Id.Id Evergreen.V406.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V406.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V406.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V406.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V406.UserAgent.UserAgent
    | AdminToBackend Evergreen.V406.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V406.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V406.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V406.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V406.PersonName.PersonName Evergreen.V406.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V406.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V406.Discord.UserAuth
    | LinkSlackRequest Evergreen.V406.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V406.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V406.Id.Id Evergreen.V406.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V406.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V406.EmailAddress.EmailAddress (Result Evergreen.V406.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V406.EmailAddress.EmailAddress (Result Evergreen.V406.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V406.EmailAddress.EmailAddress (Result Evergreen.V406.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V406.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMaybeMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Result Evergreen.V406.Discord.HttpError Evergreen.V406.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V406.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Result Evergreen.V406.Discord.HttpError Evergreen.V406.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V406.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V406.Id.SlackGuildOrDmId String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId))) (Result Evergreen.V406.Slack.HttpError (Evergreen.V406.Slack.Id Evergreen.V406.Slack.MessageId))
    | SlackWebsocketCreatedHandle (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) (Result Evergreen.V406.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) (Result Evergreen.V406.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) (Result Evergreen.V406.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) (Result Evergreen.V406.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji (Result Evergreen.V406.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji (Result Evergreen.V406.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji (Result Evergreen.V406.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji (Result Evergreen.V406.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V406.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V406.Discord.HttpError (List ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId, Maybe Evergreen.V406.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Effect.Time.Posix Evergreen.V406.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V406.Slack.SlackToken, Result Evergreen.V406.Slack.HttpError Evergreen.V406.Slack.UserBoot ))
    | LinkSlackUserStep2
        Effect.Time.Posix
        (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId)
        (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
        (Result
            Evergreen.V406.Slack.HttpError
            { channels : List ( Evergreen.V406.Slack.Channel, List Evergreen.V406.Slack.Message )
            , dmChannels : List ( Evergreen.V406.Slack.DmChannel, List Evergreen.V406.Slack.Message )
            , users : List Evergreen.V406.Slack.User
            }
        )
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Discord.UserAuth (Result Evergreen.V406.Discord.HttpError Evergreen.V406.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Result Evergreen.V406.Discord.HttpError Evergreen.V406.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
        (Result
            Evergreen.V406.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId
                    , members : List (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
                    , messages : List Evergreen.V406.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId
                    , { guild : Evergreen.V406.Discord.GatewayGuild
                      , channels : List Evergreen.V406.Discord.Channel
                      , icon : Maybe Evergreen.V406.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (List Evergreen.V406.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V406.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V406.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V406.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V406.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.AttachmentId, Evergreen.V406.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V406.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.AttachmentId, Evergreen.V406.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V406.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V406.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V406.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V406.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (Result Evergreen.V406.Discord.HttpError Evergreen.V406.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Result Evergreen.V406.Discord.HttpError (List Evergreen.V406.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V406.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V406.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V406.DmChannelId.DmChannelId Evergreen.V406.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V406.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V406.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V406.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
        (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V406.Discord.HttpError
            { guild : Evergreen.V406.Discord.GatewayGuild
            , channels : List Evergreen.V406.Discord.Channel
            , icon : Maybe Evergreen.V406.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Maybe Evergreen.V406.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Result Evergreen.V406.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V406.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V406.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (List ( Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId, Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId, Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (List ( Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V406.Discord.HttpError (List Evergreen.V406.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V406.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V406.SecretId.SecretId Evergreen.V406.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V406.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V406.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V406.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V406.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Result Evergreen.V406.Discord.HttpError ( Evergreen.V406.Discord.Guild, List Evergreen.V406.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V406.FileStatus.FileHash Int (Maybe (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Call.CallId
