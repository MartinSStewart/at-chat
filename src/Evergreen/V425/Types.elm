module Evergreen.V425.Types exposing (..)

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
import Evergreen.V425.AiChat
import Evergreen.V425.Audio
import Evergreen.V425.BackendMsgLog
import Evergreen.V425.Call
import Evergreen.V425.ChannelDescription
import Evergreen.V425.ChannelName
import Evergreen.V425.Coord
import Evergreen.V425.CssPixels
import Evergreen.V425.CustomEmoji
import Evergreen.V425.Discord
import Evergreen.V425.DiscordAttachmentId
import Evergreen.V425.DiscordUserData
import Evergreen.V425.DmChannel
import Evergreen.V425.DmChannelId
import Evergreen.V425.Drawing
import Evergreen.V425.Editable
import Evergreen.V425.EmailAddress
import Evergreen.V425.Embed
import Evergreen.V425.Emoji
import Evergreen.V425.Encryption
import Evergreen.V425.FileStatus
import Evergreen.V425.Game
import Evergreen.V425.Go
import Evergreen.V425.GuildName
import Evergreen.V425.Id
import Evergreen.V425.IdArray
import Evergreen.V425.ImageEditor
import Evergreen.V425.ImageViewer
import Evergreen.V425.LinkedAndOtherDiscordUsers
import Evergreen.V425.Local
import Evergreen.V425.LocalState
import Evergreen.V425.Log
import Evergreen.V425.LoginForm
import Evergreen.V425.MembersAndOwner
import Evergreen.V425.Message
import Evergreen.V425.MessageInput
import Evergreen.V425.MessageView
import Evergreen.V425.MuteSettings
import Evergreen.V425.MyUi
import Evergreen.V425.NonemptyDict
import Evergreen.V425.NonemptySet
import Evergreen.V425.OneOrGreater
import Evergreen.V425.OneToOne
import Evergreen.V425.Pages.Admin
import Evergreen.V425.Pagination
import Evergreen.V425.PeerToPeer
import Evergreen.V425.PersonName
import Evergreen.V425.Ports
import Evergreen.V425.Postmark
import Evergreen.V425.Range
import Evergreen.V425.RateLimit
import Evergreen.V425.RecoveryLogin
import Evergreen.V425.RichText
import Evergreen.V425.Route
import Evergreen.V425.Scroll
import Evergreen.V425.SecretId
import Evergreen.V425.SessionIdHash
import Evergreen.V425.SetViewing
import Evergreen.V425.SheepGame
import Evergreen.V425.Slack
import Evergreen.V425.Sticker
import Evergreen.V425.TextEditor
import Evergreen.V425.Thread
import Evergreen.V425.ToBackendLog
import Evergreen.V425.Touch
import Evergreen.V425.TwoFactorAuthentication
import Evergreen.V425.Ui.Anim
import Evergreen.V425.User
import Evergreen.V425.UserAgent
import Evergreen.V425.UserColor
import Evergreen.V425.UserSession
import Evergreen.V425.VisibleMessages
import Evergreen.V425.WordSpellingGame
import Evergreen.V425.X25519
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
    | LoginFormMsg Evergreen.V425.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V425.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V425.Pages.Admin.Msg
    | PressedLogOut Evergreen.V425.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V425.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V425.Route.Route
    | SelectedFilesToAttach ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | SelectedPeerToPeerFileToShareAgain Evergreen.V425.Id.GuildOrDmId Evergreen.V425.FileStatus.PeerToPeerFile Effect.File.File
    | SentPeerToPeerFile Evergreen.V425.FileStatus.PeerToPeerId (Result Effect.Http.Error ())
    | NewChannelFormChanged (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | PressedImportChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V425.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V425.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V425.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V425.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V425.NonemptyDict.NonemptyDict Int Evergreen.V425.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V425.NonemptyDict.NonemptyDict Int Evergreen.V425.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRoute Evergreen.V425.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId))
    | MessageMenu_PressedOpenDm (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V425.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V425.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V425.AiChat.Msg
    | GameMsg Evergreen.V425.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V425.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V425.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V425.Editable.Msg Evergreen.V425.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V425.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) (Maybe Evergreen.V425.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute )
        { fileId : Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute )
        { fileId : Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V425.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V425.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V425.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V425.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V425.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V425.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V425.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | PressedDisableE2ee (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | TypedPrivateKey (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) String
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
    | TextEditorMsg Evergreen.V425.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId
        , otherUserId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V425.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRoute Evergreen.V425.MessageInput.Msg
    | MessageInputMsg Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRoute Evergreen.V425.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V425.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V425.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V425.Range.Range, Evergreen.V425.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V425.Range.Range, Evergreen.V425.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V425.Call.FromJs)
    | VoiceChatMsg Evergreen.V425.Call.Msg
    | PressedChannelHeaderTab Evergreen.V425.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V425.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V425.Audio.LoadError Evergreen.V425.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V425.Route.Route
    | PressedMuteChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteDiscordDm (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteSlackDm (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) Evergreen.V425.MuteSettings.IsMuted
    | PressedMuteSlackDmThread (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V425.Id.AnyGuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V425.Id.AnyGuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) Evergreen.V425.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V425.Encryption.FromJs (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V425.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V425.UserSession.UserSession
    , currentlyViewing : Evergreen.V425.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) Evergreen.V425.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    , user : Evergreen.V425.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.User.FrontendUser
    , discordUsers : Evergreen.V425.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V425.SessionIdHash.SessionIdHash Evergreen.V425.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V425.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId) Evergreen.V425.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId) Evergreen.V425.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V425.Call.CallId (Evergreen.V425.NonemptyDict.NonemptyDict ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V425.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V425.Call.CallId Evergreen.V425.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V425.Go.PublicGoMatchData Evergreen.V425.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V425.Route.Route
    , windowSize : Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V425.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V425.Audio.LoadError Evergreen.V425.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Encryption.EncryptedData (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.NonemptyDict.NonemptyDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Encryption.EncryptedData (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V425.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V425.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V425.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment) (List Evergreen.V425.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V425.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V425.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.ChannelName.ChannelName Evergreen.V425.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.ChannelName.ChannelName Evergreen.V425.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V425.GuildName.GuildName (Evergreen.V425.UserSession.ToBeFilledInByBackend (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V425.Id.Viewing_DiscordDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V425.SetViewing.SetViewing
    | Local_SetName Evergreen.V425.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.VisibleMessages.PageRequest Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend Evergreen.V425.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.VisibleMessages.PageRequest Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V425.Id.SlackGuildOrDmId (Evergreen.V425.VisibleMessages.PageRequest Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V425.Id.SlackGuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.VisibleMessages.PageRequest Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V425.Id.DiscordGuildOrDmId (Evergreen.V425.VisibleMessages.PageRequest Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V425.Id.DiscordGuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.VisibleMessages.PageRequest Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V425.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V425.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V425.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.QuestionId Evergreen.V425.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V425.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V425.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V425.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V425.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V425.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V425.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V425.UserColor.UserColor
    | Local_AddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId))
    | Local_VoiceChatChange Evergreen.V425.Call.LocalChange
    | Local_Game Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Game.LocalChange
    | Local_Drawing Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Drawing.AnchorType Evergreen.V425.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteDiscordDm (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteSlackDm (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Local_SetMuteSlackDmThread (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V425.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V425.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V425.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V425.X25519.PublicKey (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V425.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V425.Id.Viewing_DmId (List ( Evergreen.V425.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V425.FileStatus.FileHash, Evergreen.V425.Encryption.EncryptedData (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V425.Id.Viewing_DmId (Evergreen.V425.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V425.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V425.Id.ThreadRouteWithMessage, Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V425.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V425.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V425.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V425.FileStatus.FileHash) (Evergreen.V425.Encryption.EncryptedData (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))) (Evergreen.V425.Encryption.EncryptedData String) Evergreen.V425.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V425.Id.Viewing_DmId Evergreen.V425.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V425.FileStatus.FileHash) (Evergreen.V425.Encryption.EncryptedData (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    | RepliedToGame Evergreen.V425.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
        , sender : Evergreen.V425.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V425.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
        , threadRoute : Evergreen.V425.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment
        , stickers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId) Evergreen.V425.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment) (Maybe (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) Evergreen.V425.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V425.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
        (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) Evergreen.V425.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId) Evergreen.V425.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId) Evergreen.V425.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId) Evergreen.V425.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V425.Id.DiscordGuildOrDmId Evergreen.V425.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))) Evergreen.V425.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment) (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId) Evergreen.V425.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.ChannelName.ChannelName Evergreen.V425.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.ChannelName.ChannelName Evergreen.V425.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.User.FrontendUser
    | Server_MemberLeft (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V425.LocalState.JoinGuildError
            { guildId : Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId
            , guild : Evergreen.V425.LocalState.FrontendGuild
            , owner : Evergreen.V425.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V425.NonemptySet.NonemptySet (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.CallRecordingFile (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))) Evergreen.V425.Message.ChangeAttachments
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V425.Id.Viewing_DiscordDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))) Evergreen.V425.Message.ChangeAttachments
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Maybe Evergreen.V425.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Maybe Evergreen.V425.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V425.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V425.SessionIdHash.SessionIdHash Evergreen.V425.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V425.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V425.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V425.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V425.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V425.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Bool Evergreen.V425.ChannelName.ChannelName (Evergreen.V425.Discord.OptionalData (Maybe String)) (List Evergreen.V425.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
        (Evergreen.V425.NonemptyDict.NonemptyDict
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Maybe (Evergreen.V425.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V425.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V425.Log.Log
    | Server_BackupGenerated Evergreen.V425.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V425.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V425.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V425.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V425.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (Evergreen.V425.Discord.OptionalData (Maybe String)) (Evergreen.V425.Discord.OptionalData (Maybe String)) (List Evergreen.V425.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.GuildName.GuildName (Maybe Evergreen.V425.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId) Evergreen.V425.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId) Evergreen.V425.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
        (Evergreen.V425.MembersAndOwner.MembersAndOwner
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.PersonName.PersonName Evergreen.V425.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId) Evergreen.V425.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId) Evergreen.V425.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V425.Call.ServerChange
    | Server_Game (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Game.LocalChange
    | Server_Drawing (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Drawing.AnchorType Evergreen.V425.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteDiscordDm (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteSlackDm (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) Evergreen.V425.MuteSettings.IsMuted
    | Server_SetMuteSlackDmThread (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V425.Id.Viewing_DmId ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V425.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V425.Id.Viewing_DmId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | Server_E2eeAccepted Evergreen.V425.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
        , sender : Evergreen.V425.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V425.Id.Viewing_DmId
        , content : Evergreen.V425.Encryption.EncryptedData (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
        , threadRoute : Evergreen.V425.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V425.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.Viewing_DmId Evergreen.V425.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V425.FileStatus.FileHash) (Evergreen.V425.Encryption.EncryptedData (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V425.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V425.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V425.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V425.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V425.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V425.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V425.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V425.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V425.Id.AnyGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V425.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels) (Maybe Evergreen.V425.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V425.SheepGame.Input (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels) (Maybe Evergreen.V425.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V425.Id.GuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId) (Evergreen.V425.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V425.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V425.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V425.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V425.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , threadRoute : Evergreen.V425.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V425.Encryption.BytesHash
    , id : Evergreen.V425.Id.Viewing_DmId
    , senderId : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , threadRoute : Evergreen.V425.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V425.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V425.Id.Viewing_DmId
    , messages : List Evergreen.V425.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V425.Id.Viewing_DmId
    , messages : List ( Evergreen.V425.Id.ThreadRouteWithMessage, Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V425.Id.Viewing_DmId
    , threadRoute : Evergreen.V425.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute )
    , fileId : Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V425.Id.Id Evergreen.V425.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V425.Id.Id Evergreen.V425.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V425.Id.Id Evergreen.V425.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V425.Id.Id Evergreen.V425.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V425.Id.Id Evergreen.V425.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V425.Local.Local LocalMsg Evergreen.V425.LocalState.LocalState
    , admin : Evergreen.V425.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId, Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V425.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V425.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.Message.RepliedTo Evergreen.V425.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V425.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V425.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V425.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.ThreadRoute ) (Evergreen.V425.NonemptyDict.NonemptyDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V425.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V425.Scroll.ScrollPosition
    , textEditor : Evergreen.V425.TextEditor.Model
    , profilePictureEditor : Evergreen.V425.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId, Evergreen.V425.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V425.Emoji.Model
    , voiceChat : Evergreen.V425.Call.Model
    , games : SeqDict.SeqDict Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V425.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V425.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V425.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V425.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V425.Range.Range
                , direction : Evergreen.V425.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V425.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V425.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V425.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V425.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V425.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | PeerToPeerDownloadResponse (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.FileStatus.PeerToPeerId (Maybe String)
    | PeerToPeerSendFileRequest Evergreen.V425.FileStatus.PeerToPeerId String
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V425.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V425.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V425.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V425.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V425.MyUi.LastCopy
    , drag : Evergreen.V425.Touch.Drag
    , dragPrevious : Evergreen.V425.Touch.Drag
    , aiChatModel : Evergreen.V425.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V425.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V425.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V425.Audio.LoadError Evergreen.V425.Audio.Source
    , startupData : Evergreen.V425.Ports.StartupData
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
    Evergreen.V425.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V425.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V425.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V425.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    , messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.Slack.Id Evergreen.V425.Slack.MessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V425.Slack.User
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V425.Slack.User
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , linkedTo : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V425.Slack.SlackToken
    , cookie : Evergreen.V425.Slack.SlackCookie
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
    { fileHash : Evergreen.V425.FileStatus.FileHash
    , metadata : Maybe Evergreen.V425.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId
    , members : Evergreen.V425.NonemptySet.NonemptySet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    , messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.Slack.Id Evergreen.V425.Slack.MessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V425.FileStatus.FileHash
    , metadata : Maybe Evergreen.V425.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId, Evergreen.V425.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId, Evergreen.V425.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V425.DmChannelId.DmChannelId, Evergreen.V425.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId, Evergreen.V425.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId, Evergreen.V425.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId, Evergreen.V425.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V425.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V425.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V425.LocalState.BackupContents
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
    { users : Evergreen.V425.NonemptyDict.NonemptyDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V425.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V425.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V425.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V425.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V425.DmChannelId.DmChannelId Evergreen.V425.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V425.FileStatus.FileHash Evergreen.V425.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V425.FileStatus.FileHash
    , privateVapidKey : Evergreen.V425.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    , textEditor : Evergreen.V425.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId, Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V425.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V425.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V425.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V425.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.LocalState.LoadingDiscordChannel Evergreen.V425.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Array.Array Effect.Time.Posix)
    , peerToPeerRateLimits : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V425.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V425.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V425.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId) Evergreen.V425.Sticker.StickerData
    , discordStickers : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.Discord.Id Evergreen.V425.Discord.StickerId) (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId) Evergreen.V425.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V425.OneToOne.OneToOne Evergreen.V425.RichText.DiscordCustomEmojiIdAndName (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V425.Postmark.ApiKey
    , serverSecret : Evergreen.V425.SecretId.SecretId Evergreen.V425.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V425.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.GamePublicId) ( Evergreen.V425.DmChannelId.GuildOrFullDmId, Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V425.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V425.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V425.Call.SharedCallId Evergreen.V425.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V425.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.Id.ThreadRoute (Maybe Evergreen.V425.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V425.DmChannelId.DmChannelId Evergreen.V425.Id.ThreadRoute (Maybe Evergreen.V425.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V425.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V425.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V425.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V425.UserAgent.UserAgent
    | AdminToBackend Evergreen.V425.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V425.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V425.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V425.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V425.PersonName.PersonName Evergreen.V425.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V425.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V425.Discord.UserAuth
    | LinkSlackRequest Evergreen.V425.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V425.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V425.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
        { fileName : String
        , json : String
        }
    | SharePeerToPeerFileRequest Evergreen.V425.FileStatus.PeerToPeerId Evergreen.V425.PeerToPeer.SharedFile
    | PeerToPeerDownloadRequest Evergreen.V425.Id.GuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.FileStatus.PeerToPeerId


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V425.Slack.Channel, Evergreen.V425.Slack.History )
    , dmChannels : List ( Evergreen.V425.Slack.DmChannel, Evergreen.V425.Slack.History )
    , users : List ( Evergreen.V425.Slack.User, Maybe Evergreen.V425.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V425.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V425.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V425.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V425.EmailAddress.EmailAddress (Result Evergreen.V425.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V425.EmailAddress.EmailAddress (Result Evergreen.V425.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V425.EmailAddress.EmailAddress (Result Evergreen.V425.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V425.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMaybeMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Result Evergreen.V425.Discord.HttpError Evergreen.V425.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V425.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Result Evergreen.V425.Discord.HttpError Evergreen.V425.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V425.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment) (Result Evergreen.V425.Slack.HttpError ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.MessageId, List ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.FileId, Evergreen.V425.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) (Result Evergreen.V425.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) (Result Evergreen.V425.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) (Result Evergreen.V425.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) (Result Evergreen.V425.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji (Result Evergreen.V425.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji (Result Evergreen.V425.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji (Result Evergreen.V425.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji (Result Evergreen.V425.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V425.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V425.Discord.HttpError (List ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId, Maybe Evergreen.V425.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Effect.Time.Posix Evergreen.V425.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Result Evergreen.V425.Slack.HttpError ( Evergreen.V425.Slack.User, Maybe Evergreen.V425.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V425.Slack.User (Maybe Evergreen.V425.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V425.Id.SlackGuildOrDmId (Result Evergreen.V425.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V425.Id.SlackGuildOrDmId (Result Evergreen.V425.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V425.Id.SlackGuildOrDmId (Result Evergreen.V425.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V425.Slack.SlackToken, Result Evergreen.V425.Slack.HttpError Evergreen.V425.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Result Evergreen.V425.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (List Evergreen.V425.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Result Evergreen.V425.Slack.HttpError Evergreen.V425.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V425.Slack.HttpError ) ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Discord.UserAuth (Result Evergreen.V425.Discord.HttpError Evergreen.V425.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Result Evergreen.V425.Discord.HttpError Evergreen.V425.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
        (Result
            Evergreen.V425.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId
                    , members : List (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
                    , messages : List Evergreen.V425.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId
                    , { guild : Evergreen.V425.Discord.GatewayGuild
                      , channels : List Evergreen.V425.Discord.Channel
                      , icon : Maybe Evergreen.V425.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.LocalState.DiscordChannelReload
            , attachments : List (Result Effect.Http.Error ( Evergreen.V425.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V425.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V425.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V425.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.AttachmentId, Evergreen.V425.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V425.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.AttachmentId, Evergreen.V425.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V425.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V425.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V425.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V425.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (Result Evergreen.V425.Discord.HttpError Evergreen.V425.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Result Evergreen.V425.Discord.HttpError (List Evergreen.V425.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V425.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V425.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V425.DmChannelId.DmChannelId Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V425.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V425.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V425.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V425.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
        (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V425.Discord.HttpError
            { guild : Evergreen.V425.Discord.GatewayGuild
            , channels : List Evergreen.V425.Discord.Channel
            , icon : Maybe Evergreen.V425.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Maybe Evergreen.V425.FileStatus.UploadResponse)
    | ToBackendCompleted
        Evergreen.V425.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V425.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (List ( Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId, Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordCatchUpMessages (List Evergreen.V425.Discord.Message) (List (Result Effect.Http.Error ( Evergreen.V425.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V425.FileStatus.UploadResponse )))
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId, Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (List ( Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (List ( Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V425.Discord.HttpError (List Evergreen.V425.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V425.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V425.SecretId.SecretId Evergreen.V425.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V425.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V425.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V425.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V425.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Result Evergreen.V425.Discord.HttpError ( Evergreen.V425.Discord.Guild, List Evergreen.V425.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V425.FileStatus.FileHash Int (Maybe (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V425.Call.SharedCallId Effect.Time.Posix (Evergreen.V425.Message.CallRecordingFile (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V425.Call.SharedCallId Effect.Time.Posix (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V425.Call.SharedCallId Effect.Time.Posix Evergreen.V425.Message.CallRecordingZip
