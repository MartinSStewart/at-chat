module Evergreen.V417.Types exposing (..)

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
import Evergreen.V417.AiChat
import Evergreen.V417.Audio
import Evergreen.V417.BackendMsgLog
import Evergreen.V417.Call
import Evergreen.V417.ChannelDescription
import Evergreen.V417.ChannelName
import Evergreen.V417.Coord
import Evergreen.V417.CssPixels
import Evergreen.V417.CustomEmoji
import Evergreen.V417.Discord
import Evergreen.V417.DiscordAttachmentId
import Evergreen.V417.DiscordUserData
import Evergreen.V417.DmChannel
import Evergreen.V417.DmChannelId
import Evergreen.V417.Drawing
import Evergreen.V417.Editable
import Evergreen.V417.EmailAddress
import Evergreen.V417.Embed
import Evergreen.V417.Emoji
import Evergreen.V417.Encryption
import Evergreen.V417.FileStatus
import Evergreen.V417.Game
import Evergreen.V417.Go
import Evergreen.V417.GuildName
import Evergreen.V417.Id
import Evergreen.V417.IdArray
import Evergreen.V417.ImageEditor
import Evergreen.V417.ImageViewer
import Evergreen.V417.LinkedAndOtherDiscordUsers
import Evergreen.V417.Local
import Evergreen.V417.LocalState
import Evergreen.V417.Log
import Evergreen.V417.LoginForm
import Evergreen.V417.MembersAndOwner
import Evergreen.V417.Message
import Evergreen.V417.MessageInput
import Evergreen.V417.MessageView
import Evergreen.V417.MuteSettings
import Evergreen.V417.MyUi
import Evergreen.V417.NonemptyDict
import Evergreen.V417.NonemptySet
import Evergreen.V417.OneOrGreater
import Evergreen.V417.OneToOne
import Evergreen.V417.Pages.Admin
import Evergreen.V417.Pagination
import Evergreen.V417.PersonName
import Evergreen.V417.Ports
import Evergreen.V417.Postmark
import Evergreen.V417.Range
import Evergreen.V417.RateLimit
import Evergreen.V417.RecoveryLogin
import Evergreen.V417.RichText
import Evergreen.V417.Route
import Evergreen.V417.Scroll
import Evergreen.V417.SecretId
import Evergreen.V417.SessionIdHash
import Evergreen.V417.SetViewing
import Evergreen.V417.SheepGame
import Evergreen.V417.Slack
import Evergreen.V417.Sticker
import Evergreen.V417.TextEditor
import Evergreen.V417.Thread
import Evergreen.V417.ToBackendLog
import Evergreen.V417.Touch
import Evergreen.V417.TwoFactorAuthentication
import Evergreen.V417.Ui.Anim
import Evergreen.V417.User
import Evergreen.V417.UserAgent
import Evergreen.V417.UserColor
import Evergreen.V417.UserSession
import Evergreen.V417.VisibleMessages
import Evergreen.V417.WordSpellingGame
import Evergreen.V417.X25519
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
    | LoginFormMsg Evergreen.V417.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V417.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V417.Pages.Admin.Msg
    | PressedLogOut Evergreen.V417.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V417.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V417.Route.Route
    | SelectedFilesToAttach ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | PressedImportChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V417.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V417.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V417.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V417.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V417.NonemptyDict.NonemptyDict Int Evergreen.V417.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V417.NonemptyDict.NonemptyDict Int Evergreen.V417.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRoute Evergreen.V417.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V417.NonemptySet.NonemptySet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V417.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V417.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V417.AiChat.Msg
    | GameMsg Evergreen.V417.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V417.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V417.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V417.Editable.Msg Evergreen.V417.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V417.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) (Maybe Evergreen.V417.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute )
        { fileId : Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute )
        { fileId : Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V417.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V417.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V417.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V417.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V417.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V417.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V417.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | PressedDisableE2ee (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | TypedPrivateKey (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) String
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
    | TextEditorMsg Evergreen.V417.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId
        , otherUserId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V417.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRoute Evergreen.V417.MessageInput.Msg
    | MessageInputMsg Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRoute Evergreen.V417.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V417.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V417.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V417.Range.Range, Evergreen.V417.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V417.Range.Range, Evergreen.V417.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V417.Call.FromJs)
    | VoiceChatMsg Evergreen.V417.Call.Msg
    | PressedChannelHeaderTab Evergreen.V417.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V417.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V417.Audio.LoadError Evergreen.V417.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V417.Route.Route
    | PressedMuteChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V417.Id.AnyGuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V417.Id.AnyGuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) Evergreen.V417.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V417.Encryption.FromJs (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V417.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V417.UserSession.UserSession
    , currentlyViewing : Evergreen.V417.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) Evergreen.V417.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId) Evergreen.V417.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    , user : Evergreen.V417.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.User.FrontendUser
    , discordUsers : Evergreen.V417.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V417.SessionIdHash.SessionIdHash Evergreen.V417.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V417.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId) Evergreen.V417.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId) Evergreen.V417.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V417.Call.CallId (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V417.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V417.Call.CallId Evergreen.V417.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V417.Go.PublicGoMatchData Evergreen.V417.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V417.Route.Route
    , windowSize : Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V417.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V417.Audio.LoadError Evergreen.V417.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Encryption.EncryptedData (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.NonemptyDict.NonemptyDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Encryption.EncryptedData (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V417.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V417.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V417.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData) (List Evergreen.V417.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V417.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V417.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.ChannelName.ChannelName Evergreen.V417.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.ChannelName.ChannelName Evergreen.V417.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V417.GuildName.GuildName (Evergreen.V417.UserSession.ToBeFilledInByBackend (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V417.Id.Viewing_DiscordDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V417.SetViewing.SetViewing
    | Local_SetName Evergreen.V417.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.VisibleMessages.PageRequest Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend Evergreen.V417.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.VisibleMessages.PageRequest Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V417.Id.SlackGuildOrDmId (Evergreen.V417.VisibleMessages.PageRequest Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V417.Id.SlackGuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.VisibleMessages.PageRequest Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V417.Id.DiscordGuildOrDmId (Evergreen.V417.VisibleMessages.PageRequest Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V417.Id.DiscordGuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.VisibleMessages.PageRequest Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V417.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V417.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V417.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.QuestionId Evergreen.V417.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V417.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V417.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V417.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V417.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V417.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V417.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V417.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V417.NonemptySet.NonemptySet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V417.Call.LocalChange
    | Local_Game Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Game.LocalChange
    | Local_Drawing Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Drawing.AnchorType Evergreen.V417.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V417.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V417.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V417.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V417.X25519.PublicKey (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V417.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V417.Id.Viewing_DmId (List ( Evergreen.V417.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V417.FileStatus.FileHash, Evergreen.V417.Encryption.EncryptedData (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V417.Id.Viewing_DmId (Evergreen.V417.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V417.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V417.Id.ThreadRouteWithMessage, Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V417.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V417.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V417.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V417.FileStatus.FileHash) (Evergreen.V417.Encryption.EncryptedData (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))) (Evergreen.V417.Encryption.EncryptedData String) Evergreen.V417.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V417.Id.Viewing_DmId Evergreen.V417.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V417.FileStatus.FileHash) (Evergreen.V417.Encryption.EncryptedData (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    | RepliedToGame Evergreen.V417.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        , sender : Evergreen.V417.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V417.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
        , threadRoute : Evergreen.V417.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId) Evergreen.V417.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData) (Maybe (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) Evergreen.V417.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V417.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
        (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId) Evergreen.V417.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId) Evergreen.V417.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId) Evergreen.V417.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId) Evergreen.V417.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V417.Id.DiscordGuildOrDmId Evergreen.V417.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))) Evergreen.V417.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId) Evergreen.V417.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.ChannelName.ChannelName Evergreen.V417.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.ChannelName.ChannelName Evergreen.V417.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.User.FrontendUser
    | Server_MemberLeft (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V417.LocalState.JoinGuildError
            { guildId : Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId
            , guild : Evergreen.V417.LocalState.FrontendGuild
            , owner : Evergreen.V417.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V417.NonemptySet.NonemptySet (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.CallRecordingFile (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V417.Id.Viewing_DiscordDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Maybe Evergreen.V417.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Maybe Evergreen.V417.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V417.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V417.SessionIdHash.SessionIdHash Evergreen.V417.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V417.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V417.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V417.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V417.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V417.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Bool Evergreen.V417.ChannelName.ChannelName (Evergreen.V417.Discord.OptionalData (Maybe String)) (List Evergreen.V417.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
        (Evergreen.V417.NonemptyDict.NonemptyDict
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) Evergreen.V417.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Maybe (Evergreen.V417.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V417.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V417.Log.Log
    | Server_BackupGenerated Evergreen.V417.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V417.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V417.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V417.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V417.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (Evergreen.V417.Discord.OptionalData (Maybe String)) (Evergreen.V417.Discord.OptionalData (Maybe String)) (List Evergreen.V417.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.GuildName.GuildName (Maybe Evergreen.V417.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId) Evergreen.V417.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId) Evergreen.V417.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
        (Evergreen.V417.MembersAndOwner.MembersAndOwner
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.PersonName.PersonName Evergreen.V417.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId) Evergreen.V417.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId) Evergreen.V417.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V417.Call.ServerChange
    | Server_Game (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Game.LocalChange
    | Server_Drawing (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Drawing.AnchorType Evergreen.V417.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) Evergreen.V417.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V417.Id.Viewing_DmId ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V417.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V417.Id.Viewing_DmId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | Server_E2eeAccepted Evergreen.V417.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        , sender : Evergreen.V417.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V417.Id.Viewing_DmId
        , content : Evergreen.V417.Encryption.EncryptedData (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
        , threadRoute : Evergreen.V417.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V417.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.Viewing_DmId Evergreen.V417.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V417.FileStatus.FileHash) (Evergreen.V417.Encryption.EncryptedData (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V417.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V417.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V417.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V417.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V417.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V417.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V417.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V417.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V417.Id.AnyGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V417.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels) (Maybe Evergreen.V417.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V417.SheepGame.Input (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels) (Maybe Evergreen.V417.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V417.Id.GuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V417.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V417.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V417.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V417.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , threadRoute : Evergreen.V417.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V417.Encryption.BytesHash
    , id : Evergreen.V417.Id.Viewing_DmId
    , senderId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , threadRoute : Evergreen.V417.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V417.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V417.Id.Viewing_DmId
    , messages : List Evergreen.V417.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V417.Id.Viewing_DmId
    , messages : List ( Evergreen.V417.Id.ThreadRouteWithMessage, Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V417.Id.Viewing_DmId
    , threadRoute : Evergreen.V417.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute )
    , fileId : Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V417.Id.Id Evergreen.V417.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V417.Id.Id Evergreen.V417.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V417.Id.Id Evergreen.V417.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V417.Id.Id Evergreen.V417.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V417.Id.Id Evergreen.V417.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V417.Local.Local LocalMsg Evergreen.V417.LocalState.LocalState
    , admin : Evergreen.V417.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V417.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V417.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.Message.RepliedTo Evergreen.V417.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V417.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V417.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V417.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.ThreadRoute ) (Evergreen.V417.NonemptyDict.NonemptyDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V417.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V417.Scroll.ScrollPosition
    , textEditor : Evergreen.V417.TextEditor.Model
    , profilePictureEditor : Evergreen.V417.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId, Evergreen.V417.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V417.Emoji.Model
    , voiceChat : Evergreen.V417.Call.Model
    , games : SeqDict.SeqDict Evergreen.V417.Id.GuildOrDmId Evergreen.V417.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V417.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V417.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V417.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V417.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V417.Range.Range
                , direction : Evergreen.V417.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V417.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V417.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V417.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V417.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V417.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V417.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V417.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V417.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V417.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V417.MyUi.LastCopy
    , drag : Evergreen.V417.Touch.Drag
    , dragPrevious : Evergreen.V417.Touch.Drag
    , aiChatModel : Evergreen.V417.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V417.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V417.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V417.Audio.LoadError Evergreen.V417.Audio.Source
    , startupData : Evergreen.V417.Ports.StartupData
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
    Evergreen.V417.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V417.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V417.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V417.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    , messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.Slack.Id Evergreen.V417.Slack.MessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V417.Slack.User
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V417.Slack.User
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , linkedTo : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V417.Slack.SlackToken
    , cookie : Evergreen.V417.Slack.SlackCookie
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
    { fileHash : Evergreen.V417.FileStatus.FileHash
    , metadata : Maybe Evergreen.V417.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId
    , members : Evergreen.V417.NonemptySet.NonemptySet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    , messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.Slack.Id Evergreen.V417.Slack.MessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V417.FileStatus.FileHash
    , metadata : Maybe Evergreen.V417.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId, Evergreen.V417.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId, Evergreen.V417.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V417.DmChannelId.DmChannelId, Evergreen.V417.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId, Evergreen.V417.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId, Evergreen.V417.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId, Evergreen.V417.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V417.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V417.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V417.LocalState.BackupContents
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
    { users : Evergreen.V417.NonemptyDict.NonemptyDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V417.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V417.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V417.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V417.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V417.DmChannelId.DmChannelId Evergreen.V417.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) Evergreen.V417.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V417.FileStatus.FileHash Evergreen.V417.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V417.FileStatus.FileHash
    , privateVapidKey : Evergreen.V417.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    , textEditor : Evergreen.V417.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId, Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V417.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V417.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V417.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V417.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.LocalState.LoadingDiscordChannel Evergreen.V417.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V417.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V417.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V417.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId) Evergreen.V417.Sticker.StickerData
    , discordStickers : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.Discord.Id Evergreen.V417.Discord.StickerId) (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId) Evergreen.V417.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V417.OneToOne.OneToOne Evergreen.V417.RichText.DiscordCustomEmojiIdAndName (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V417.Postmark.ApiKey
    , serverSecret : Evergreen.V417.SecretId.SecretId Evergreen.V417.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V417.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.GamePublicId) ( Evergreen.V417.DmChannelId.GuildOrFullDmId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V417.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V417.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V417.Call.SharedCallId Evergreen.V417.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V417.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.Id.ThreadRoute (Maybe Evergreen.V417.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V417.DmChannelId.DmChannelId Evergreen.V417.Id.ThreadRoute (Maybe Evergreen.V417.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V417.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V417.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V417.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V417.UserAgent.UserAgent
    | AdminToBackend Evergreen.V417.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V417.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V417.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V417.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V417.PersonName.PersonName Evergreen.V417.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V417.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V417.Discord.UserAuth
    | LinkSlackRequest Evergreen.V417.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V417.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V417.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
        { fileName : String
        , json : String
        }


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V417.Slack.Channel, Evergreen.V417.Slack.History )
    , dmChannels : List ( Evergreen.V417.Slack.DmChannel, Evergreen.V417.Slack.History )
    , users : List ( Evergreen.V417.Slack.User, Maybe Evergreen.V417.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V417.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V417.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V417.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V417.EmailAddress.EmailAddress (Result Evergreen.V417.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V417.EmailAddress.EmailAddress (Result Evergreen.V417.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V417.EmailAddress.EmailAddress (Result Evergreen.V417.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V417.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMaybeMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Result Evergreen.V417.Discord.HttpError Evergreen.V417.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V417.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Result Evergreen.V417.Discord.HttpError Evergreen.V417.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V417.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData) (Result Evergreen.V417.Slack.HttpError ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.MessageId, List ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.FileId, Evergreen.V417.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) (Result Evergreen.V417.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) (Result Evergreen.V417.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) (Result Evergreen.V417.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) (Result Evergreen.V417.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji (Result Evergreen.V417.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji (Result Evergreen.V417.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji (Result Evergreen.V417.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji (Result Evergreen.V417.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V417.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V417.Discord.HttpError (List ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId, Maybe Evergreen.V417.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Effect.Time.Posix Evergreen.V417.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Result Evergreen.V417.Slack.HttpError ( Evergreen.V417.Slack.User, Maybe Evergreen.V417.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V417.Slack.User (Maybe Evergreen.V417.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V417.Id.SlackGuildOrDmId (Result Evergreen.V417.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V417.Id.SlackGuildOrDmId (Result Evergreen.V417.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V417.Id.SlackGuildOrDmId (Result Evergreen.V417.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V417.Slack.SlackToken, Result Evergreen.V417.Slack.HttpError Evergreen.V417.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Result Evergreen.V417.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (List Evergreen.V417.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Result Evergreen.V417.Slack.HttpError Evergreen.V417.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V417.Slack.HttpError ) ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Discord.UserAuth (Result Evergreen.V417.Discord.HttpError Evergreen.V417.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Result Evergreen.V417.Discord.HttpError Evergreen.V417.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
        (Result
            Evergreen.V417.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId
                    , members : List (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
                    , messages : List Evergreen.V417.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId
                    , { guild : Evergreen.V417.Discord.GatewayGuild
                      , channels : List Evergreen.V417.Discord.Channel
                      , icon : Maybe Evergreen.V417.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (List Evergreen.V417.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V417.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V417.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V417.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V417.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.AttachmentId, Evergreen.V417.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V417.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.AttachmentId, Evergreen.V417.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V417.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V417.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V417.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V417.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (Result Evergreen.V417.Discord.HttpError Evergreen.V417.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Result Evergreen.V417.Discord.HttpError (List Evergreen.V417.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V417.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V417.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V417.DmChannelId.DmChannelId Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V417.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V417.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V417.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V417.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
        (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V417.Discord.HttpError
            { guild : Evergreen.V417.Discord.GatewayGuild
            , channels : List Evergreen.V417.Discord.Channel
            , icon : Maybe Evergreen.V417.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Maybe Evergreen.V417.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Result Evergreen.V417.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V417.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V417.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (List ( Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId, Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId, Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (List ( Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (List ( Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V417.Discord.HttpError (List Evergreen.V417.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V417.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V417.SecretId.SecretId Evergreen.V417.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V417.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V417.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V417.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V417.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Result Evergreen.V417.Discord.HttpError ( Evergreen.V417.Discord.Guild, List Evergreen.V417.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V417.FileStatus.FileHash Int (Maybe (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V417.Call.SharedCallId Effect.Time.Posix (Evergreen.V417.Message.CallRecordingFile (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V417.Call.SharedCallId Effect.Time.Posix (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V417.Call.SharedCallId Effect.Time.Posix Evergreen.V417.Message.CallRecordingZip
