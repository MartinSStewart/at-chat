module Evergreen.V408.Types exposing (..)

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
import Evergreen.V408.AiChat
import Evergreen.V408.Audio
import Evergreen.V408.BackendMsgLog
import Evergreen.V408.Call
import Evergreen.V408.ChannelDescription
import Evergreen.V408.ChannelName
import Evergreen.V408.Coord
import Evergreen.V408.CssPixels
import Evergreen.V408.CustomEmoji
import Evergreen.V408.Discord
import Evergreen.V408.DiscordAttachmentId
import Evergreen.V408.DiscordUserData
import Evergreen.V408.DmChannel
import Evergreen.V408.DmChannelId
import Evergreen.V408.Drawing
import Evergreen.V408.Editable
import Evergreen.V408.EmailAddress
import Evergreen.V408.Embed
import Evergreen.V408.Emoji
import Evergreen.V408.Encryption
import Evergreen.V408.FileStatus
import Evergreen.V408.Game
import Evergreen.V408.Go
import Evergreen.V408.GuildName
import Evergreen.V408.Id
import Evergreen.V408.IdArray
import Evergreen.V408.ImageEditor
import Evergreen.V408.ImageViewer
import Evergreen.V408.LinkedAndOtherDiscordUsers
import Evergreen.V408.Local
import Evergreen.V408.LocalState
import Evergreen.V408.Log
import Evergreen.V408.LoginForm
import Evergreen.V408.MembersAndOwner
import Evergreen.V408.Message
import Evergreen.V408.MessageInput
import Evergreen.V408.MessageView
import Evergreen.V408.MuteSettings
import Evergreen.V408.MyUi
import Evergreen.V408.NonemptyDict
import Evergreen.V408.NonemptySet
import Evergreen.V408.OneOrGreater
import Evergreen.V408.OneToOne
import Evergreen.V408.Pages.Admin
import Evergreen.V408.Pagination
import Evergreen.V408.PersonName
import Evergreen.V408.Ports
import Evergreen.V408.Postmark
import Evergreen.V408.Range
import Evergreen.V408.RateLimit
import Evergreen.V408.RecoveryLogin
import Evergreen.V408.RichText
import Evergreen.V408.Route
import Evergreen.V408.Scroll
import Evergreen.V408.SecretId
import Evergreen.V408.SessionIdHash
import Evergreen.V408.SetViewing
import Evergreen.V408.SheepGame
import Evergreen.V408.Slack
import Evergreen.V408.Sticker
import Evergreen.V408.TextEditor
import Evergreen.V408.Thread
import Evergreen.V408.ToBackendLog
import Evergreen.V408.Touch
import Evergreen.V408.TwoFactorAuthentication
import Evergreen.V408.Ui.Anim
import Evergreen.V408.User
import Evergreen.V408.UserAgent
import Evergreen.V408.UserColor
import Evergreen.V408.UserSession
import Evergreen.V408.VisibleMessages
import Evergreen.V408.WordSpellingGame
import Evergreen.V408.X25519
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
    | LoginFormMsg Evergreen.V408.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V408.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V408.Pages.Admin.Msg
    | PressedLogOut Evergreen.V408.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V408.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V408.Route.Route
    | SelectedFilesToAttach ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | PressedImportChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V408.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V408.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V408.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V408.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V408.NonemptyDict.NonemptyDict Int Evergreen.V408.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V408.NonemptyDict.NonemptyDict Int Evergreen.V408.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRoute Evergreen.V408.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V408.NonemptySet.NonemptySet (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V408.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V408.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V408.AiChat.Msg
    | GameMsg Evergreen.V408.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V408.Id.GuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V408.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V408.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V408.Editable.Msg Evergreen.V408.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V408.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) (Maybe Evergreen.V408.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute )
        { fileId : Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute )
        { fileId : Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V408.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V408.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V408.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V408.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V408.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V408.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V408.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | PressedDisableE2ee (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | TypedPrivateKey (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) String
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
    | TextEditorMsg Evergreen.V408.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId
        , otherUserId : Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V408.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRoute Evergreen.V408.MessageInput.Msg
    | MessageInputMsg Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRoute Evergreen.V408.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V408.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V408.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V408.Range.Range, Evergreen.V408.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V408.Range.Range, Evergreen.V408.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V408.Call.FromJs)
    | VoiceChatMsg Evergreen.V408.Call.Msg
    | PressedChannelHeaderTab Evergreen.V408.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V408.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V408.Audio.LoadError Evergreen.V408.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V408.Route.Route
    | PressedMuteChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V408.Id.AnyGuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V408.Id.AnyGuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) Evergreen.V408.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V408.Encryption.FromJs (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V408.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V408.UserSession.UserSession
    , currentlyViewing : Evergreen.V408.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) Evergreen.V408.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId) Evergreen.V408.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    , user : Evergreen.V408.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.User.FrontendUser
    , discordUsers : Evergreen.V408.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V408.SessionIdHash.SessionIdHash Evergreen.V408.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V408.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId) Evergreen.V408.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId) Evergreen.V408.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V408.Call.CallId (Evergreen.V408.NonemptyDict.NonemptyDict ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V408.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V408.Go.PublicGoMatchData Evergreen.V408.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V408.Route.Route
    , windowSize : Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V408.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V408.Audio.LoadError Evergreen.V408.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Encryption.EncryptedData (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.NonemptyDict.NonemptyDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Encryption.EncryptedData (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V408.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V408.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V408.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData) (List Evergreen.V408.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V408.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V408.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.ChannelName.ChannelName Evergreen.V408.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.ChannelName.ChannelName Evergreen.V408.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V408.GuildName.GuildName (Evergreen.V408.UserSession.ToBeFilledInByBackend (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V408.Id.Viewing_DiscordDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V408.SetViewing.SetViewing
    | Local_SetName Evergreen.V408.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V408.Id.GuildOrDmId (Evergreen.V408.VisibleMessages.PageRequest Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend Evergreen.V408.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V408.Id.GuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.VisibleMessages.PageRequest Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V408.Id.SlackGuildOrDmId (Evergreen.V408.VisibleMessages.PageRequest Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V408.Id.SlackGuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.VisibleMessages.PageRequest Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V408.Id.DiscordGuildOrDmId (Evergreen.V408.VisibleMessages.PageRequest Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V408.Id.DiscordGuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.VisibleMessages.PageRequest Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V408.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V408.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V408.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.QuestionId Evergreen.V408.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V408.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V408.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V408.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V408.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V408.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V408.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V408.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V408.NonemptySet.NonemptySet (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V408.Call.LocalChange
    | Local_Game Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Game.LocalChange
    | Local_Drawing Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Drawing.AnchorType Evergreen.V408.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V408.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V408.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V408.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V408.X25519.PublicKey (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V408.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V408.Id.Viewing_DmId (List ( Evergreen.V408.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V408.FileStatus.FileHash, Evergreen.V408.Encryption.EncryptedData (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V408.Id.Viewing_DmId (Evergreen.V408.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V408.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V408.Id.ThreadRouteWithMessage, Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V408.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V408.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V408.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V408.FileStatus.FileHash) (Evergreen.V408.Encryption.EncryptedData (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))) (Evergreen.V408.Encryption.EncryptedData String) Evergreen.V408.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V408.Id.Viewing_DmId Evergreen.V408.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V408.FileStatus.FileHash) (Evergreen.V408.Encryption.EncryptedData (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
    | RepliedToGame Evergreen.V408.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
        , sender : Evergreen.V408.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V408.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
        , threadRoute : Evergreen.V408.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId) Evergreen.V408.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData) (Maybe (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) Evergreen.V408.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V408.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
        (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId) Evergreen.V408.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId) Evergreen.V408.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId) Evergreen.V408.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId) Evergreen.V408.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V408.Id.DiscordGuildOrDmId Evergreen.V408.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId))) Evergreen.V408.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId) Evergreen.V408.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.ChannelName.ChannelName Evergreen.V408.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.ChannelName.ChannelName Evergreen.V408.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.User.FrontendUser
    | Server_MemberLeft (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V408.LocalState.JoinGuildError
            { guildId : Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId
            , guild : Evergreen.V408.LocalState.FrontendGuild
            , owner : Evergreen.V408.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V408.Id.Viewing_DiscordDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Maybe Evergreen.V408.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Maybe Evergreen.V408.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V408.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V408.SessionIdHash.SessionIdHash Evergreen.V408.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V408.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V408.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V408.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V408.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V408.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Bool Evergreen.V408.ChannelName.ChannelName (Evergreen.V408.Discord.OptionalData (Maybe String)) (List Evergreen.V408.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
        (Evergreen.V408.NonemptyDict.NonemptyDict
            (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) Evergreen.V408.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Maybe (Evergreen.V408.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V408.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V408.Log.Log
    | Server_BackupGenerated Evergreen.V408.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V408.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V408.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V408.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V408.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (Evergreen.V408.Discord.OptionalData (Maybe String)) (Evergreen.V408.Discord.OptionalData (Maybe String)) (List Evergreen.V408.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.GuildName.GuildName (Maybe Evergreen.V408.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.RoleId) Evergreen.V408.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.RoleId) Evergreen.V408.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
        (Evergreen.V408.MembersAndOwner.MembersAndOwner
            (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V408.Discord.Id Evergreen.V408.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.PersonName.PersonName Evergreen.V408.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId) Evergreen.V408.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId) Evergreen.V408.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V408.Call.ServerChange
    | Server_Game (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Game.LocalChange
    | Server_Drawing (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Drawing.AnchorType Evergreen.V408.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) Evergreen.V408.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V408.Id.Viewing_DmId ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Evergreen.V408.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V408.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V408.Id.Viewing_DmId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | Server_E2eeAccepted Evergreen.V408.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
        , sender : Evergreen.V408.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V408.Id.Viewing_DmId
        , content : Evergreen.V408.Encryption.EncryptedData (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
        , threadRoute : Evergreen.V408.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V408.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.Viewing_DmId Evergreen.V408.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V408.FileStatus.FileHash) (Evergreen.V408.Encryption.EncryptedData (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V408.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V408.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V408.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V408.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V408.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V408.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V408.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V408.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V408.Id.AnyGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V408.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels) (Maybe Evergreen.V408.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V408.SheepGame.Input (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels) (Maybe Evergreen.V408.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V408.Id.GuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V408.Id.GuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId) (Evergreen.V408.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V408.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V408.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V408.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V408.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    , threadRoute : Evergreen.V408.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V408.Encryption.BytesHash
    , id : Evergreen.V408.Id.Viewing_DmId
    , senderId : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    , threadRoute : Evergreen.V408.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V408.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V408.Id.Viewing_DmId
    , messages : List Evergreen.V408.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V408.Id.Viewing_DmId
    , messages : List ( Evergreen.V408.Id.ThreadRouteWithMessage, Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V408.Id.Viewing_DmId
    , threadRoute : Evergreen.V408.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute )
    , fileId : Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V408.Id.Id Evergreen.V408.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V408.Id.Id Evergreen.V408.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V408.Id.Id Evergreen.V408.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V408.Id.Id Evergreen.V408.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V408.Id.Id Evergreen.V408.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V408.Local.Local LocalMsg Evergreen.V408.LocalState.LocalState
    , admin : Evergreen.V408.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId, Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V408.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V408.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.Message.RepliedTo Evergreen.V408.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V408.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V408.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V408.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.ThreadRoute ) (Evergreen.V408.NonemptyDict.NonemptyDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V408.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V408.Scroll.ScrollPosition
    , textEditor : Evergreen.V408.TextEditor.Model
    , profilePictureEditor : Evergreen.V408.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId, Evergreen.V408.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V408.Emoji.Model
    , voiceChat : Evergreen.V408.Call.Model
    , games : SeqDict.SeqDict Evergreen.V408.Id.GuildOrDmId Evergreen.V408.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V408.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V408.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V408.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V408.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V408.Range.Range
                , direction : Evergreen.V408.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V408.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V408.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V408.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V408.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V408.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V408.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V408.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V408.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V408.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V408.MyUi.LastCopy
    , drag : Evergreen.V408.Touch.Drag
    , dragPrevious : Evergreen.V408.Touch.Drag
    , aiChatModel : Evergreen.V408.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V408.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V408.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V408.Audio.LoadError Evergreen.V408.Audio.Source
    , startupData : Evergreen.V408.Ports.StartupData
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
    Evergreen.V408.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V408.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V408.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V408.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    , messages : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V408.OneToOne.OneToOne (Evergreen.V408.Slack.Id Evergreen.V408.Slack.MessageId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V408.Slack.User
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V408.Slack.User
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , linkedTo : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V408.Slack.SlackToken
    , cookie : Evergreen.V408.Slack.SlackCookie
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
    { fileHash : Evergreen.V408.FileStatus.FileHash
    , metadata : Maybe Evergreen.V408.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId
    , members : Evergreen.V408.NonemptySet.NonemptySet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    , messages : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V408.OneToOne.OneToOne (Evergreen.V408.Slack.Id Evergreen.V408.Slack.MessageId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V408.FileStatus.FileHash
    , metadata : Maybe Evergreen.V408.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId, Evergreen.V408.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId, Evergreen.V408.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V408.DmChannelId.DmChannelId, Evergreen.V408.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId, Evergreen.V408.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId, Evergreen.V408.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId, Evergreen.V408.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V408.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V408.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V408.LocalState.BackupContents
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
    { users : Evergreen.V408.NonemptyDict.NonemptyDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V408.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V408.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V408.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V408.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V408.DmChannelId.DmChannelId Evergreen.V408.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) Evergreen.V408.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V408.FileStatus.FileHash Evergreen.V408.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V408.FileStatus.FileHash
    , privateVapidKey : Evergreen.V408.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V408.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId, Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V408.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V408.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V408.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V408.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.LocalState.LoadingDiscordChannel Evergreen.V408.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V408.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V408.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V408.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId) Evergreen.V408.Sticker.StickerData
    , discordStickers : Evergreen.V408.OneToOne.OneToOne (Evergreen.V408.Discord.Id Evergreen.V408.Discord.StickerId) (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId) Evergreen.V408.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V408.OneToOne.OneToOne Evergreen.V408.RichText.DiscordCustomEmojiIdAndName (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V408.Postmark.ApiKey
    , serverSecret : Evergreen.V408.SecretId.SecretId Evergreen.V408.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V408.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V408.OneToOne.OneToOne (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.GamePublicId) ( Evergreen.V408.DmChannelId.GuildOrFullDmId, Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V408.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V408.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V408.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.Id.ThreadRoute (Maybe Evergreen.V408.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V408.DmChannelId.DmChannelId Evergreen.V408.Id.ThreadRoute (Maybe Evergreen.V408.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V408.Id.Id Evergreen.V408.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V408.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V408.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V408.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V408.UserAgent.UserAgent
    | AdminToBackend Evergreen.V408.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V408.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V408.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V408.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V408.PersonName.PersonName Evergreen.V408.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V408.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V408.Discord.UserAuth
    | LinkSlackRequest Evergreen.V408.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V408.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V408.Id.Id Evergreen.V408.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V408.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
        { fileName : String
        , json : String
        }


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V408.Slack.Channel, Evergreen.V408.Slack.History )
    , dmChannels : List ( Evergreen.V408.Slack.DmChannel, Evergreen.V408.Slack.History )
    , users : List ( Evergreen.V408.Slack.User, Maybe Evergreen.V408.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V408.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V408.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V408.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V408.EmailAddress.EmailAddress (Result Evergreen.V408.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V408.EmailAddress.EmailAddress (Result Evergreen.V408.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V408.EmailAddress.EmailAddress (Result Evergreen.V408.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V408.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMaybeMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Result Evergreen.V408.Discord.HttpError Evergreen.V408.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V408.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Result Evergreen.V408.Discord.HttpError Evergreen.V408.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V408.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData) (Result Evergreen.V408.Slack.HttpError ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.MessageId, List ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.FileId, Evergreen.V408.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) (Result Evergreen.V408.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) (Result Evergreen.V408.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) (Result Evergreen.V408.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) (Result Evergreen.V408.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji (Result Evergreen.V408.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji (Result Evergreen.V408.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji (Result Evergreen.V408.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji (Result Evergreen.V408.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V408.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V408.Discord.HttpError (List ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId, Maybe Evergreen.V408.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Effect.Time.Posix Evergreen.V408.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Result Evergreen.V408.Slack.HttpError ( Evergreen.V408.Slack.User, Maybe Evergreen.V408.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V408.Slack.User (Maybe Evergreen.V408.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V408.Id.SlackGuildOrDmId (Result Evergreen.V408.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V408.Id.SlackGuildOrDmId (Result Evergreen.V408.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V408.Id.SlackGuildOrDmId (Result Evergreen.V408.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V408.Slack.SlackToken, Result Evergreen.V408.Slack.HttpError Evergreen.V408.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Result Evergreen.V408.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (List Evergreen.V408.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Result Evergreen.V408.Slack.HttpError Evergreen.V408.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V408.Slack.HttpError ) ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Discord.UserAuth (Result Evergreen.V408.Discord.HttpError Evergreen.V408.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Result Evergreen.V408.Discord.HttpError Evergreen.V408.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
        (Result
            Evergreen.V408.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId
                    , members : List (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
                    , messages : List Evergreen.V408.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId
                    , { guild : Evergreen.V408.Discord.GatewayGuild
                      , channels : List Evergreen.V408.Discord.Channel
                      , icon : Maybe Evergreen.V408.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (List Evergreen.V408.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V408.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V408.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V408.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V408.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.AttachmentId, Evergreen.V408.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V408.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.AttachmentId, Evergreen.V408.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V408.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V408.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V408.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V408.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) (Result Evergreen.V408.Discord.HttpError Evergreen.V408.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Result Evergreen.V408.Discord.HttpError (List Evergreen.V408.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V408.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V408.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V408.DmChannelId.DmChannelId Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V408.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V408.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V408.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V408.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
        (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V408.Discord.HttpError
            { guild : Evergreen.V408.Discord.GatewayGuild
            , channels : List Evergreen.V408.Discord.Channel
            , icon : Maybe Evergreen.V408.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Maybe Evergreen.V408.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Result Evergreen.V408.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V408.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V408.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (List ( Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId, Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId, Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (List ( Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (List ( Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V408.Discord.HttpError (List Evergreen.V408.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V408.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V408.SecretId.SecretId Evergreen.V408.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V408.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V408.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V408.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V408.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Result Evergreen.V408.Discord.HttpError ( Evergreen.V408.Discord.Guild, List Evergreen.V408.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V408.FileStatus.FileHash Int (Maybe (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Call.CallId
