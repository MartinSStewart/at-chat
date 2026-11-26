module Evergreen.V426.Types exposing (..)

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
import Evergreen.V426.AiChat
import Evergreen.V426.Audio
import Evergreen.V426.BackendMsgLog
import Evergreen.V426.Call
import Evergreen.V426.ChannelDescription
import Evergreen.V426.ChannelName
import Evergreen.V426.Coord
import Evergreen.V426.CssPixels
import Evergreen.V426.CustomEmoji
import Evergreen.V426.Discord
import Evergreen.V426.DiscordAttachmentId
import Evergreen.V426.DiscordUserData
import Evergreen.V426.DmChannel
import Evergreen.V426.DmChannelId
import Evergreen.V426.Drawing
import Evergreen.V426.Editable
import Evergreen.V426.EmailAddress
import Evergreen.V426.Embed
import Evergreen.V426.Emoji
import Evergreen.V426.Encryption
import Evergreen.V426.FileStatus
import Evergreen.V426.Game
import Evergreen.V426.Go
import Evergreen.V426.GuildName
import Evergreen.V426.Id
import Evergreen.V426.IdArray
import Evergreen.V426.ImageEditor
import Evergreen.V426.ImageViewer
import Evergreen.V426.LinkedAndOtherDiscordUsers
import Evergreen.V426.Local
import Evergreen.V426.LocalState
import Evergreen.V426.Log
import Evergreen.V426.LoginForm
import Evergreen.V426.MembersAndOwner
import Evergreen.V426.Message
import Evergreen.V426.MessageInput
import Evergreen.V426.MessageView
import Evergreen.V426.MuteSettings
import Evergreen.V426.MyUi
import Evergreen.V426.NonemptyDict
import Evergreen.V426.NonemptySet
import Evergreen.V426.OneOrGreater
import Evergreen.V426.OneToOne
import Evergreen.V426.Pages.Admin
import Evergreen.V426.Pagination
import Evergreen.V426.PeerToPeer
import Evergreen.V426.PersonName
import Evergreen.V426.Ports
import Evergreen.V426.Postmark
import Evergreen.V426.Range
import Evergreen.V426.RateLimit
import Evergreen.V426.RecoveryLogin
import Evergreen.V426.RichText
import Evergreen.V426.Route
import Evergreen.V426.Scroll
import Evergreen.V426.SecretId
import Evergreen.V426.SessionIdHash
import Evergreen.V426.SetViewing
import Evergreen.V426.SheepGame
import Evergreen.V426.Slack
import Evergreen.V426.Sticker
import Evergreen.V426.TextEditor
import Evergreen.V426.Thread
import Evergreen.V426.ToBackendLog
import Evergreen.V426.Touch
import Evergreen.V426.TwoFactorAuthentication
import Evergreen.V426.Ui.Anim
import Evergreen.V426.User
import Evergreen.V426.UserAgent
import Evergreen.V426.UserColor
import Evergreen.V426.UserSession
import Evergreen.V426.VisibleMessages
import Evergreen.V426.WordSpellingGame
import Evergreen.V426.X25519
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
    | LoginFormMsg Evergreen.V426.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V426.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V426.Pages.Admin.Msg
    | PressedLogOut Evergreen.V426.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V426.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V426.Route.Route
    | SelectedFilesToAttach ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | SelectedPeerToPeerFileToShareAgain Evergreen.V426.Id.GuildOrDmId Evergreen.V426.FileStatus.PeerToPeerFile Effect.File.File
    | SentPeerToPeerFile Evergreen.V426.FileStatus.PeerToPeerId (Result Effect.Http.Error ())
    | NewChannelFormChanged (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | PressedImportChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V426.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V426.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V426.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V426.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V426.NonemptyDict.NonemptyDict Int Evergreen.V426.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V426.NonemptyDict.NonemptyDict Int Evergreen.V426.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRoute Evergreen.V426.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId))
    | MessageMenu_PressedOpenDm (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V426.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V426.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V426.AiChat.Msg
    | GameMsg Evergreen.V426.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V426.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V426.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V426.Editable.Msg Evergreen.V426.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V426.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) (Maybe Evergreen.V426.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute )
        { fileId : Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute )
        { fileId : Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V426.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V426.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V426.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V426.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V426.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V426.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V426.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | PressedDisableE2ee (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | TypedPrivateKey (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) String
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
    | TextEditorMsg Evergreen.V426.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId
        , otherUserId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V426.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRoute Evergreen.V426.MessageInput.Msg
    | MessageInputMsg Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRoute Evergreen.V426.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V426.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V426.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V426.Range.Range, Evergreen.V426.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V426.Range.Range, Evergreen.V426.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V426.Call.FromJs)
    | VoiceChatMsg Evergreen.V426.Call.Msg
    | PressedChannelHeaderTab Evergreen.V426.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V426.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V426.Audio.LoadError Evergreen.V426.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V426.Route.Route
    | PressedMuteChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteDiscordDm (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteSlackDm (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) Evergreen.V426.MuteSettings.IsMuted
    | PressedMuteSlackDmThread (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V426.Id.AnyGuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V426.Id.AnyGuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) Evergreen.V426.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V426.Encryption.FromJs (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V426.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V426.UserSession.UserSession
    , currentlyViewing : Evergreen.V426.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) Evergreen.V426.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    , user : Evergreen.V426.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.User.FrontendUser
    , discordUsers : Evergreen.V426.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V426.SessionIdHash.SessionIdHash Evergreen.V426.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V426.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId) Evergreen.V426.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId) Evergreen.V426.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V426.Call.CallId (Evergreen.V426.NonemptyDict.NonemptyDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V426.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V426.Call.CallId Evergreen.V426.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V426.Go.PublicGoMatchData Evergreen.V426.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V426.Route.Route
    , windowSize : Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V426.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V426.Audio.LoadError Evergreen.V426.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Encryption.EncryptedData (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.NonemptyDict.NonemptyDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Encryption.EncryptedData (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V426.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V426.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V426.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment) (List Evergreen.V426.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V426.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V426.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.ChannelName.ChannelName Evergreen.V426.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.ChannelName.ChannelName Evergreen.V426.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V426.GuildName.GuildName (Evergreen.V426.UserSession.ToBeFilledInByBackend (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V426.Id.Viewing_DiscordDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V426.SetViewing.SetViewing
    | Local_SetName Evergreen.V426.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.VisibleMessages.PageRequest Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend Evergreen.V426.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.VisibleMessages.PageRequest Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V426.Id.SlackGuildOrDmId (Evergreen.V426.VisibleMessages.PageRequest Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V426.Id.SlackGuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.VisibleMessages.PageRequest Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V426.Id.DiscordGuildOrDmId (Evergreen.V426.VisibleMessages.PageRequest Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V426.Id.DiscordGuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.VisibleMessages.PageRequest Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V426.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V426.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V426.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.QuestionId Evergreen.V426.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V426.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V426.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V426.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V426.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V426.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V426.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V426.UserColor.UserColor
    | Local_AddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId))
    | Local_VoiceChatChange Evergreen.V426.Call.LocalChange
    | Local_Game Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Game.LocalChange
    | Local_Drawing Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Drawing.AnchorType Evergreen.V426.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteDiscordDm (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteSlackDm (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Local_SetMuteSlackDmThread (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V426.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V426.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V426.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V426.X25519.PublicKey (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V426.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V426.Id.Viewing_DmId (List ( Evergreen.V426.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V426.FileStatus.FileHash, Evergreen.V426.Encryption.EncryptedData (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V426.Id.Viewing_DmId (Evergreen.V426.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V426.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V426.Id.ThreadRouteWithMessage, Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V426.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V426.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V426.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V426.FileStatus.FileHash) (Evergreen.V426.Encryption.EncryptedData (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))) (Evergreen.V426.Encryption.EncryptedData String) Evergreen.V426.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V426.Id.Viewing_DmId Evergreen.V426.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V426.FileStatus.FileHash) (Evergreen.V426.Encryption.EncryptedData (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    | RepliedToGame Evergreen.V426.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
        , sender : Evergreen.V426.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V426.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
        , threadRoute : Evergreen.V426.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment
        , stickers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId) Evergreen.V426.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment) (Maybe (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) Evergreen.V426.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V426.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
        (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) Evergreen.V426.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId) Evergreen.V426.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId) Evergreen.V426.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId) Evergreen.V426.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V426.Id.DiscordGuildOrDmId Evergreen.V426.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))) Evergreen.V426.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId) Evergreen.V426.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.ChannelName.ChannelName Evergreen.V426.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.ChannelName.ChannelName Evergreen.V426.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.User.FrontendUser
    | Server_MemberLeft (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V426.LocalState.JoinGuildError
            { guildId : Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId
            , guild : Evergreen.V426.LocalState.FrontendGuild
            , owner : Evergreen.V426.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V426.NonemptySet.NonemptySet (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.CallRecordingFile (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))) Evergreen.V426.Message.ChangeAttachments
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V426.Id.Viewing_DiscordDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))) Evergreen.V426.Message.ChangeAttachments
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Maybe Evergreen.V426.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Maybe Evergreen.V426.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V426.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V426.SessionIdHash.SessionIdHash Evergreen.V426.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V426.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V426.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V426.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V426.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V426.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Bool Evergreen.V426.ChannelName.ChannelName (Evergreen.V426.Discord.OptionalData (Maybe String)) (List Evergreen.V426.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
        (Evergreen.V426.NonemptyDict.NonemptyDict
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Maybe (Evergreen.V426.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V426.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V426.Log.Log
    | Server_BackupGenerated Evergreen.V426.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V426.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V426.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V426.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V426.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (Evergreen.V426.Discord.OptionalData (Maybe String)) (Evergreen.V426.Discord.OptionalData (Maybe String)) (List Evergreen.V426.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.GuildName.GuildName (Maybe Evergreen.V426.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId) Evergreen.V426.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId) Evergreen.V426.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
        (Evergreen.V426.MembersAndOwner.MembersAndOwner
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.PersonName.PersonName Evergreen.V426.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId) Evergreen.V426.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId) Evergreen.V426.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V426.Call.ServerChange
    | Server_Game (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Game.LocalChange
    | Server_Drawing (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Drawing.AnchorType Evergreen.V426.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteDiscordDm (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteSlackDm (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) Evergreen.V426.MuteSettings.IsMuted
    | Server_SetMuteSlackDmThread (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V426.Id.Viewing_DmId ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V426.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V426.Id.Viewing_DmId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | Server_E2eeAccepted Evergreen.V426.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
        , sender : Evergreen.V426.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V426.Id.Viewing_DmId
        , content : Evergreen.V426.Encryption.EncryptedData (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
        , threadRoute : Evergreen.V426.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V426.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.Viewing_DmId Evergreen.V426.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V426.FileStatus.FileHash) (Evergreen.V426.Encryption.EncryptedData (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V426.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V426.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V426.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V426.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V426.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V426.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V426.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V426.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V426.Id.AnyGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V426.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels) (Maybe Evergreen.V426.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V426.SheepGame.Input (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels) (Maybe Evergreen.V426.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V426.Id.GuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V426.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V426.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V426.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V426.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , threadRoute : Evergreen.V426.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V426.Encryption.BytesHash
    , id : Evergreen.V426.Id.Viewing_DmId
    , senderId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , threadRoute : Evergreen.V426.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V426.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V426.Id.Viewing_DmId
    , messages : List Evergreen.V426.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V426.Id.Viewing_DmId
    , messages : List ( Evergreen.V426.Id.ThreadRouteWithMessage, Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V426.Id.Viewing_DmId
    , threadRoute : Evergreen.V426.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute )
    , fileId : Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V426.Id.Id Evergreen.V426.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V426.Id.Id Evergreen.V426.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V426.Id.Id Evergreen.V426.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V426.Id.Id Evergreen.V426.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V426.Id.Id Evergreen.V426.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V426.Local.Local LocalMsg Evergreen.V426.LocalState.LocalState
    , admin : Evergreen.V426.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V426.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V426.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.Message.RepliedTo Evergreen.V426.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V426.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V426.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V426.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.ThreadRoute ) (Evergreen.V426.NonemptyDict.NonemptyDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V426.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V426.Scroll.ScrollPosition
    , textEditor : Evergreen.V426.TextEditor.Model
    , profilePictureEditor : Evergreen.V426.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId, Evergreen.V426.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V426.Emoji.Model
    , voiceChat : Evergreen.V426.Call.Model
    , games : SeqDict.SeqDict Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V426.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V426.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V426.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V426.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V426.Range.Range
                , direction : Evergreen.V426.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V426.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V426.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V426.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V426.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V426.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | PeerToPeerDownloadResponse (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.FileStatus.PeerToPeerId (Maybe String)
    | PeerToPeerSendFileRequest Evergreen.V426.FileStatus.PeerToPeerId String
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V426.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V426.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V426.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V426.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V426.MyUi.LastCopy
    , drag : Evergreen.V426.Touch.Drag
    , dragPrevious : Evergreen.V426.Touch.Drag
    , aiChatModel : Evergreen.V426.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V426.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V426.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V426.Audio.LoadError Evergreen.V426.Audio.Source
    , startupData : Evergreen.V426.Ports.StartupData
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
    Evergreen.V426.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V426.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V426.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V426.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    , messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.Slack.Id Evergreen.V426.Slack.MessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V426.Slack.User
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V426.Slack.User
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , linkedTo : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V426.Slack.SlackToken
    , cookie : Evergreen.V426.Slack.SlackCookie
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
    { fileHash : Evergreen.V426.FileStatus.FileHash
    , metadata : Maybe Evergreen.V426.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId
    , members : Evergreen.V426.NonemptySet.NonemptySet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    , messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.Slack.Id Evergreen.V426.Slack.MessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V426.FileStatus.FileHash
    , metadata : Maybe Evergreen.V426.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId, Evergreen.V426.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId, Evergreen.V426.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V426.DmChannelId.DmChannelId, Evergreen.V426.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId, Evergreen.V426.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId, Evergreen.V426.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId, Evergreen.V426.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V426.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V426.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V426.LocalState.BackupContents
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
    { users : Evergreen.V426.NonemptyDict.NonemptyDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V426.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V426.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V426.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V426.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V426.DmChannelId.DmChannelId Evergreen.V426.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V426.FileStatus.FileHash Evergreen.V426.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V426.FileStatus.FileHash
    , privateVapidKey : Evergreen.V426.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    , textEditor : Evergreen.V426.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId, Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V426.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V426.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V426.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V426.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.LocalState.LoadingDiscordChannel Evergreen.V426.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Array.Array Effect.Time.Posix)
    , peerToPeerRateLimits : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V426.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V426.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V426.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId) Evergreen.V426.Sticker.StickerData
    , discordStickers : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.Discord.Id Evergreen.V426.Discord.StickerId) (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId) Evergreen.V426.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V426.OneToOne.OneToOne Evergreen.V426.RichText.DiscordCustomEmojiIdAndName (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V426.Postmark.ApiKey
    , serverSecret : Evergreen.V426.SecretId.SecretId Evergreen.V426.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V426.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.GamePublicId) ( Evergreen.V426.DmChannelId.GuildOrFullDmId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V426.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V426.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V426.Call.SharedCallId Evergreen.V426.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V426.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.Id.ThreadRoute (Maybe Evergreen.V426.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V426.DmChannelId.DmChannelId Evergreen.V426.Id.ThreadRoute (Maybe Evergreen.V426.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V426.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V426.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V426.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V426.UserAgent.UserAgent
    | AdminToBackend Evergreen.V426.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V426.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V426.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V426.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V426.PersonName.PersonName Evergreen.V426.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V426.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V426.Discord.UserAuth
    | LinkSlackRequest Evergreen.V426.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V426.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V426.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
        { fileName : String
        , json : String
        }
    | SharePeerToPeerFileRequest Evergreen.V426.FileStatus.PeerToPeerId Evergreen.V426.PeerToPeer.SharedFile
    | PeerToPeerDownloadRequest Evergreen.V426.Id.GuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.FileStatus.PeerToPeerId


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V426.Slack.Channel, Evergreen.V426.Slack.History )
    , dmChannels : List ( Evergreen.V426.Slack.DmChannel, Evergreen.V426.Slack.History )
    , users : List ( Evergreen.V426.Slack.User, Maybe Evergreen.V426.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V426.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V426.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V426.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V426.EmailAddress.EmailAddress (Result Evergreen.V426.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V426.EmailAddress.EmailAddress (Result Evergreen.V426.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V426.EmailAddress.EmailAddress (Result Evergreen.V426.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V426.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMaybeMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Result Evergreen.V426.Discord.HttpError Evergreen.V426.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V426.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Result Evergreen.V426.Discord.HttpError Evergreen.V426.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V426.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.Attachment) (Result Evergreen.V426.Slack.HttpError ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.MessageId, List ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.FileId, Evergreen.V426.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) (Result Evergreen.V426.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) (Result Evergreen.V426.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) (Result Evergreen.V426.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) (Result Evergreen.V426.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji (Result Evergreen.V426.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji (Result Evergreen.V426.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji (Result Evergreen.V426.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji (Result Evergreen.V426.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V426.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V426.Discord.HttpError (List ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId, Maybe Evergreen.V426.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Effect.Time.Posix Evergreen.V426.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Result Evergreen.V426.Slack.HttpError ( Evergreen.V426.Slack.User, Maybe Evergreen.V426.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V426.Slack.User (Maybe Evergreen.V426.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V426.Id.SlackGuildOrDmId (Result Evergreen.V426.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V426.Id.SlackGuildOrDmId (Result Evergreen.V426.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V426.Id.SlackGuildOrDmId (Result Evergreen.V426.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V426.Slack.SlackToken, Result Evergreen.V426.Slack.HttpError Evergreen.V426.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Result Evergreen.V426.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (List Evergreen.V426.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Result Evergreen.V426.Slack.HttpError Evergreen.V426.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V426.Slack.HttpError ) ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Discord.UserAuth (Result Evergreen.V426.Discord.HttpError Evergreen.V426.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Result Evergreen.V426.Discord.HttpError Evergreen.V426.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
        (Result
            Evergreen.V426.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId
                    , members : List (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
                    , messages : List Evergreen.V426.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId
                    , { guild : Evergreen.V426.Discord.GatewayGuild
                      , channels : List Evergreen.V426.Discord.Channel
                      , icon : Maybe Evergreen.V426.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.LocalState.DiscordChannelReload
            , attachments : List (Result Effect.Http.Error ( Evergreen.V426.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V426.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V426.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V426.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.AttachmentId, Evergreen.V426.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V426.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.AttachmentId, Evergreen.V426.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V426.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V426.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V426.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V426.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (Result Evergreen.V426.Discord.HttpError Evergreen.V426.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Result Evergreen.V426.Discord.HttpError (List Evergreen.V426.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V426.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V426.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V426.DmChannelId.DmChannelId Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V426.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V426.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V426.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V426.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
        (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V426.Discord.HttpError
            { guild : Evergreen.V426.Discord.GatewayGuild
            , channels : List Evergreen.V426.Discord.Channel
            , icon : Maybe Evergreen.V426.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Maybe Evergreen.V426.FileStatus.UploadResponse)
    | ToBackendCompleted
        Evergreen.V426.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V426.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (List ( Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId, Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordCatchUpMessages (List Evergreen.V426.Discord.Message) (List (Result Effect.Http.Error ( Evergreen.V426.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V426.FileStatus.UploadResponse )))
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId, Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (List ( Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (List ( Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V426.Discord.HttpError (List Evergreen.V426.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V426.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V426.SecretId.SecretId Evergreen.V426.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V426.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V426.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V426.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V426.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Result Evergreen.V426.Discord.HttpError ( Evergreen.V426.Discord.Guild, List Evergreen.V426.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V426.FileStatus.FileHash Int (Maybe (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V426.Call.SharedCallId Effect.Time.Posix (Evergreen.V426.Message.CallRecordingFile (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V426.Call.SharedCallId Effect.Time.Posix (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V426.Call.SharedCallId Effect.Time.Posix Evergreen.V426.Message.CallRecordingZip
