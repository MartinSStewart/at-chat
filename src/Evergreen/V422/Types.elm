module Evergreen.V422.Types exposing (..)

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
import Evergreen.V422.AiChat
import Evergreen.V422.Audio
import Evergreen.V422.BackendMsgLog
import Evergreen.V422.Call
import Evergreen.V422.ChannelDescription
import Evergreen.V422.ChannelName
import Evergreen.V422.Coord
import Evergreen.V422.CssPixels
import Evergreen.V422.CustomEmoji
import Evergreen.V422.Discord
import Evergreen.V422.DiscordAttachmentId
import Evergreen.V422.DiscordUserData
import Evergreen.V422.DmChannel
import Evergreen.V422.DmChannelId
import Evergreen.V422.Drawing
import Evergreen.V422.Editable
import Evergreen.V422.EmailAddress
import Evergreen.V422.Embed
import Evergreen.V422.Emoji
import Evergreen.V422.Encryption
import Evergreen.V422.FileStatus
import Evergreen.V422.Game
import Evergreen.V422.Go
import Evergreen.V422.GuildName
import Evergreen.V422.Id
import Evergreen.V422.IdArray
import Evergreen.V422.ImageEditor
import Evergreen.V422.ImageViewer
import Evergreen.V422.LinkedAndOtherDiscordUsers
import Evergreen.V422.Local
import Evergreen.V422.LocalState
import Evergreen.V422.Log
import Evergreen.V422.LoginForm
import Evergreen.V422.MembersAndOwner
import Evergreen.V422.Message
import Evergreen.V422.MessageInput
import Evergreen.V422.MessageView
import Evergreen.V422.MuteSettings
import Evergreen.V422.MyUi
import Evergreen.V422.NonemptyDict
import Evergreen.V422.NonemptySet
import Evergreen.V422.OneOrGreater
import Evergreen.V422.OneToOne
import Evergreen.V422.Pages.Admin
import Evergreen.V422.Pagination
import Evergreen.V422.PeerToPeer
import Evergreen.V422.PersonName
import Evergreen.V422.Ports
import Evergreen.V422.Postmark
import Evergreen.V422.Range
import Evergreen.V422.RateLimit
import Evergreen.V422.RecoveryLogin
import Evergreen.V422.RichText
import Evergreen.V422.Route
import Evergreen.V422.Scroll
import Evergreen.V422.SecretId
import Evergreen.V422.SessionIdHash
import Evergreen.V422.SetViewing
import Evergreen.V422.SheepGame
import Evergreen.V422.Slack
import Evergreen.V422.Sticker
import Evergreen.V422.TextEditor
import Evergreen.V422.Thread
import Evergreen.V422.ToBackendLog
import Evergreen.V422.Touch
import Evergreen.V422.TwoFactorAuthentication
import Evergreen.V422.Ui.Anim
import Evergreen.V422.User
import Evergreen.V422.UserAgent
import Evergreen.V422.UserColor
import Evergreen.V422.UserSession
import Evergreen.V422.VisibleMessages
import Evergreen.V422.WordSpellingGame
import Evergreen.V422.X25519
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
    | LoginFormMsg Evergreen.V422.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V422.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V422.Pages.Admin.Msg
    | PressedLogOut Evergreen.V422.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V422.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V422.Route.Route
    | SelectedFilesToAttach ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | SelectedPeerToPeerFileToShareAgain Evergreen.V422.Id.GuildOrDmId Evergreen.V422.FileStatus.PeerToPeerFile Effect.File.File
    | SentPeerToPeerFile Evergreen.V422.FileStatus.PeerToPeerId (Result Effect.Http.Error ())
    | NewChannelFormChanged (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | PressedImportChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V422.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V422.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V422.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V422.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V422.NonemptyDict.NonemptyDict Int Evergreen.V422.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V422.NonemptyDict.NonemptyDict Int Evergreen.V422.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRoute Evergreen.V422.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId))
    | MessageMenu_PressedOpenDm (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V422.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V422.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V422.AiChat.Msg
    | GameMsg Evergreen.V422.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V422.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V422.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V422.Editable.Msg Evergreen.V422.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V422.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) (Maybe Evergreen.V422.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V422.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute )
        { fileId : Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute )
        { fileId : Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V422.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V422.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V422.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V422.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V422.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V422.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V422.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V422.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | PressedDisableE2ee (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | TypedPrivateKey (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) String
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
    | TextEditorMsg Evergreen.V422.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId
        , otherUserId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V422.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRoute Evergreen.V422.MessageInput.Msg
    | MessageInputMsg Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRoute Evergreen.V422.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V422.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V422.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V422.Range.Range, Evergreen.V422.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V422.Range.Range, Evergreen.V422.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V422.Call.FromJs)
    | VoiceChatMsg Evergreen.V422.Call.Msg
    | PressedChannelHeaderTab Evergreen.V422.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V422.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V422.Audio.LoadError Evergreen.V422.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V422.Route.Route
    | PressedMuteChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteDiscordDm (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteSlackDm (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) Evergreen.V422.MuteSettings.IsMuted
    | PressedMuteSlackDmThread (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V422.Id.AnyGuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V422.Id.AnyGuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) Evergreen.V422.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V422.Encryption.FromJs (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V422.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V422.UserSession.UserSession
    , currentlyViewing : Evergreen.V422.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) Evergreen.V422.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    , user : Evergreen.V422.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.User.FrontendUser
    , discordUsers : Evergreen.V422.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V422.SessionIdHash.SessionIdHash Evergreen.V422.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V422.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId) Evergreen.V422.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId) Evergreen.V422.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V422.Call.CallId (Evergreen.V422.NonemptyDict.NonemptyDict ( Evergreen.V422.Id.Id Evergreen.V422.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V422.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V422.Call.CallId Evergreen.V422.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V422.Go.PublicGoMatchData Evergreen.V422.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V422.Route.Route
    , windowSize : Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V422.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V422.Audio.LoadError Evergreen.V422.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Encryption.EncryptedData (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.NonemptyDict.NonemptyDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Encryption.EncryptedData (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V422.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V422.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V422.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment) (List Evergreen.V422.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V422.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V422.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.ChannelName.ChannelName Evergreen.V422.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.ChannelName.ChannelName Evergreen.V422.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V422.GuildName.GuildName (Evergreen.V422.UserSession.ToBeFilledInByBackend (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V422.Id.Viewing_DiscordDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V422.SetViewing.SetViewing
    | Local_SetName Evergreen.V422.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.VisibleMessages.PageRequest Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend Evergreen.V422.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.VisibleMessages.PageRequest Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V422.Id.SlackGuildOrDmId (Evergreen.V422.VisibleMessages.PageRequest Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V422.Id.SlackGuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.VisibleMessages.PageRequest Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V422.Id.DiscordGuildOrDmId (Evergreen.V422.VisibleMessages.PageRequest Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V422.Id.DiscordGuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.VisibleMessages.PageRequest Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V422.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V422.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V422.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.QuestionId Evergreen.V422.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V422.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V422.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V422.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V422.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V422.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V422.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V422.UserColor.UserColor
    | Local_AddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId))
    | Local_VoiceChatChange Evergreen.V422.Call.LocalChange
    | Local_Game Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Game.LocalChange
    | Local_Drawing Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Drawing.AnchorType Evergreen.V422.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteDiscordDm (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteSlackDm (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Local_SetMuteSlackDmThread (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V422.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V422.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V422.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V422.X25519.PublicKey (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V422.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V422.Id.Viewing_DmId (List ( Evergreen.V422.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V422.FileStatus.FileHash, Evergreen.V422.Encryption.EncryptedData (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V422.Id.Viewing_DmId (Evergreen.V422.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V422.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V422.Id.ThreadRouteWithMessage, Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V422.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V422.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V422.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V422.FileStatus.FileHash) (Evergreen.V422.Encryption.EncryptedData (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))) (Evergreen.V422.Encryption.EncryptedData String) Evergreen.V422.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V422.Id.Viewing_DmId Evergreen.V422.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V422.FileStatus.FileHash) (Evergreen.V422.Encryption.EncryptedData (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    | RepliedToGame Evergreen.V422.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
        , sender : Evergreen.V422.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V422.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
        , threadRoute : Evergreen.V422.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment
        , stickers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId) Evergreen.V422.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment) (Maybe (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) Evergreen.V422.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V422.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
        (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) Evergreen.V422.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId) Evergreen.V422.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId) Evergreen.V422.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId) Evergreen.V422.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V422.Id.DiscordGuildOrDmId Evergreen.V422.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))) Evergreen.V422.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment) (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId) Evergreen.V422.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.ChannelName.ChannelName Evergreen.V422.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.ChannelName.ChannelName Evergreen.V422.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.User.FrontendUser
    | Server_MemberLeft (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V422.LocalState.JoinGuildError
            { guildId : Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId
            , guild : Evergreen.V422.LocalState.FrontendGuild
            , owner : Evergreen.V422.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V422.NonemptySet.NonemptySet (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.CallRecordingFile (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V422.Id.Viewing_DiscordDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Maybe Evergreen.V422.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Maybe Evergreen.V422.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V422.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V422.SessionIdHash.SessionIdHash Evergreen.V422.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V422.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V422.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V422.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V422.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V422.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Bool Evergreen.V422.ChannelName.ChannelName (Evergreen.V422.Discord.OptionalData (Maybe String)) (List Evergreen.V422.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
        (Evergreen.V422.NonemptyDict.NonemptyDict
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Maybe (Evergreen.V422.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V422.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V422.Log.Log
    | Server_BackupGenerated Evergreen.V422.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V422.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V422.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V422.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V422.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (Evergreen.V422.Discord.OptionalData (Maybe String)) (Evergreen.V422.Discord.OptionalData (Maybe String)) (List Evergreen.V422.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.GuildName.GuildName (Maybe Evergreen.V422.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId) Evergreen.V422.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId) Evergreen.V422.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
        (Evergreen.V422.MembersAndOwner.MembersAndOwner
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.PersonName.PersonName Evergreen.V422.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId) Evergreen.V422.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId) Evergreen.V422.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V422.Call.ServerChange
    | Server_Game (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Game.LocalChange
    | Server_Drawing (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Drawing.AnchorType Evergreen.V422.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteDiscordDm (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteSlackDm (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) Evergreen.V422.MuteSettings.IsMuted
    | Server_SetMuteSlackDmThread (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V422.Id.Viewing_DmId ( Evergreen.V422.Id.Id Evergreen.V422.Id.UserId, Evergreen.V422.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V422.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V422.Id.Viewing_DmId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | Server_E2eeAccepted Evergreen.V422.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
        , sender : Evergreen.V422.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V422.Id.Viewing_DmId
        , content : Evergreen.V422.Encryption.EncryptedData (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
        , threadRoute : Evergreen.V422.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V422.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.Viewing_DmId Evergreen.V422.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V422.FileStatus.FileHash) (Evergreen.V422.Encryption.EncryptedData (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V422.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V422.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V422.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V422.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V422.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V422.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V422.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V422.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V422.Id.AnyGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V422.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels) (Maybe Evergreen.V422.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V422.SheepGame.Input (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels) (Maybe Evergreen.V422.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V422.Id.GuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId) (Evergreen.V422.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V422.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V422.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V422.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V422.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , threadRoute : Evergreen.V422.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V422.Encryption.BytesHash
    , id : Evergreen.V422.Id.Viewing_DmId
    , senderId : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , threadRoute : Evergreen.V422.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V422.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V422.Id.Viewing_DmId
    , messages : List Evergreen.V422.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V422.Id.Viewing_DmId
    , messages : List ( Evergreen.V422.Id.ThreadRouteWithMessage, Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V422.Id.Viewing_DmId
    , threadRoute : Evergreen.V422.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute )
    , fileId : Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V422.Id.Id Evergreen.V422.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V422.Id.Id Evergreen.V422.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V422.Id.Id Evergreen.V422.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V422.Id.Id Evergreen.V422.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V422.Id.Id Evergreen.V422.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V422.Local.Local LocalMsg Evergreen.V422.LocalState.LocalState
    , admin : Evergreen.V422.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId, Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V422.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V422.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.Message.RepliedTo Evergreen.V422.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V422.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V422.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V422.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.ThreadRoute ) (Evergreen.V422.NonemptyDict.NonemptyDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V422.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V422.Scroll.ScrollPosition
    , textEditor : Evergreen.V422.TextEditor.Model
    , profilePictureEditor : Evergreen.V422.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId, Evergreen.V422.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V422.Emoji.Model
    , voiceChat : Evergreen.V422.Call.Model
    , games : SeqDict.SeqDict Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V422.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V422.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V422.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V422.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V422.Range.Range
                , direction : Evergreen.V422.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V422.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V422.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V422.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V422.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V422.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | PeerToPeerDownloadResponse (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.FileStatus.PeerToPeerId (Maybe String)
    | PeerToPeerSendFileRequest Evergreen.V422.FileStatus.PeerToPeerId String
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V422.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V422.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V422.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V422.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V422.MyUi.LastCopy
    , drag : Evergreen.V422.Touch.Drag
    , dragPrevious : Evergreen.V422.Touch.Drag
    , aiChatModel : Evergreen.V422.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V422.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V422.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V422.Audio.LoadError Evergreen.V422.Audio.Source
    , startupData : Evergreen.V422.Ports.StartupData
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
    Evergreen.V422.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V422.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V422.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V422.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    , messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.Slack.Id Evergreen.V422.Slack.MessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V422.Slack.User
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V422.Slack.User
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , linkedTo : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V422.Slack.SlackToken
    , cookie : Evergreen.V422.Slack.SlackCookie
    , websocket : Maybe Effect.Websocket.Connection
    , reconnect :
        { failedAttempts : Int
        , seed : Int
        }
    , needsAuthAgain : Bool
    }


type SlackUserData
    = SlackBasicData SlackBasicUserData
    | SlackFullData SlackLinkedUser


type alias SlackFileData =
    { fileHash : Evergreen.V422.FileStatus.FileHash
    , metadata : Maybe Evergreen.V422.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId
    , members : Evergreen.V422.NonemptySet.NonemptySet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    , messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.Slack.Id Evergreen.V422.Slack.MessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V422.FileStatus.FileHash
    , metadata : Maybe Evergreen.V422.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId, Evergreen.V422.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId, Evergreen.V422.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V422.DmChannelId.DmChannelId, Evergreen.V422.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId, Evergreen.V422.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId, Evergreen.V422.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId, Evergreen.V422.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V422.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V422.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V422.LocalState.BackupContents
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
    { users : Evergreen.V422.NonemptyDict.NonemptyDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V422.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V422.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V422.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V422.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V422.DmChannelId.DmChannelId Evergreen.V422.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V422.FileStatus.FileHash Evergreen.V422.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V422.FileStatus.FileHash
    , privateVapidKey : Evergreen.V422.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    , textEditor : Evergreen.V422.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId, Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V422.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V422.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V422.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V422.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.LocalState.LoadingDiscordChannel Evergreen.V422.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , slackLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , slackLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Array.Array Effect.Time.Posix)
    , peerToPeerRateLimits : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V422.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V422.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V422.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId) Evergreen.V422.Sticker.StickerData
    , discordStickers : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.Discord.Id Evergreen.V422.Discord.StickerId) (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId) Evergreen.V422.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V422.OneToOne.OneToOne Evergreen.V422.RichText.DiscordCustomEmojiIdAndName (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V422.Postmark.ApiKey
    , serverSecret : Evergreen.V422.SecretId.SecretId Evergreen.V422.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V422.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.GamePublicId) ( Evergreen.V422.DmChannelId.GuildOrFullDmId, Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V422.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V422.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V422.Call.SharedCallId Evergreen.V422.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V422.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.Id.ThreadRoute (Maybe Evergreen.V422.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V422.DmChannelId.DmChannelId Evergreen.V422.Id.ThreadRoute (Maybe Evergreen.V422.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V422.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V422.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V422.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V422.UserAgent.UserAgent
    | AdminToBackend Evergreen.V422.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V422.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V422.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V422.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V422.PersonName.PersonName Evergreen.V422.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V422.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V422.Discord.UserAuth
    | LinkSlackRequest Evergreen.V422.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V422.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V422.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
        { fileName : String
        , json : String
        }
    | SharePeerToPeerFileRequest Evergreen.V422.FileStatus.PeerToPeerId Evergreen.V422.PeerToPeer.SharedFile
    | PeerToPeerDownloadRequest Evergreen.V422.Id.GuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.FileStatus.PeerToPeerId


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V422.Slack.Channel, Evergreen.V422.Slack.History )
    , dmChannels : List ( Evergreen.V422.Slack.DmChannel, Evergreen.V422.Slack.History )
    , users : List ( Evergreen.V422.Slack.User, Maybe Evergreen.V422.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V422.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V422.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V422.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V422.EmailAddress.EmailAddress (Result Evergreen.V422.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V422.EmailAddress.EmailAddress (Result Evergreen.V422.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V422.EmailAddress.EmailAddress (Result Evergreen.V422.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V422.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMaybeMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Result Evergreen.V422.Discord.HttpError Evergreen.V422.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V422.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Result Evergreen.V422.Discord.HttpError Evergreen.V422.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V422.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V422.RichText.RichText (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId) Evergreen.V422.FileStatus.Attachment) (Result Evergreen.V422.Slack.HttpError ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.MessageId, List ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.FileId, Evergreen.V422.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) (Result Evergreen.V422.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) (Result Evergreen.V422.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) (Result Evergreen.V422.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) (Result Evergreen.V422.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji (Result Evergreen.V422.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji (Result Evergreen.V422.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji (Result Evergreen.V422.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji (Result Evergreen.V422.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V422.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V422.Discord.HttpError (List ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId, Maybe Evergreen.V422.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Effect.Time.Posix Evergreen.V422.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Result Evergreen.V422.Slack.HttpError ( Evergreen.V422.Slack.User, Maybe Evergreen.V422.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V422.Slack.User (Maybe Evergreen.V422.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V422.Id.SlackGuildOrDmId (Result Evergreen.V422.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V422.Id.SlackGuildOrDmId (Result Evergreen.V422.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V422.Id.SlackGuildOrDmId (Result Evergreen.V422.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V422.Slack.SlackToken, Result Evergreen.V422.Slack.HttpError Evergreen.V422.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Result Evergreen.V422.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (List Evergreen.V422.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Result Evergreen.V422.Slack.HttpError Evergreen.V422.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V422.Slack.HttpError ) ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Discord.UserAuth (Result Evergreen.V422.Discord.HttpError Evergreen.V422.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Result Evergreen.V422.Discord.HttpError Evergreen.V422.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
        (Result
            Evergreen.V422.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId
                    , members : List (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
                    , messages : List Evergreen.V422.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId
                    , { guild : Evergreen.V422.Discord.GatewayGuild
                      , channels : List Evergreen.V422.Discord.Channel
                      , icon : Maybe Evergreen.V422.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.LocalState.DiscordChannelReload
            , attachments : List (Result Effect.Http.Error ( Evergreen.V422.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V422.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V422.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V422.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.AttachmentId, Evergreen.V422.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V422.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.AttachmentId, Evergreen.V422.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V422.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V422.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V422.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V422.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (Result Evergreen.V422.Discord.HttpError Evergreen.V422.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Result Evergreen.V422.Discord.HttpError (List Evergreen.V422.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V422.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V422.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V422.DmChannelId.DmChannelId Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V422.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V422.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V422.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V422.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
        (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V422.Discord.HttpError
            { guild : Evergreen.V422.Discord.GatewayGuild
            , channels : List Evergreen.V422.Discord.Channel
            , icon : Maybe Evergreen.V422.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Maybe Evergreen.V422.FileStatus.UploadResponse)
    | ToBackendCompleted
        Evergreen.V422.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V422.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (List ( Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId, Result Effect.Http.Error Evergreen.V422.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId, Result Effect.Http.Error Evergreen.V422.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (List ( Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V422.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (List ( Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V422.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V422.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V422.Discord.HttpError (List Evergreen.V422.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V422.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V422.SecretId.SecretId Evergreen.V422.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V422.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V422.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V422.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V422.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Result Evergreen.V422.Discord.HttpError ( Evergreen.V422.Discord.Guild, List Evergreen.V422.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V422.FileStatus.FileHash Int (Maybe (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V422.Call.SharedCallId Effect.Time.Posix (Evergreen.V422.Message.CallRecordingFile (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V422.Call.SharedCallId Effect.Time.Posix (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V422.Call.SharedCallId Effect.Time.Posix Evergreen.V422.Message.CallRecordingZip
