module Evergreen.V421.Types exposing (..)

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
import Evergreen.V421.AiChat
import Evergreen.V421.Audio
import Evergreen.V421.BackendMsgLog
import Evergreen.V421.Call
import Evergreen.V421.ChannelDescription
import Evergreen.V421.ChannelName
import Evergreen.V421.Coord
import Evergreen.V421.CssPixels
import Evergreen.V421.CustomEmoji
import Evergreen.V421.Discord
import Evergreen.V421.DiscordAttachmentId
import Evergreen.V421.DiscordUserData
import Evergreen.V421.DmChannel
import Evergreen.V421.DmChannelId
import Evergreen.V421.Drawing
import Evergreen.V421.Editable
import Evergreen.V421.EmailAddress
import Evergreen.V421.Embed
import Evergreen.V421.Emoji
import Evergreen.V421.Encryption
import Evergreen.V421.FileStatus
import Evergreen.V421.Game
import Evergreen.V421.Go
import Evergreen.V421.GuildName
import Evergreen.V421.Id
import Evergreen.V421.IdArray
import Evergreen.V421.ImageEditor
import Evergreen.V421.ImageViewer
import Evergreen.V421.LinkedAndOtherDiscordUsers
import Evergreen.V421.Local
import Evergreen.V421.LocalState
import Evergreen.V421.Log
import Evergreen.V421.LoginForm
import Evergreen.V421.MembersAndOwner
import Evergreen.V421.Message
import Evergreen.V421.MessageInput
import Evergreen.V421.MessageView
import Evergreen.V421.MuteSettings
import Evergreen.V421.MyUi
import Evergreen.V421.NonemptyDict
import Evergreen.V421.NonemptySet
import Evergreen.V421.OneOrGreater
import Evergreen.V421.OneToOne
import Evergreen.V421.Pages.Admin
import Evergreen.V421.Pagination
import Evergreen.V421.PeerToPeer
import Evergreen.V421.PersonName
import Evergreen.V421.Ports
import Evergreen.V421.Postmark
import Evergreen.V421.Range
import Evergreen.V421.RateLimit
import Evergreen.V421.RecoveryLogin
import Evergreen.V421.RichText
import Evergreen.V421.Route
import Evergreen.V421.Scroll
import Evergreen.V421.SecretId
import Evergreen.V421.SessionIdHash
import Evergreen.V421.SetViewing
import Evergreen.V421.SheepGame
import Evergreen.V421.Slack
import Evergreen.V421.Sticker
import Evergreen.V421.TextEditor
import Evergreen.V421.Thread
import Evergreen.V421.ToBackendLog
import Evergreen.V421.Touch
import Evergreen.V421.TwoFactorAuthentication
import Evergreen.V421.Ui.Anim
import Evergreen.V421.User
import Evergreen.V421.UserAgent
import Evergreen.V421.UserColor
import Evergreen.V421.UserSession
import Evergreen.V421.VisibleMessages
import Evergreen.V421.WordSpellingGame
import Evergreen.V421.X25519
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
    | LoginFormMsg Evergreen.V421.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V421.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V421.Pages.Admin.Msg
    | PressedLogOut Evergreen.V421.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V421.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V421.Route.Route
    | SelectedFilesToAttach ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | SelectedPeerToPeerFileToShareAgain Evergreen.V421.Id.GuildOrDmId Evergreen.V421.FileStatus.PeerToPeerFile Effect.File.File
    | SentPeerToPeerFile Evergreen.V421.FileStatus.PeerToPeerId (Result Effect.Http.Error ())
    | NewChannelFormChanged (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | PressedImportChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V421.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V421.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V421.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V421.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V421.NonemptyDict.NonemptyDict Int Evergreen.V421.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V421.NonemptyDict.NonemptyDict Int Evergreen.V421.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRoute Evergreen.V421.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId))
    | MessageMenu_PressedOpenDm (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V421.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V421.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V421.AiChat.Msg
    | GameMsg Evergreen.V421.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V421.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V421.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V421.Editable.Msg Evergreen.V421.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V421.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) (Maybe Evergreen.V421.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute )
        { fileId : Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute )
        { fileId : Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V421.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V421.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V421.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V421.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V421.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V421.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V421.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | PressedDisableE2ee (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | TypedPrivateKey (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) String
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
    | TextEditorMsg Evergreen.V421.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId
        , otherUserId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V421.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRoute Evergreen.V421.MessageInput.Msg
    | MessageInputMsg Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRoute Evergreen.V421.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V421.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V421.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V421.Range.Range, Evergreen.V421.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V421.Range.Range, Evergreen.V421.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V421.Call.FromJs)
    | VoiceChatMsg Evergreen.V421.Call.Msg
    | PressedChannelHeaderTab Evergreen.V421.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V421.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V421.Audio.LoadError Evergreen.V421.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V421.Route.Route
    | PressedMuteChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V421.Id.AnyGuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V421.Id.AnyGuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) Evergreen.V421.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V421.Encryption.FromJs (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V421.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V421.UserSession.UserSession
    , currentlyViewing : Evergreen.V421.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) Evergreen.V421.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId) Evergreen.V421.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    , user : Evergreen.V421.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.User.FrontendUser
    , discordUsers : Evergreen.V421.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V421.SessionIdHash.SessionIdHash Evergreen.V421.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V421.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId) Evergreen.V421.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId) Evergreen.V421.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V421.Call.CallId (Evergreen.V421.NonemptyDict.NonemptyDict ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V421.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V421.Call.CallId Evergreen.V421.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V421.Go.PublicGoMatchData Evergreen.V421.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V421.Route.Route
    , windowSize : Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V421.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V421.Audio.LoadError Evergreen.V421.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Encryption.EncryptedData (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.NonemptyDict.NonemptyDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Encryption.EncryptedData (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V421.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V421.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V421.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment) (List Evergreen.V421.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V421.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V421.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.ChannelName.ChannelName Evergreen.V421.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.ChannelName.ChannelName Evergreen.V421.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V421.GuildName.GuildName (Evergreen.V421.UserSession.ToBeFilledInByBackend (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V421.Id.Viewing_DiscordDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V421.SetViewing.SetViewing
    | Local_SetName Evergreen.V421.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.VisibleMessages.PageRequest Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend Evergreen.V421.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.VisibleMessages.PageRequest Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V421.Id.SlackGuildOrDmId (Evergreen.V421.VisibleMessages.PageRequest Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V421.Id.SlackGuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.VisibleMessages.PageRequest Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V421.Id.DiscordGuildOrDmId (Evergreen.V421.VisibleMessages.PageRequest Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V421.Id.DiscordGuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.VisibleMessages.PageRequest Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V421.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V421.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V421.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.QuestionId Evergreen.V421.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V421.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V421.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V421.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V421.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V421.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V421.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V421.UserColor.UserColor
    | Local_AddCustomEmojisAndStickersToUser (SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)) (SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId))
    | Local_VoiceChatChange Evergreen.V421.Call.LocalChange
    | Local_Game Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Game.LocalChange
    | Local_Drawing Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Drawing.AnchorType Evergreen.V421.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V421.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V421.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V421.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V421.X25519.PublicKey (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V421.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V421.Id.Viewing_DmId (List ( Evergreen.V421.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V421.FileStatus.FileHash, Evergreen.V421.Encryption.EncryptedData (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V421.Id.Viewing_DmId (Evergreen.V421.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V421.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V421.Id.ThreadRouteWithMessage, Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V421.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V421.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V421.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V421.FileStatus.FileHash) (Evergreen.V421.Encryption.EncryptedData (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))) (Evergreen.V421.Encryption.EncryptedData String) Evergreen.V421.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V421.Id.Viewing_DmId Evergreen.V421.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V421.FileStatus.FileHash) (Evergreen.V421.Encryption.EncryptedData (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    | RepliedToGame Evergreen.V421.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
        , sender : Evergreen.V421.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V421.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
        , threadRoute : Evergreen.V421.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment
        , stickers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId) Evergreen.V421.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment) (Maybe (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) Evergreen.V421.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V421.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
        (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId) Evergreen.V421.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId) Evergreen.V421.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId) Evergreen.V421.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId) Evergreen.V421.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V421.Id.DiscordGuildOrDmId Evergreen.V421.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))) Evergreen.V421.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment) (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId) Evergreen.V421.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.ChannelName.ChannelName Evergreen.V421.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.ChannelName.ChannelName Evergreen.V421.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.User.FrontendUser
    | Server_MemberLeft (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V421.LocalState.JoinGuildError
            { guildId : Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId
            , guild : Evergreen.V421.LocalState.FrontendGuild
            , owner : Evergreen.V421.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V421.NonemptySet.NonemptySet (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.CallRecordingFile (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V421.Id.Viewing_DiscordDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Maybe Evergreen.V421.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Maybe Evergreen.V421.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V421.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V421.SessionIdHash.SessionIdHash Evergreen.V421.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V421.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V421.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V421.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V421.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V421.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Bool Evergreen.V421.ChannelName.ChannelName (Evergreen.V421.Discord.OptionalData (Maybe String)) (List Evergreen.V421.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
        (Evergreen.V421.NonemptyDict.NonemptyDict
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) Evergreen.V421.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Maybe (Evergreen.V421.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V421.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V421.Log.Log
    | Server_BackupGenerated Evergreen.V421.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V421.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V421.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V421.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V421.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (Evergreen.V421.Discord.OptionalData (Maybe String)) (Evergreen.V421.Discord.OptionalData (Maybe String)) (List Evergreen.V421.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.GuildName.GuildName (Maybe Evergreen.V421.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId) Evergreen.V421.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId) Evergreen.V421.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
        (Evergreen.V421.MembersAndOwner.MembersAndOwner
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.PersonName.PersonName Evergreen.V421.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId) Evergreen.V421.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId) Evergreen.V421.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V421.Call.ServerChange
    | Server_Game (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Game.LocalChange
    | Server_Drawing (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Drawing.AnchorType Evergreen.V421.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) Evergreen.V421.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V421.Id.Viewing_DmId ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V421.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V421.Id.Viewing_DmId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | Server_E2eeAccepted Evergreen.V421.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
        , sender : Evergreen.V421.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V421.Id.Viewing_DmId
        , content : Evergreen.V421.Encryption.EncryptedData (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
        , threadRoute : Evergreen.V421.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V421.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.Viewing_DmId Evergreen.V421.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V421.FileStatus.FileHash) (Evergreen.V421.Encryption.EncryptedData (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V421.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V421.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V421.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V421.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V421.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V421.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V421.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V421.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V421.Id.AnyGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V421.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels) (Maybe Evergreen.V421.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V421.SheepGame.Input (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels) (Maybe Evergreen.V421.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V421.Id.GuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId) (Evergreen.V421.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V421.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V421.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V421.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V421.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , threadRoute : Evergreen.V421.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V421.Encryption.BytesHash
    , id : Evergreen.V421.Id.Viewing_DmId
    , senderId : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , threadRoute : Evergreen.V421.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V421.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V421.Id.Viewing_DmId
    , messages : List Evergreen.V421.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V421.Id.Viewing_DmId
    , messages : List ( Evergreen.V421.Id.ThreadRouteWithMessage, Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V421.Id.Viewing_DmId
    , threadRoute : Evergreen.V421.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute )
    , fileId : Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V421.Id.Id Evergreen.V421.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V421.Id.Id Evergreen.V421.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V421.Id.Id Evergreen.V421.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V421.Id.Id Evergreen.V421.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V421.Id.Id Evergreen.V421.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V421.Local.Local LocalMsg Evergreen.V421.LocalState.LocalState
    , admin : Evergreen.V421.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId, Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V421.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V421.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.Message.RepliedTo Evergreen.V421.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V421.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V421.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V421.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.ThreadRoute ) (Evergreen.V421.NonemptyDict.NonemptyDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V421.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V421.Scroll.ScrollPosition
    , textEditor : Evergreen.V421.TextEditor.Model
    , profilePictureEditor : Evergreen.V421.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId, Evergreen.V421.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V421.Emoji.Model
    , voiceChat : Evergreen.V421.Call.Model
    , games : SeqDict.SeqDict Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V421.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V421.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V421.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V421.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V421.Range.Range
                , direction : Evergreen.V421.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V421.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V421.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V421.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V421.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V421.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | PeerToPeerDownloadResponse (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.FileStatus.PeerToPeerId (Maybe String)
    | PeerToPeerSendFileRequest Evergreen.V421.FileStatus.PeerToPeerId String
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V421.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V421.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V421.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V421.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V421.MyUi.LastCopy
    , drag : Evergreen.V421.Touch.Drag
    , dragPrevious : Evergreen.V421.Touch.Drag
    , aiChatModel : Evergreen.V421.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V421.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V421.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V421.Audio.LoadError Evergreen.V421.Audio.Source
    , startupData : Evergreen.V421.Ports.StartupData
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
    Evergreen.V421.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V421.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V421.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V421.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    , messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.Slack.Id Evergreen.V421.Slack.MessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V421.Slack.User
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V421.Slack.User
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , linkedTo : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V421.Slack.SlackToken
    , cookie : Evergreen.V421.Slack.SlackCookie
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
    { fileHash : Evergreen.V421.FileStatus.FileHash
    , metadata : Maybe Evergreen.V421.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId
    , members : Evergreen.V421.NonemptySet.NonemptySet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    , messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.Slack.Id Evergreen.V421.Slack.MessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V421.FileStatus.FileHash
    , metadata : Maybe Evergreen.V421.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId, Evergreen.V421.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId, Evergreen.V421.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V421.DmChannelId.DmChannelId, Evergreen.V421.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId, Evergreen.V421.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId, Evergreen.V421.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId, Evergreen.V421.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V421.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V421.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V421.LocalState.BackupContents
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
    { users : Evergreen.V421.NonemptyDict.NonemptyDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V421.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V421.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V421.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V421.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V421.DmChannelId.DmChannelId Evergreen.V421.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) Evergreen.V421.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V421.FileStatus.FileHash Evergreen.V421.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V421.FileStatus.FileHash
    , privateVapidKey : Evergreen.V421.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    , textEditor : Evergreen.V421.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId, Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V421.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V421.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V421.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V421.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.LocalState.LoadingDiscordChannel Evergreen.V421.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Array.Array Effect.Time.Posix)
    , peerToPeerRateLimits : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V421.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V421.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V421.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId) Evergreen.V421.Sticker.StickerData
    , discordStickers : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.Discord.Id Evergreen.V421.Discord.StickerId) (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId) Evergreen.V421.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V421.OneToOne.OneToOne Evergreen.V421.RichText.DiscordCustomEmojiIdAndName (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V421.Postmark.ApiKey
    , serverSecret : Evergreen.V421.SecretId.SecretId Evergreen.V421.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V421.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.GamePublicId) ( Evergreen.V421.DmChannelId.GuildOrFullDmId, Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V421.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V421.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V421.Call.SharedCallId Evergreen.V421.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V421.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.Id.ThreadRoute (Maybe Evergreen.V421.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V421.DmChannelId.DmChannelId Evergreen.V421.Id.ThreadRoute (Maybe Evergreen.V421.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V421.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V421.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V421.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V421.UserAgent.UserAgent
    | AdminToBackend Evergreen.V421.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V421.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V421.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V421.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V421.PersonName.PersonName Evergreen.V421.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V421.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V421.Discord.UserAuth
    | LinkSlackRequest Evergreen.V421.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V421.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V421.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
        { fileName : String
        , json : String
        }
    | SharePeerToPeerFileRequest Evergreen.V421.FileStatus.PeerToPeerId Evergreen.V421.PeerToPeer.SharedFile
    | PeerToPeerDownloadRequest Evergreen.V421.Id.GuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.FileStatus.PeerToPeerId


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V421.Slack.Channel, Evergreen.V421.Slack.History )
    , dmChannels : List ( Evergreen.V421.Slack.DmChannel, Evergreen.V421.Slack.History )
    , users : List ( Evergreen.V421.Slack.User, Maybe Evergreen.V421.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V421.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V421.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V421.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V421.EmailAddress.EmailAddress (Result Evergreen.V421.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V421.EmailAddress.EmailAddress (Result Evergreen.V421.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V421.EmailAddress.EmailAddress (Result Evergreen.V421.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V421.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMaybeMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Result Evergreen.V421.Discord.HttpError Evergreen.V421.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V421.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Result Evergreen.V421.Discord.HttpError Evergreen.V421.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V421.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.Attachment) (Result Evergreen.V421.Slack.HttpError ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.MessageId, List ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.FileId, Evergreen.V421.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) (Result Evergreen.V421.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) (Result Evergreen.V421.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) (Result Evergreen.V421.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) (Result Evergreen.V421.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji (Result Evergreen.V421.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji (Result Evergreen.V421.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji (Result Evergreen.V421.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji (Result Evergreen.V421.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V421.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V421.Discord.HttpError (List ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId, Maybe Evergreen.V421.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Effect.Time.Posix Evergreen.V421.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Result Evergreen.V421.Slack.HttpError ( Evergreen.V421.Slack.User, Maybe Evergreen.V421.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V421.Slack.User (Maybe Evergreen.V421.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V421.Id.SlackGuildOrDmId (Result Evergreen.V421.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V421.Id.SlackGuildOrDmId (Result Evergreen.V421.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V421.Id.SlackGuildOrDmId (Result Evergreen.V421.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V421.Slack.SlackToken, Result Evergreen.V421.Slack.HttpError Evergreen.V421.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Result Evergreen.V421.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (List Evergreen.V421.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Result Evergreen.V421.Slack.HttpError Evergreen.V421.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V421.Slack.HttpError ) ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Discord.UserAuth (Result Evergreen.V421.Discord.HttpError Evergreen.V421.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Result Evergreen.V421.Discord.HttpError Evergreen.V421.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
        (Result
            Evergreen.V421.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId
                    , members : List (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
                    , messages : List Evergreen.V421.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId
                    , { guild : Evergreen.V421.Discord.GatewayGuild
                      , channels : List Evergreen.V421.Discord.Channel
                      , icon : Maybe Evergreen.V421.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (List Evergreen.V421.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V421.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V421.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V421.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V421.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.AttachmentId, Evergreen.V421.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V421.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.AttachmentId, Evergreen.V421.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V421.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V421.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V421.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V421.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (Result Evergreen.V421.Discord.HttpError Evergreen.V421.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Result Evergreen.V421.Discord.HttpError (List Evergreen.V421.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V421.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V421.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V421.DmChannelId.DmChannelId Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V421.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V421.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V421.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V421.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
        (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V421.Discord.HttpError
            { guild : Evergreen.V421.Discord.GatewayGuild
            , channels : List Evergreen.V421.Discord.Channel
            , icon : Maybe Evergreen.V421.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Maybe Evergreen.V421.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Result Evergreen.V421.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V421.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V421.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (List ( Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId, Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId, Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (List ( Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (List ( Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V421.Discord.HttpError (List Evergreen.V421.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V421.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V421.SecretId.SecretId Evergreen.V421.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V421.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V421.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V421.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V421.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Result Evergreen.V421.Discord.HttpError ( Evergreen.V421.Discord.Guild, List Evergreen.V421.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V421.FileStatus.FileHash Int (Maybe (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V421.Call.SharedCallId Effect.Time.Posix (Evergreen.V421.Message.CallRecordingFile (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V421.Call.SharedCallId Effect.Time.Posix (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V421.Call.SharedCallId Effect.Time.Posix Evergreen.V421.Message.CallRecordingZip
