module Evergreen.V423.Types exposing (..)

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
import Evergreen.V423.AiChat
import Evergreen.V423.Audio
import Evergreen.V423.BackendMsgLog
import Evergreen.V423.Call
import Evergreen.V423.ChannelDescription
import Evergreen.V423.ChannelName
import Evergreen.V423.Coord
import Evergreen.V423.CssPixels
import Evergreen.V423.CustomEmoji
import Evergreen.V423.Discord
import Evergreen.V423.DiscordAttachmentId
import Evergreen.V423.DiscordUserData
import Evergreen.V423.DmChannel
import Evergreen.V423.DmChannelId
import Evergreen.V423.Drawing
import Evergreen.V423.Editable
import Evergreen.V423.EmailAddress
import Evergreen.V423.Embed
import Evergreen.V423.Emoji
import Evergreen.V423.Encryption
import Evergreen.V423.FileStatus
import Evergreen.V423.Game
import Evergreen.V423.Go
import Evergreen.V423.GuildName
import Evergreen.V423.Id
import Evergreen.V423.IdArray
import Evergreen.V423.ImageEditor
import Evergreen.V423.ImageViewer
import Evergreen.V423.LinkedAndOtherDiscordUsers
import Evergreen.V423.Local
import Evergreen.V423.LocalState
import Evergreen.V423.Log
import Evergreen.V423.LoginForm
import Evergreen.V423.MembersAndOwner
import Evergreen.V423.Message
import Evergreen.V423.MessageInput
import Evergreen.V423.MessageView
import Evergreen.V423.MuteSettings
import Evergreen.V423.MyUi
import Evergreen.V423.NonemptyDict
import Evergreen.V423.NonemptySet
import Evergreen.V423.OneOrGreater
import Evergreen.V423.OneToOne
import Evergreen.V423.Pages.Admin
import Evergreen.V423.Pagination
import Evergreen.V423.PeerToPeer
import Evergreen.V423.PersonName
import Evergreen.V423.Ports
import Evergreen.V423.Postmark
import Evergreen.V423.Range
import Evergreen.V423.RateLimit
import Evergreen.V423.RecoveryLogin
import Evergreen.V423.RichText
import Evergreen.V423.Route
import Evergreen.V423.Scroll
import Evergreen.V423.SecretId
import Evergreen.V423.SessionIdHash
import Evergreen.V423.SetViewing
import Evergreen.V423.SheepGame
import Evergreen.V423.Slack
import Evergreen.V423.Sticker
import Evergreen.V423.TextEditor
import Evergreen.V423.Thread
import Evergreen.V423.ToBackendLog
import Evergreen.V423.Touch
import Evergreen.V423.TwoFactorAuthentication
import Evergreen.V423.Ui.Anim
import Evergreen.V423.User
import Evergreen.V423.UserAgent
import Evergreen.V423.UserColor
import Evergreen.V423.UserSession
import Evergreen.V423.VisibleMessages
import Evergreen.V423.WordSpellingGame
import Evergreen.V423.X25519
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
    | LoginFormMsg Evergreen.V423.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V423.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V423.Pages.Admin.Msg
    | PressedLogOut Evergreen.V423.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V423.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V423.Route.Route
    | SelectedFilesToAttach ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | SelectedPeerToPeerFileToShareAgain Evergreen.V423.Id.GuildOrDmId Evergreen.V423.FileStatus.PeerToPeerFile Effect.File.File
    | SentPeerToPeerFile Evergreen.V423.FileStatus.PeerToPeerId (Result Effect.Http.Error ())
    | NewChannelFormChanged (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | PressedImportChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V423.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V423.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V423.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V423.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V423.NonemptyDict.NonemptyDict Int Evergreen.V423.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V423.NonemptyDict.NonemptyDict Int Evergreen.V423.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRoute Evergreen.V423.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId))
    | MessageMenu_PressedOpenDm (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V423.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V423.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V423.AiChat.Msg
    | GameMsg Evergreen.V423.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V423.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V423.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V423.Editable.Msg Evergreen.V423.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V423.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) (Maybe Evergreen.V423.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute )
        { fileId : Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute )
        { fileId : Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V423.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V423.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V423.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V423.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V423.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V423.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V423.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | PressedDisableE2ee (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | TypedPrivateKey (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) String
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
    | TextEditorMsg Evergreen.V423.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId
        , otherUserId : Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V423.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRoute Evergreen.V423.MessageInput.Msg
    | MessageInputMsg Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRoute Evergreen.V423.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V423.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V423.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V423.Range.Range, Evergreen.V423.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V423.Range.Range, Evergreen.V423.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V423.Call.FromJs)
    | VoiceChatMsg Evergreen.V423.Call.Msg
    | PressedChannelHeaderTab Evergreen.V423.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V423.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V423.Audio.LoadError Evergreen.V423.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V423.Route.Route
    | PressedMuteChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteDiscordDm (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteSlackDm (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) Evergreen.V423.MuteSettings.IsMuted
    | PressedMuteSlackDmThread (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V423.Id.AnyGuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V423.Id.AnyGuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) Evergreen.V423.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V423.Encryption.FromJs (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V423.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V423.UserSession.UserSession
    , currentlyViewing : Evergreen.V423.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) Evergreen.V423.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    , user : Evergreen.V423.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.User.FrontendUser
    , discordUsers : Evergreen.V423.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V423.SessionIdHash.SessionIdHash Evergreen.V423.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V423.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId) Evergreen.V423.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId) Evergreen.V423.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V423.Call.CallId (Evergreen.V423.NonemptyDict.NonemptyDict ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V423.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V423.Call.CallId Evergreen.V423.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V423.Go.PublicGoMatchData Evergreen.V423.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V423.Route.Route
    , windowSize : Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V423.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V423.Audio.LoadError Evergreen.V423.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Encryption.EncryptedData (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.NonemptyDict.NonemptyDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Encryption.EncryptedData (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V423.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V423.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V423.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment) (List Evergreen.V423.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V423.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V423.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.ChannelName.ChannelName Evergreen.V423.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.ChannelName.ChannelName Evergreen.V423.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V423.GuildName.GuildName (Evergreen.V423.UserSession.ToBeFilledInByBackend (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V423.Id.Viewing_DiscordDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V423.SetViewing.SetViewing
    | Local_SetName Evergreen.V423.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.VisibleMessages.PageRequest Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend Evergreen.V423.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.VisibleMessages.PageRequest Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V423.Id.SlackGuildOrDmId (Evergreen.V423.VisibleMessages.PageRequest Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V423.Id.SlackGuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.VisibleMessages.PageRequest Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V423.Id.DiscordGuildOrDmId (Evergreen.V423.VisibleMessages.PageRequest Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V423.Id.DiscordGuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.VisibleMessages.PageRequest Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V423.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V423.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V423.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.QuestionId Evergreen.V423.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V423.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V423.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V423.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V423.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V423.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V423.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V423.UserColor.UserColor
    | Local_AddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId))
    | Local_VoiceChatChange Evergreen.V423.Call.LocalChange
    | Local_Game Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Game.LocalChange
    | Local_Drawing Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Drawing.AnchorType Evergreen.V423.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteDiscordDm (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteSlackDm (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Local_SetMuteSlackDmThread (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V423.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V423.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V423.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V423.X25519.PublicKey (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V423.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V423.Id.Viewing_DmId (List ( Evergreen.V423.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V423.FileStatus.FileHash, Evergreen.V423.Encryption.EncryptedData (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V423.Id.Viewing_DmId (Evergreen.V423.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V423.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V423.Id.ThreadRouteWithMessage, Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V423.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V423.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V423.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V423.FileStatus.FileHash) (Evergreen.V423.Encryption.EncryptedData (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))) (Evergreen.V423.Encryption.EncryptedData String) Evergreen.V423.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V423.Id.Viewing_DmId Evergreen.V423.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V423.FileStatus.FileHash) (Evergreen.V423.Encryption.EncryptedData (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
    | RepliedToGame Evergreen.V423.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
        , sender : Evergreen.V423.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V423.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
        , threadRoute : Evergreen.V423.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment
        , stickers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId) Evergreen.V423.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment) (Maybe (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) Evergreen.V423.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V423.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
        (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) Evergreen.V423.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId) Evergreen.V423.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId) Evergreen.V423.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId) Evergreen.V423.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V423.Id.DiscordGuildOrDmId Evergreen.V423.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId))) Evergreen.V423.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment) (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId) Evergreen.V423.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.ChannelName.ChannelName Evergreen.V423.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.ChannelName.ChannelName Evergreen.V423.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.User.FrontendUser
    | Server_MemberLeft (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V423.LocalState.JoinGuildError
            { guildId : Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId
            , guild : Evergreen.V423.LocalState.FrontendGuild
            , owner : Evergreen.V423.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V423.NonemptySet.NonemptySet (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.CallRecordingFile (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V423.Id.Viewing_DiscordDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Maybe Evergreen.V423.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Maybe Evergreen.V423.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V423.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V423.SessionIdHash.SessionIdHash Evergreen.V423.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V423.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V423.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V423.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V423.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V423.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Bool Evergreen.V423.ChannelName.ChannelName (Evergreen.V423.Discord.OptionalData (Maybe String)) (List Evergreen.V423.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
        (Evergreen.V423.NonemptyDict.NonemptyDict
            (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Maybe (Evergreen.V423.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V423.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V423.Log.Log
    | Server_BackupGenerated Evergreen.V423.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V423.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V423.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V423.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V423.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (Evergreen.V423.Discord.OptionalData (Maybe String)) (Evergreen.V423.Discord.OptionalData (Maybe String)) (List Evergreen.V423.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.GuildName.GuildName (Maybe Evergreen.V423.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.RoleId) Evergreen.V423.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.RoleId) Evergreen.V423.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
        (Evergreen.V423.MembersAndOwner.MembersAndOwner
            (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V423.Discord.Id Evergreen.V423.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.PersonName.PersonName Evergreen.V423.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId) Evergreen.V423.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId) Evergreen.V423.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V423.Call.ServerChange
    | Server_Game (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Game.LocalChange
    | Server_Drawing (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Drawing.AnchorType Evergreen.V423.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteDiscordDm (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteSlackDm (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) Evergreen.V423.MuteSettings.IsMuted
    | Server_SetMuteSlackDmThread (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V423.Id.Viewing_DmId ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V423.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V423.Id.Viewing_DmId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | Server_E2eeAccepted Evergreen.V423.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
        , sender : Evergreen.V423.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V423.Id.Viewing_DmId
        , content : Evergreen.V423.Encryption.EncryptedData (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
        , threadRoute : Evergreen.V423.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V423.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.Viewing_DmId Evergreen.V423.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V423.FileStatus.FileHash) (Evergreen.V423.Encryption.EncryptedData (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V423.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V423.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V423.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V423.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V423.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V423.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V423.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V423.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V423.Id.AnyGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V423.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels) (Maybe Evergreen.V423.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V423.SheepGame.Input (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels) (Maybe Evergreen.V423.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V423.Id.GuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId) (Evergreen.V423.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V423.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V423.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V423.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V423.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    , threadRoute : Evergreen.V423.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V423.Encryption.BytesHash
    , id : Evergreen.V423.Id.Viewing_DmId
    , senderId : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    , threadRoute : Evergreen.V423.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V423.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V423.Id.Viewing_DmId
    , messages : List Evergreen.V423.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V423.Id.Viewing_DmId
    , messages : List ( Evergreen.V423.Id.ThreadRouteWithMessage, Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V423.Id.Viewing_DmId
    , threadRoute : Evergreen.V423.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute )
    , fileId : Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V423.Id.Id Evergreen.V423.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V423.Id.Id Evergreen.V423.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V423.Id.Id Evergreen.V423.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V423.Id.Id Evergreen.V423.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V423.Id.Id Evergreen.V423.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V423.Local.Local LocalMsg Evergreen.V423.LocalState.LocalState
    , admin : Evergreen.V423.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId, Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V423.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V423.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.Message.RepliedTo Evergreen.V423.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V423.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V423.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V423.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.ThreadRoute ) (Evergreen.V423.NonemptyDict.NonemptyDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V423.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V423.Scroll.ScrollPosition
    , textEditor : Evergreen.V423.TextEditor.Model
    , profilePictureEditor : Evergreen.V423.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId, Evergreen.V423.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V423.Emoji.Model
    , voiceChat : Evergreen.V423.Call.Model
    , games : SeqDict.SeqDict Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V423.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V423.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V423.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V423.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V423.Range.Range
                , direction : Evergreen.V423.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V423.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V423.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V423.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V423.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V423.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | PeerToPeerDownloadResponse (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.FileStatus.PeerToPeerId (Maybe String)
    | PeerToPeerSendFileRequest Evergreen.V423.FileStatus.PeerToPeerId String
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V423.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V423.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V423.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V423.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V423.MyUi.LastCopy
    , drag : Evergreen.V423.Touch.Drag
    , dragPrevious : Evergreen.V423.Touch.Drag
    , aiChatModel : Evergreen.V423.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V423.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V423.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V423.Audio.LoadError Evergreen.V423.Audio.Source
    , startupData : Evergreen.V423.Ports.StartupData
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
    Evergreen.V423.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V423.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V423.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V423.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    , messages : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V423.OneToOne.OneToOne (Evergreen.V423.Slack.Id Evergreen.V423.Slack.MessageId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V423.Slack.User
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V423.Slack.User
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , linkedTo : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V423.Slack.SlackToken
    , cookie : Evergreen.V423.Slack.SlackCookie
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
    { fileHash : Evergreen.V423.FileStatus.FileHash
    , metadata : Maybe Evergreen.V423.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId
    , members : Evergreen.V423.NonemptySet.NonemptySet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    , messages : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V423.OneToOne.OneToOne (Evergreen.V423.Slack.Id Evergreen.V423.Slack.MessageId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V423.FileStatus.FileHash
    , metadata : Maybe Evergreen.V423.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId, Evergreen.V423.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId, Evergreen.V423.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V423.DmChannelId.DmChannelId, Evergreen.V423.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId, Evergreen.V423.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId, Evergreen.V423.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId, Evergreen.V423.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V423.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V423.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V423.LocalState.BackupContents
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
    { users : Evergreen.V423.NonemptyDict.NonemptyDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V423.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V423.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V423.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V423.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V423.DmChannelId.DmChannelId Evergreen.V423.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V423.FileStatus.FileHash Evergreen.V423.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V423.FileStatus.FileHash
    , privateVapidKey : Evergreen.V423.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    , textEditor : Evergreen.V423.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId, Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V423.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V423.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V423.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V423.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.LocalState.LoadingDiscordChannel Evergreen.V423.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Array.Array Effect.Time.Posix)
    , peerToPeerRateLimits : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V423.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V423.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V423.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId) Evergreen.V423.Sticker.StickerData
    , discordStickers : Evergreen.V423.OneToOne.OneToOne (Evergreen.V423.Discord.Id Evergreen.V423.Discord.StickerId) (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId) Evergreen.V423.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V423.OneToOne.OneToOne Evergreen.V423.RichText.DiscordCustomEmojiIdAndName (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V423.Postmark.ApiKey
    , serverSecret : Evergreen.V423.SecretId.SecretId Evergreen.V423.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V423.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V423.OneToOne.OneToOne (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.GamePublicId) ( Evergreen.V423.DmChannelId.GuildOrFullDmId, Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V423.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V423.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V423.Call.SharedCallId Evergreen.V423.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V423.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.Id.ThreadRoute (Maybe Evergreen.V423.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V423.DmChannelId.DmChannelId Evergreen.V423.Id.ThreadRoute (Maybe Evergreen.V423.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V423.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V423.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V423.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V423.UserAgent.UserAgent
    | AdminToBackend Evergreen.V423.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V423.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V423.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V423.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V423.PersonName.PersonName Evergreen.V423.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V423.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V423.Discord.UserAuth
    | LinkSlackRequest Evergreen.V423.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V423.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V423.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
        { fileName : String
        , json : String
        }
    | SharePeerToPeerFileRequest Evergreen.V423.FileStatus.PeerToPeerId Evergreen.V423.PeerToPeer.SharedFile
    | PeerToPeerDownloadRequest Evergreen.V423.Id.GuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.FileStatus.PeerToPeerId


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V423.Slack.Channel, Evergreen.V423.Slack.History )
    , dmChannels : List ( Evergreen.V423.Slack.DmChannel, Evergreen.V423.Slack.History )
    , users : List ( Evergreen.V423.Slack.User, Maybe Evergreen.V423.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V423.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V423.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V423.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V423.EmailAddress.EmailAddress (Result Evergreen.V423.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V423.EmailAddress.EmailAddress (Result Evergreen.V423.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V423.EmailAddress.EmailAddress (Result Evergreen.V423.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V423.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMaybeMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Result Evergreen.V423.Discord.HttpError Evergreen.V423.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V423.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Result Evergreen.V423.Discord.HttpError Evergreen.V423.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V423.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.Attachment) (Result Evergreen.V423.Slack.HttpError ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.MessageId, List ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.FileId, Evergreen.V423.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) (Result Evergreen.V423.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) (Result Evergreen.V423.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) (Result Evergreen.V423.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) (Result Evergreen.V423.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji (Result Evergreen.V423.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji (Result Evergreen.V423.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji (Result Evergreen.V423.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji (Result Evergreen.V423.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V423.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V423.Discord.HttpError (List ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId, Maybe Evergreen.V423.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Effect.Time.Posix Evergreen.V423.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Result Evergreen.V423.Slack.HttpError ( Evergreen.V423.Slack.User, Maybe Evergreen.V423.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V423.Slack.User (Maybe Evergreen.V423.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V423.Id.SlackGuildOrDmId (Result Evergreen.V423.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V423.Id.SlackGuildOrDmId (Result Evergreen.V423.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V423.Id.SlackGuildOrDmId (Result Evergreen.V423.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V423.Slack.SlackToken, Result Evergreen.V423.Slack.HttpError Evergreen.V423.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Result Evergreen.V423.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (List Evergreen.V423.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Result Evergreen.V423.Slack.HttpError Evergreen.V423.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V423.Slack.HttpError ) ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Discord.UserAuth (Result Evergreen.V423.Discord.HttpError Evergreen.V423.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Result Evergreen.V423.Discord.HttpError Evergreen.V423.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
        (Result
            Evergreen.V423.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId
                    , members : List (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
                    , messages : List Evergreen.V423.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId
                    , { guild : Evergreen.V423.Discord.GatewayGuild
                      , channels : List Evergreen.V423.Discord.Channel
                      , icon : Maybe Evergreen.V423.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.LocalState.DiscordChannelReload
            , attachments : List (Result Effect.Http.Error ( Evergreen.V423.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V423.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V423.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V423.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.AttachmentId, Evergreen.V423.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V423.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.AttachmentId, Evergreen.V423.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V423.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V423.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V423.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V423.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) (Result Evergreen.V423.Discord.HttpError Evergreen.V423.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Result Evergreen.V423.Discord.HttpError (List Evergreen.V423.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V423.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V423.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V423.DmChannelId.DmChannelId Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V423.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V423.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V423.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V423.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
        (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V423.Discord.HttpError
            { guild : Evergreen.V423.Discord.GatewayGuild
            , channels : List Evergreen.V423.Discord.Channel
            , icon : Maybe Evergreen.V423.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Maybe Evergreen.V423.FileStatus.UploadResponse)
    | ToBackendCompleted
        Evergreen.V423.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V423.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (List ( Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId, Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordCatchUpMessages (List Evergreen.V423.Discord.Message) (List (Result Effect.Http.Error ( Evergreen.V423.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V423.FileStatus.UploadResponse )))
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId, Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (List ( Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (List ( Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V423.Discord.HttpError (List Evergreen.V423.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V423.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V423.SecretId.SecretId Evergreen.V423.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V423.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V423.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V423.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V423.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Result Evergreen.V423.Discord.HttpError ( Evergreen.V423.Discord.Guild, List Evergreen.V423.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V423.FileStatus.FileHash Int (Maybe (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V423.Call.SharedCallId Effect.Time.Posix (Evergreen.V423.Message.CallRecordingFile (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V423.Call.SharedCallId Effect.Time.Posix (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V423.Call.SharedCallId Effect.Time.Posix Evergreen.V423.Message.CallRecordingZip
