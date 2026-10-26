module Evergreen.V413.Types exposing (..)

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
import Evergreen.V413.AiChat
import Evergreen.V413.Audio
import Evergreen.V413.BackendMsgLog
import Evergreen.V413.Call
import Evergreen.V413.ChannelDescription
import Evergreen.V413.ChannelName
import Evergreen.V413.Coord
import Evergreen.V413.CssPixels
import Evergreen.V413.CustomEmoji
import Evergreen.V413.Discord
import Evergreen.V413.DiscordAttachmentId
import Evergreen.V413.DiscordUserData
import Evergreen.V413.DmChannel
import Evergreen.V413.DmChannelId
import Evergreen.V413.Drawing
import Evergreen.V413.Editable
import Evergreen.V413.EmailAddress
import Evergreen.V413.Embed
import Evergreen.V413.Emoji
import Evergreen.V413.Encryption
import Evergreen.V413.FileStatus
import Evergreen.V413.Game
import Evergreen.V413.Go
import Evergreen.V413.GuildName
import Evergreen.V413.Id
import Evergreen.V413.IdArray
import Evergreen.V413.ImageEditor
import Evergreen.V413.ImageViewer
import Evergreen.V413.LinkedAndOtherDiscordUsers
import Evergreen.V413.Local
import Evergreen.V413.LocalState
import Evergreen.V413.Log
import Evergreen.V413.LoginForm
import Evergreen.V413.MembersAndOwner
import Evergreen.V413.Message
import Evergreen.V413.MessageInput
import Evergreen.V413.MessageView
import Evergreen.V413.MuteSettings
import Evergreen.V413.MyUi
import Evergreen.V413.NonemptyDict
import Evergreen.V413.NonemptySet
import Evergreen.V413.OneOrGreater
import Evergreen.V413.OneToOne
import Evergreen.V413.Pages.Admin
import Evergreen.V413.Pagination
import Evergreen.V413.PersonName
import Evergreen.V413.Ports
import Evergreen.V413.Postmark
import Evergreen.V413.Range
import Evergreen.V413.RateLimit
import Evergreen.V413.RecoveryLogin
import Evergreen.V413.RichText
import Evergreen.V413.Route
import Evergreen.V413.Scroll
import Evergreen.V413.SecretId
import Evergreen.V413.SessionIdHash
import Evergreen.V413.SetViewing
import Evergreen.V413.SheepGame
import Evergreen.V413.Slack
import Evergreen.V413.Sticker
import Evergreen.V413.TextEditor
import Evergreen.V413.Thread
import Evergreen.V413.ToBackendLog
import Evergreen.V413.Touch
import Evergreen.V413.TwoFactorAuthentication
import Evergreen.V413.Ui.Anim
import Evergreen.V413.User
import Evergreen.V413.UserAgent
import Evergreen.V413.UserColor
import Evergreen.V413.UserSession
import Evergreen.V413.VisibleMessages
import Evergreen.V413.WordSpellingGame
import Evergreen.V413.X25519
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
    | LoginFormMsg Evergreen.V413.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V413.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V413.Pages.Admin.Msg
    | PressedLogOut Evergreen.V413.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V413.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V413.Route.Route
    | SelectedFilesToAttach ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | PressedImportChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V413.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V413.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V413.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V413.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V413.NonemptyDict.NonemptyDict Int Evergreen.V413.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V413.NonemptyDict.NonemptyDict Int Evergreen.V413.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRoute Evergreen.V413.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V413.NonemptySet.NonemptySet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V413.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V413.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V413.AiChat.Msg
    | GameMsg Evergreen.V413.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V413.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V413.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V413.Editable.Msg Evergreen.V413.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V413.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) (Maybe Evergreen.V413.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute )
        { fileId : Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute )
        { fileId : Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V413.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V413.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V413.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V413.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V413.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V413.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V413.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | PressedDisableE2ee (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | TypedPrivateKey (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) String
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
    | TextEditorMsg Evergreen.V413.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId
        , otherUserId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V413.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRoute Evergreen.V413.MessageInput.Msg
    | MessageInputMsg Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRoute Evergreen.V413.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V413.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V413.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V413.Range.Range, Evergreen.V413.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V413.Range.Range, Evergreen.V413.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V413.Call.FromJs)
    | VoiceChatMsg Evergreen.V413.Call.Msg
    | PressedChannelHeaderTab Evergreen.V413.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V413.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V413.Audio.LoadError Evergreen.V413.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V413.Route.Route
    | PressedMuteChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V413.Id.AnyGuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V413.Id.AnyGuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) Evergreen.V413.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V413.Encryption.FromJs (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V413.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V413.UserSession.UserSession
    , currentlyViewing : Evergreen.V413.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) Evergreen.V413.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.DmChannelId) Evergreen.V413.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    , user : Evergreen.V413.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.User.FrontendUser
    , discordUsers : Evergreen.V413.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V413.SessionIdHash.SessionIdHash Evergreen.V413.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V413.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId) Evergreen.V413.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId) Evergreen.V413.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V413.Call.CallId (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V413.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V413.Call.CallId Evergreen.V413.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V413.Go.PublicGoMatchData Evergreen.V413.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V413.Route.Route
    , windowSize : Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V413.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V413.Audio.LoadError Evergreen.V413.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Encryption.EncryptedData (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.NonemptyDict.NonemptyDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Encryption.EncryptedData (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V413.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V413.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V413.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData) (List Evergreen.V413.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V413.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V413.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.ChannelName.ChannelName Evergreen.V413.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.ChannelName.ChannelName Evergreen.V413.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.UserSession.ToBeFilledInByBackend (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V413.GuildName.GuildName (Evergreen.V413.UserSession.ToBeFilledInByBackend (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V413.Id.Viewing_DiscordDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V413.SetViewing.SetViewing
    | Local_SetName Evergreen.V413.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.VisibleMessages.PageRequest Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend Evergreen.V413.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.VisibleMessages.PageRequest Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V413.Id.SlackGuildOrDmId (Evergreen.V413.VisibleMessages.PageRequest Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V413.Id.SlackGuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.VisibleMessages.PageRequest Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V413.Id.DiscordGuildOrDmId (Evergreen.V413.VisibleMessages.PageRequest Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V413.Id.DiscordGuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.VisibleMessages.PageRequest Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V413.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V413.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V413.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.QuestionId Evergreen.V413.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V413.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V413.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V413.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V413.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V413.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V413.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V413.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V413.NonemptySet.NonemptySet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V413.Call.LocalChange
    | Local_Game Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Game.LocalChange
    | Local_Drawing Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Drawing.AnchorType Evergreen.V413.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V413.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V413.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V413.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V413.X25519.PublicKey (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V413.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V413.Id.Viewing_DmId (List ( Evergreen.V413.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V413.FileStatus.FileHash, Evergreen.V413.Encryption.EncryptedData (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V413.Id.Viewing_DmId (Evergreen.V413.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V413.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V413.Id.ThreadRouteWithMessage, Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V413.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V413.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V413.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V413.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V413.FileStatus.FileHash) (Evergreen.V413.Encryption.EncryptedData (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))) (Evergreen.V413.Encryption.EncryptedData String) Evergreen.V413.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V413.Id.Viewing_DmId Evergreen.V413.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V413.FileStatus.FileHash) (Evergreen.V413.Encryption.EncryptedData (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    | RepliedToGame Evergreen.V413.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        , sender : Evergreen.V413.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V413.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
        , threadRoute : Evergreen.V413.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId) Evergreen.V413.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData) (Maybe (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) Evergreen.V413.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V413.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
        (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.DmChannelId) Evergreen.V413.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId) Evergreen.V413.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId) Evergreen.V413.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId) Evergreen.V413.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V413.Id.DiscordGuildOrDmId Evergreen.V413.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))) Evergreen.V413.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId) Evergreen.V413.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.ChannelName.ChannelName Evergreen.V413.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.ChannelName.ChannelName Evergreen.V413.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.User.FrontendUser
    | Server_MemberLeft (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V413.LocalState.JoinGuildError
            { guildId : Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId
            , guild : Evergreen.V413.LocalState.FrontendGuild
            , owner : Evergreen.V413.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V413.NonemptySet.NonemptySet (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.CallRecordingFile (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V413.Id.Viewing_DiscordDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Maybe Evergreen.V413.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Maybe Evergreen.V413.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V413.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V413.SessionIdHash.SessionIdHash Evergreen.V413.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V413.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V413.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V413.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V413.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V413.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Evergreen.V413.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Bool Evergreen.V413.ChannelName.ChannelName (Evergreen.V413.Discord.OptionalData (Maybe String)) (List Evergreen.V413.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId)
        (Evergreen.V413.NonemptyDict.NonemptyDict
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) Evergreen.V413.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Evergreen.V413.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Maybe (Evergreen.V413.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V413.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V413.Log.Log
    | Server_BackupGenerated Evergreen.V413.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V413.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V413.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V413.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V413.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (Evergreen.V413.Discord.OptionalData (Maybe String)) (Evergreen.V413.Discord.OptionalData (Maybe String)) (List Evergreen.V413.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.GuildName.GuildName (Maybe Evergreen.V413.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId) Evergreen.V413.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId) Evergreen.V413.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId)
        (Evergreen.V413.MembersAndOwner.MembersAndOwner
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Evergreen.V413.PersonName.PersonName Evergreen.V413.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId) Evergreen.V413.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId) Evergreen.V413.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V413.Call.ServerChange
    | Server_Game (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Game.LocalChange
    | Server_Drawing (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Drawing.AnchorType Evergreen.V413.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) Evergreen.V413.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Evergreen.V413.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V413.Id.Viewing_DmId ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Evergreen.V413.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V413.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V413.Id.Viewing_DmId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | Server_E2eeAccepted Evergreen.V413.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        , sender : Evergreen.V413.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V413.Id.Viewing_DmId
        , content : Evergreen.V413.Encryption.EncryptedData (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
        , threadRoute : Evergreen.V413.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V413.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.Viewing_DmId Evergreen.V413.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V413.FileStatus.FileHash) (Evergreen.V413.Encryption.EncryptedData (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V413.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V413.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V413.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V413.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V413.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V413.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V413.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V413.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V413.Id.AnyGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V413.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels) (Maybe Evergreen.V413.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V413.SheepGame.Input (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels) (Maybe Evergreen.V413.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V413.Id.GuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId) (Evergreen.V413.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V413.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V413.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V413.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V413.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , threadRoute : Evergreen.V413.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V413.Encryption.BytesHash
    , id : Evergreen.V413.Id.Viewing_DmId
    , senderId : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , threadRoute : Evergreen.V413.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V413.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V413.Id.Viewing_DmId
    , messages : List Evergreen.V413.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V413.Id.Viewing_DmId
    , messages : List ( Evergreen.V413.Id.ThreadRouteWithMessage, Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V413.Id.Viewing_DmId
    , threadRoute : Evergreen.V413.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute )
    , fileId : Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V413.Id.Id Evergreen.V413.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V413.Id.Id Evergreen.V413.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V413.Id.Id Evergreen.V413.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V413.Id.Id Evergreen.V413.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V413.Id.Id Evergreen.V413.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V413.Local.Local LocalMsg Evergreen.V413.LocalState.LocalState
    , admin : Evergreen.V413.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId, Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V413.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V413.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.Message.RepliedTo Evergreen.V413.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V413.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V413.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V413.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.ThreadRoute ) (Evergreen.V413.NonemptyDict.NonemptyDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V413.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V413.Scroll.ScrollPosition
    , textEditor : Evergreen.V413.TextEditor.Model
    , profilePictureEditor : Evergreen.V413.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId, Evergreen.V413.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V413.Emoji.Model
    , voiceChat : Evergreen.V413.Call.Model
    , games : SeqDict.SeqDict Evergreen.V413.Id.GuildOrDmId Evergreen.V413.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V413.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V413.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V413.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V413.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V413.Range.Range
                , direction : Evergreen.V413.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V413.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V413.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V413.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V413.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V413.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V413.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V413.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V413.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V413.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V413.MyUi.LastCopy
    , drag : Evergreen.V413.Touch.Drag
    , dragPrevious : Evergreen.V413.Touch.Drag
    , aiChatModel : Evergreen.V413.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V413.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V413.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V413.Audio.LoadError Evergreen.V413.Audio.Source
    , startupData : Evergreen.V413.Ports.StartupData
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
    Evergreen.V413.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V413.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V413.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V413.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    , messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.Slack.Id Evergreen.V413.Slack.MessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V413.Slack.User
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V413.Slack.User
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , linkedTo : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V413.Slack.SlackToken
    , cookie : Evergreen.V413.Slack.SlackCookie
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
    { fileHash : Evergreen.V413.FileStatus.FileHash
    , metadata : Maybe Evergreen.V413.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId
    , members : Evergreen.V413.NonemptySet.NonemptySet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    , messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.Slack.Id Evergreen.V413.Slack.MessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V413.FileStatus.FileHash
    , metadata : Maybe Evergreen.V413.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId, Evergreen.V413.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId, Evergreen.V413.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V413.DmChannelId.DmChannelId, Evergreen.V413.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId, Evergreen.V413.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId, Evergreen.V413.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId, Evergreen.V413.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V413.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V413.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V413.LocalState.BackupContents
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
    { users : Evergreen.V413.NonemptyDict.NonemptyDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V413.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V413.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V413.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V413.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) Evergreen.V413.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V413.DmChannelId.DmChannelId Evergreen.V413.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) Evergreen.V413.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V413.FileStatus.FileHash Evergreen.V413.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V413.FileStatus.FileHash
    , privateVapidKey : Evergreen.V413.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    , textEditor : Evergreen.V413.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Evergreen.V413.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId, Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V413.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V413.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V413.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V413.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.LocalState.LoadingDiscordChannel Evergreen.V413.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V413.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V413.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V413.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId) Evergreen.V413.Sticker.StickerData
    , discordStickers : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.Discord.Id Evergreen.V413.Discord.StickerId) (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId) Evergreen.V413.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V413.OneToOne.OneToOne Evergreen.V413.RichText.DiscordCustomEmojiIdAndName (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V413.Postmark.ApiKey
    , serverSecret : Evergreen.V413.SecretId.SecretId Evergreen.V413.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V413.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.GamePublicId) ( Evergreen.V413.DmChannelId.GuildOrFullDmId, Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V413.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V413.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V413.Call.SharedCallId Evergreen.V413.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V413.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.Id.ThreadRoute (Maybe Evergreen.V413.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V413.DmChannelId.DmChannelId Evergreen.V413.Id.ThreadRoute (Maybe Evergreen.V413.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V413.Id.Id Evergreen.V413.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V413.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V413.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V413.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V413.UserAgent.UserAgent
    | AdminToBackend Evergreen.V413.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V413.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V413.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V413.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V413.PersonName.PersonName Evergreen.V413.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V413.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V413.Discord.UserAuth
    | LinkSlackRequest Evergreen.V413.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V413.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V413.Id.Id Evergreen.V413.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V413.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
        { fileName : String
        , json : String
        }


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V413.Slack.Channel, Evergreen.V413.Slack.History )
    , dmChannels : List ( Evergreen.V413.Slack.DmChannel, Evergreen.V413.Slack.History )
    , users : List ( Evergreen.V413.Slack.User, Maybe Evergreen.V413.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V413.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V413.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V413.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V413.EmailAddress.EmailAddress (Result Evergreen.V413.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V413.EmailAddress.EmailAddress (Result Evergreen.V413.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V413.EmailAddress.EmailAddress (Result Evergreen.V413.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V413.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMaybeMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Result Evergreen.V413.Discord.HttpError Evergreen.V413.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V413.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Result Evergreen.V413.Discord.HttpError Evergreen.V413.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V413.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData) (Result Evergreen.V413.Slack.HttpError ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.MessageId, List ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.FileId, Evergreen.V413.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) (Result Evergreen.V413.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) (Result Evergreen.V413.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) (Result Evergreen.V413.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) (Result Evergreen.V413.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji (Result Evergreen.V413.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji (Result Evergreen.V413.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji (Result Evergreen.V413.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji (Result Evergreen.V413.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V413.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V413.Discord.HttpError (List ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId, Maybe Evergreen.V413.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Effect.Time.Posix Evergreen.V413.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Result Evergreen.V413.Slack.HttpError ( Evergreen.V413.Slack.User, Maybe Evergreen.V413.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V413.Slack.User (Maybe Evergreen.V413.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V413.Id.SlackGuildOrDmId (Result Evergreen.V413.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V413.Id.SlackGuildOrDmId (Result Evergreen.V413.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V413.Id.SlackGuildOrDmId (Result Evergreen.V413.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V413.Slack.SlackToken, Result Evergreen.V413.Slack.HttpError Evergreen.V413.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Result Evergreen.V413.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (List Evergreen.V413.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Result Evergreen.V413.Slack.HttpError Evergreen.V413.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V413.Slack.HttpError ) ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Discord.UserAuth (Result Evergreen.V413.Discord.HttpError Evergreen.V413.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Result Evergreen.V413.Discord.HttpError Evergreen.V413.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
        (Result
            Evergreen.V413.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId
                    , members : List (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
                    , messages : List Evergreen.V413.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId
                    , { guild : Evergreen.V413.Discord.GatewayGuild
                      , channels : List Evergreen.V413.Discord.Channel
                      , icon : Maybe Evergreen.V413.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (List Evergreen.V413.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V413.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V413.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V413.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V413.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.AttachmentId, Evergreen.V413.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V413.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.AttachmentId, Evergreen.V413.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V413.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V413.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V413.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V413.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (Result Evergreen.V413.Discord.HttpError Evergreen.V413.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Result Evergreen.V413.Discord.HttpError (List Evergreen.V413.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V413.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V413.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V413.DmChannelId.DmChannelId Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V413.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V413.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V413.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V413.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
        (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V413.Discord.HttpError
            { guild : Evergreen.V413.Discord.GatewayGuild
            , channels : List Evergreen.V413.Discord.Channel
            , icon : Maybe Evergreen.V413.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Maybe Evergreen.V413.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Result Evergreen.V413.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V413.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V413.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (List ( Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId, Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId, Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (List ( Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (List ( Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V413.Discord.HttpError (List Evergreen.V413.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V413.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V413.SecretId.SecretId Evergreen.V413.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V413.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V413.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V413.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V413.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Result Evergreen.V413.Discord.HttpError ( Evergreen.V413.Discord.Guild, List Evergreen.V413.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V413.FileStatus.FileHash Int (Maybe (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V413.Call.SharedCallId Effect.Time.Posix (Evergreen.V413.Message.CallRecordingFile (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V413.Call.SharedCallId Effect.Time.Posix (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V413.Call.SharedCallId Effect.Time.Posix Evergreen.V413.Message.CallRecordingZip
