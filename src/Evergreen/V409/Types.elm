module Evergreen.V409.Types exposing (..)

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
import Evergreen.V409.AiChat
import Evergreen.V409.Audio
import Evergreen.V409.BackendMsgLog
import Evergreen.V409.Call
import Evergreen.V409.ChannelDescription
import Evergreen.V409.ChannelName
import Evergreen.V409.Coord
import Evergreen.V409.CssPixels
import Evergreen.V409.CustomEmoji
import Evergreen.V409.Discord
import Evergreen.V409.DiscordAttachmentId
import Evergreen.V409.DiscordUserData
import Evergreen.V409.DmChannel
import Evergreen.V409.DmChannelId
import Evergreen.V409.Drawing
import Evergreen.V409.Editable
import Evergreen.V409.EmailAddress
import Evergreen.V409.Embed
import Evergreen.V409.Emoji
import Evergreen.V409.Encryption
import Evergreen.V409.FileStatus
import Evergreen.V409.Game
import Evergreen.V409.Go
import Evergreen.V409.GuildName
import Evergreen.V409.Id
import Evergreen.V409.IdArray
import Evergreen.V409.ImageEditor
import Evergreen.V409.ImageViewer
import Evergreen.V409.LinkedAndOtherDiscordUsers
import Evergreen.V409.Local
import Evergreen.V409.LocalState
import Evergreen.V409.Log
import Evergreen.V409.LoginForm
import Evergreen.V409.MembersAndOwner
import Evergreen.V409.Message
import Evergreen.V409.MessageInput
import Evergreen.V409.MessageView
import Evergreen.V409.MuteSettings
import Evergreen.V409.MyUi
import Evergreen.V409.NonemptyDict
import Evergreen.V409.NonemptySet
import Evergreen.V409.OneOrGreater
import Evergreen.V409.OneToOne
import Evergreen.V409.Pages.Admin
import Evergreen.V409.Pagination
import Evergreen.V409.PersonName
import Evergreen.V409.Ports
import Evergreen.V409.Postmark
import Evergreen.V409.Range
import Evergreen.V409.RateLimit
import Evergreen.V409.RecoveryLogin
import Evergreen.V409.RichText
import Evergreen.V409.Route
import Evergreen.V409.Scroll
import Evergreen.V409.SecretId
import Evergreen.V409.SessionIdHash
import Evergreen.V409.SetViewing
import Evergreen.V409.SheepGame
import Evergreen.V409.Slack
import Evergreen.V409.Sticker
import Evergreen.V409.TextEditor
import Evergreen.V409.Thread
import Evergreen.V409.ToBackendLog
import Evergreen.V409.Touch
import Evergreen.V409.TwoFactorAuthentication
import Evergreen.V409.Ui.Anim
import Evergreen.V409.User
import Evergreen.V409.UserAgent
import Evergreen.V409.UserColor
import Evergreen.V409.UserSession
import Evergreen.V409.VisibleMessages
import Evergreen.V409.WordSpellingGame
import Evergreen.V409.X25519
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
    | LoginFormMsg Evergreen.V409.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V409.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V409.Pages.Admin.Msg
    | PressedLogOut Evergreen.V409.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V409.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V409.Route.Route
    | SelectedFilesToAttach ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | PressedImportChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V409.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V409.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V409.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V409.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V409.NonemptyDict.NonemptyDict Int Evergreen.V409.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V409.NonemptyDict.NonemptyDict Int Evergreen.V409.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRoute Evergreen.V409.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V409.NonemptySet.NonemptySet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V409.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V409.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V409.AiChat.Msg
    | GameMsg Evergreen.V409.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V409.Id.GuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V409.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V409.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V409.Editable.Msg Evergreen.V409.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V409.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) (Maybe Evergreen.V409.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute )
        { fileId : Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute )
        { fileId : Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V409.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V409.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V409.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V409.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V409.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V409.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V409.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | PressedDisableE2ee (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | TypedPrivateKey (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) String
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
    | TextEditorMsg Evergreen.V409.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId
        , otherUserId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V409.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRoute Evergreen.V409.MessageInput.Msg
    | MessageInputMsg Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRoute Evergreen.V409.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V409.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V409.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V409.Range.Range, Evergreen.V409.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V409.Range.Range, Evergreen.V409.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V409.Call.FromJs)
    | VoiceChatMsg Evergreen.V409.Call.Msg
    | PressedChannelHeaderTab Evergreen.V409.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V409.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V409.Audio.LoadError Evergreen.V409.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V409.Route.Route
    | PressedMuteChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V409.Id.AnyGuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V409.Id.AnyGuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) Evergreen.V409.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V409.Encryption.FromJs (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V409.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V409.UserSession.UserSession
    , currentlyViewing : Evergreen.V409.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) Evergreen.V409.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId) Evergreen.V409.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    , user : Evergreen.V409.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.User.FrontendUser
    , discordUsers : Evergreen.V409.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V409.SessionIdHash.SessionIdHash Evergreen.V409.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V409.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId) Evergreen.V409.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId) Evergreen.V409.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V409.Call.CallId (Evergreen.V409.NonemptyDict.NonemptyDict ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V409.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V409.Go.PublicGoMatchData Evergreen.V409.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V409.Route.Route
    , windowSize : Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V409.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V409.Audio.LoadError Evergreen.V409.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Encryption.EncryptedData (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.NonemptyDict.NonemptyDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Encryption.EncryptedData (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V409.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V409.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V409.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData) (List Evergreen.V409.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V409.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V409.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.ChannelName.ChannelName Evergreen.V409.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.ChannelName.ChannelName Evergreen.V409.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V409.GuildName.GuildName (Evergreen.V409.UserSession.ToBeFilledInByBackend (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V409.Id.Viewing_DiscordDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V409.SetViewing.SetViewing
    | Local_SetName Evergreen.V409.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V409.Id.GuildOrDmId (Evergreen.V409.VisibleMessages.PageRequest Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend Evergreen.V409.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V409.Id.GuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.VisibleMessages.PageRequest Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V409.Id.SlackGuildOrDmId (Evergreen.V409.VisibleMessages.PageRequest Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V409.Id.SlackGuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.VisibleMessages.PageRequest Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V409.Id.DiscordGuildOrDmId (Evergreen.V409.VisibleMessages.PageRequest Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V409.Id.DiscordGuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.VisibleMessages.PageRequest Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V409.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V409.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V409.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.QuestionId Evergreen.V409.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V409.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V409.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V409.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V409.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V409.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V409.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V409.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V409.NonemptySet.NonemptySet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V409.Call.LocalChange
    | Local_Game Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Game.LocalChange
    | Local_Drawing Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Drawing.AnchorType Evergreen.V409.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V409.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V409.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V409.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V409.X25519.PublicKey (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V409.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V409.Id.Viewing_DmId (List ( Evergreen.V409.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V409.FileStatus.FileHash, Evergreen.V409.Encryption.EncryptedData (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V409.Id.Viewing_DmId (Evergreen.V409.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V409.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V409.Id.ThreadRouteWithMessage, Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V409.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V409.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V409.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V409.FileStatus.FileHash) (Evergreen.V409.Encryption.EncryptedData (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))) (Evergreen.V409.Encryption.EncryptedData String) Evergreen.V409.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V409.Id.Viewing_DmId Evergreen.V409.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V409.FileStatus.FileHash) (Evergreen.V409.Encryption.EncryptedData (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    | RepliedToGame Evergreen.V409.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
        , sender : Evergreen.V409.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V409.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
        , threadRoute : Evergreen.V409.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId) Evergreen.V409.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData) (Maybe (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) Evergreen.V409.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V409.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
        (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId) Evergreen.V409.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId) Evergreen.V409.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId) Evergreen.V409.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId) Evergreen.V409.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V409.Id.DiscordGuildOrDmId Evergreen.V409.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))) Evergreen.V409.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId) Evergreen.V409.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.ChannelName.ChannelName Evergreen.V409.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.ChannelName.ChannelName Evergreen.V409.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.User.FrontendUser
    | Server_MemberLeft (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V409.LocalState.JoinGuildError
            { guildId : Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId
            , guild : Evergreen.V409.LocalState.FrontendGuild
            , owner : Evergreen.V409.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V409.Id.Viewing_DiscordDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Maybe Evergreen.V409.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Maybe Evergreen.V409.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V409.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V409.SessionIdHash.SessionIdHash Evergreen.V409.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V409.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V409.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V409.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V409.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V409.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Bool Evergreen.V409.ChannelName.ChannelName (Evergreen.V409.Discord.OptionalData (Maybe String)) (List Evergreen.V409.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
        (Evergreen.V409.NonemptyDict.NonemptyDict
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) Evergreen.V409.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Maybe (Evergreen.V409.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V409.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V409.Log.Log
    | Server_BackupGenerated Evergreen.V409.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V409.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V409.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V409.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V409.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (Evergreen.V409.Discord.OptionalData (Maybe String)) (Evergreen.V409.Discord.OptionalData (Maybe String)) (List Evergreen.V409.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.GuildName.GuildName (Maybe Evergreen.V409.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId) Evergreen.V409.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId) Evergreen.V409.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
        (Evergreen.V409.MembersAndOwner.MembersAndOwner
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.PersonName.PersonName Evergreen.V409.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId) Evergreen.V409.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId) Evergreen.V409.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V409.Call.ServerChange
    | Server_Game (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Game.LocalChange
    | Server_Drawing (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Drawing.AnchorType Evergreen.V409.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) Evergreen.V409.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V409.Id.Viewing_DmId ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Evergreen.V409.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V409.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V409.Id.Viewing_DmId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | Server_E2eeAccepted Evergreen.V409.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
        , sender : Evergreen.V409.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V409.Id.Viewing_DmId
        , content : Evergreen.V409.Encryption.EncryptedData (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
        , threadRoute : Evergreen.V409.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V409.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.Viewing_DmId Evergreen.V409.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V409.FileStatus.FileHash) (Evergreen.V409.Encryption.EncryptedData (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V409.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V409.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V409.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V409.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V409.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V409.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V409.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V409.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V409.Id.AnyGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V409.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels) (Maybe Evergreen.V409.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V409.SheepGame.Input (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels) (Maybe Evergreen.V409.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V409.Id.GuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V409.Id.GuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId) (Evergreen.V409.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V409.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V409.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V409.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V409.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , threadRoute : Evergreen.V409.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V409.Encryption.BytesHash
    , id : Evergreen.V409.Id.Viewing_DmId
    , senderId : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , threadRoute : Evergreen.V409.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V409.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V409.Id.Viewing_DmId
    , messages : List Evergreen.V409.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V409.Id.Viewing_DmId
    , messages : List ( Evergreen.V409.Id.ThreadRouteWithMessage, Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V409.Id.Viewing_DmId
    , threadRoute : Evergreen.V409.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute )
    , fileId : Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V409.Id.Id Evergreen.V409.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V409.Id.Id Evergreen.V409.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V409.Id.Id Evergreen.V409.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V409.Id.Id Evergreen.V409.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V409.Id.Id Evergreen.V409.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V409.Local.Local LocalMsg Evergreen.V409.LocalState.LocalState
    , admin : Evergreen.V409.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId, Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V409.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V409.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.Message.RepliedTo Evergreen.V409.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V409.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V409.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V409.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.ThreadRoute ) (Evergreen.V409.NonemptyDict.NonemptyDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V409.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V409.Scroll.ScrollPosition
    , textEditor : Evergreen.V409.TextEditor.Model
    , profilePictureEditor : Evergreen.V409.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId, Evergreen.V409.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V409.Emoji.Model
    , voiceChat : Evergreen.V409.Call.Model
    , games : SeqDict.SeqDict Evergreen.V409.Id.GuildOrDmId Evergreen.V409.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V409.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V409.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V409.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V409.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V409.Range.Range
                , direction : Evergreen.V409.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V409.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V409.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V409.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V409.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V409.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V409.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V409.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V409.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V409.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V409.MyUi.LastCopy
    , drag : Evergreen.V409.Touch.Drag
    , dragPrevious : Evergreen.V409.Touch.Drag
    , aiChatModel : Evergreen.V409.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V409.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V409.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V409.Audio.LoadError Evergreen.V409.Audio.Source
    , startupData : Evergreen.V409.Ports.StartupData
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
    Evergreen.V409.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V409.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V409.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V409.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    , messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.Slack.Id Evergreen.V409.Slack.MessageId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V409.Slack.User
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V409.Slack.User
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , linkedTo : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V409.Slack.SlackToken
    , cookie : Evergreen.V409.Slack.SlackCookie
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
    { fileHash : Evergreen.V409.FileStatus.FileHash
    , metadata : Maybe Evergreen.V409.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId
    , members : Evergreen.V409.NonemptySet.NonemptySet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    , messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.Slack.Id Evergreen.V409.Slack.MessageId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V409.FileStatus.FileHash
    , metadata : Maybe Evergreen.V409.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId, Evergreen.V409.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId, Evergreen.V409.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V409.DmChannelId.DmChannelId, Evergreen.V409.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId, Evergreen.V409.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId, Evergreen.V409.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId, Evergreen.V409.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V409.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V409.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V409.LocalState.BackupContents
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
    { users : Evergreen.V409.NonemptyDict.NonemptyDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V409.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V409.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V409.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V409.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V409.DmChannelId.DmChannelId Evergreen.V409.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) Evergreen.V409.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V409.FileStatus.FileHash Evergreen.V409.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V409.FileStatus.FileHash
    , privateVapidKey : Evergreen.V409.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V409.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId, Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V409.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V409.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V409.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V409.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.LocalState.LoadingDiscordChannel Evergreen.V409.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V409.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V409.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V409.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId) Evergreen.V409.Sticker.StickerData
    , discordStickers : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.Discord.Id Evergreen.V409.Discord.StickerId) (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId) Evergreen.V409.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V409.OneToOne.OneToOne Evergreen.V409.RichText.DiscordCustomEmojiIdAndName (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V409.Postmark.ApiKey
    , serverSecret : Evergreen.V409.SecretId.SecretId Evergreen.V409.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V409.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.GamePublicId) ( Evergreen.V409.DmChannelId.GuildOrFullDmId, Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V409.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V409.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V409.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.Id.ThreadRoute (Maybe Evergreen.V409.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V409.DmChannelId.DmChannelId Evergreen.V409.Id.ThreadRoute (Maybe Evergreen.V409.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V409.Id.Id Evergreen.V409.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V409.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V409.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V409.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V409.UserAgent.UserAgent
    | AdminToBackend Evergreen.V409.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V409.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V409.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V409.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V409.PersonName.PersonName Evergreen.V409.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V409.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V409.Discord.UserAuth
    | LinkSlackRequest Evergreen.V409.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V409.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V409.Id.Id Evergreen.V409.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V409.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
        { fileName : String
        , json : String
        }


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V409.Slack.Channel, Evergreen.V409.Slack.History )
    , dmChannels : List ( Evergreen.V409.Slack.DmChannel, Evergreen.V409.Slack.History )
    , users : List ( Evergreen.V409.Slack.User, Maybe Evergreen.V409.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V409.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V409.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V409.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V409.EmailAddress.EmailAddress (Result Evergreen.V409.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V409.EmailAddress.EmailAddress (Result Evergreen.V409.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V409.EmailAddress.EmailAddress (Result Evergreen.V409.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V409.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMaybeMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Result Evergreen.V409.Discord.HttpError Evergreen.V409.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V409.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Result Evergreen.V409.Discord.HttpError Evergreen.V409.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V409.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData) (Result Evergreen.V409.Slack.HttpError ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.MessageId, List ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.FileId, Evergreen.V409.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) (Result Evergreen.V409.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) (Result Evergreen.V409.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) (Result Evergreen.V409.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) (Result Evergreen.V409.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji (Result Evergreen.V409.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji (Result Evergreen.V409.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji (Result Evergreen.V409.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji (Result Evergreen.V409.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V409.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V409.Discord.HttpError (List ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId, Maybe Evergreen.V409.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Effect.Time.Posix Evergreen.V409.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Result Evergreen.V409.Slack.HttpError ( Evergreen.V409.Slack.User, Maybe Evergreen.V409.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V409.Slack.User (Maybe Evergreen.V409.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V409.Id.SlackGuildOrDmId (Result Evergreen.V409.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V409.Id.SlackGuildOrDmId (Result Evergreen.V409.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V409.Id.SlackGuildOrDmId (Result Evergreen.V409.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V409.Slack.SlackToken, Result Evergreen.V409.Slack.HttpError Evergreen.V409.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Result Evergreen.V409.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (List Evergreen.V409.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Result Evergreen.V409.Slack.HttpError Evergreen.V409.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V409.Slack.HttpError ) ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Discord.UserAuth (Result Evergreen.V409.Discord.HttpError Evergreen.V409.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Result Evergreen.V409.Discord.HttpError Evergreen.V409.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
        (Result
            Evergreen.V409.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId
                    , members : List (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
                    , messages : List Evergreen.V409.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId
                    , { guild : Evergreen.V409.Discord.GatewayGuild
                      , channels : List Evergreen.V409.Discord.Channel
                      , icon : Maybe Evergreen.V409.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (List Evergreen.V409.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V409.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V409.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V409.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V409.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.AttachmentId, Evergreen.V409.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V409.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.AttachmentId, Evergreen.V409.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V409.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V409.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V409.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V409.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (Result Evergreen.V409.Discord.HttpError Evergreen.V409.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Result Evergreen.V409.Discord.HttpError (List Evergreen.V409.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V409.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V409.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V409.DmChannelId.DmChannelId Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V409.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V409.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V409.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V409.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
        (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V409.Discord.HttpError
            { guild : Evergreen.V409.Discord.GatewayGuild
            , channels : List Evergreen.V409.Discord.Channel
            , icon : Maybe Evergreen.V409.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Maybe Evergreen.V409.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Result Evergreen.V409.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V409.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V409.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (List ( Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId, Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId, Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (List ( Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (List ( Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V409.Discord.HttpError (List Evergreen.V409.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V409.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V409.SecretId.SecretId Evergreen.V409.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V409.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V409.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V409.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V409.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Result Evergreen.V409.Discord.HttpError ( Evergreen.V409.Discord.Guild, List Evergreen.V409.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V409.FileStatus.FileHash Int (Maybe (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Call.CallId
