module Evergreen.V412.Types exposing (..)

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
import Evergreen.V412.AiChat
import Evergreen.V412.Audio
import Evergreen.V412.BackendMsgLog
import Evergreen.V412.Call
import Evergreen.V412.ChannelDescription
import Evergreen.V412.ChannelName
import Evergreen.V412.Coord
import Evergreen.V412.CssPixels
import Evergreen.V412.CustomEmoji
import Evergreen.V412.Discord
import Evergreen.V412.DiscordAttachmentId
import Evergreen.V412.DiscordUserData
import Evergreen.V412.DmChannel
import Evergreen.V412.DmChannelId
import Evergreen.V412.Drawing
import Evergreen.V412.Editable
import Evergreen.V412.EmailAddress
import Evergreen.V412.Embed
import Evergreen.V412.Emoji
import Evergreen.V412.Encryption
import Evergreen.V412.FileStatus
import Evergreen.V412.Game
import Evergreen.V412.Go
import Evergreen.V412.GuildName
import Evergreen.V412.Id
import Evergreen.V412.IdArray
import Evergreen.V412.ImageEditor
import Evergreen.V412.ImageViewer
import Evergreen.V412.LinkedAndOtherDiscordUsers
import Evergreen.V412.Local
import Evergreen.V412.LocalState
import Evergreen.V412.Log
import Evergreen.V412.LoginForm
import Evergreen.V412.MembersAndOwner
import Evergreen.V412.Message
import Evergreen.V412.MessageInput
import Evergreen.V412.MessageView
import Evergreen.V412.MuteSettings
import Evergreen.V412.MyUi
import Evergreen.V412.NonemptyDict
import Evergreen.V412.NonemptySet
import Evergreen.V412.OneOrGreater
import Evergreen.V412.OneToOne
import Evergreen.V412.Pages.Admin
import Evergreen.V412.Pagination
import Evergreen.V412.PersonName
import Evergreen.V412.Ports
import Evergreen.V412.Postmark
import Evergreen.V412.Range
import Evergreen.V412.RateLimit
import Evergreen.V412.RecoveryLogin
import Evergreen.V412.RichText
import Evergreen.V412.Route
import Evergreen.V412.Scroll
import Evergreen.V412.SecretId
import Evergreen.V412.SessionIdHash
import Evergreen.V412.SetViewing
import Evergreen.V412.SheepGame
import Evergreen.V412.Slack
import Evergreen.V412.Sticker
import Evergreen.V412.TextEditor
import Evergreen.V412.Thread
import Evergreen.V412.ToBackendLog
import Evergreen.V412.Touch
import Evergreen.V412.TwoFactorAuthentication
import Evergreen.V412.Ui.Anim
import Evergreen.V412.User
import Evergreen.V412.UserAgent
import Evergreen.V412.UserColor
import Evergreen.V412.UserSession
import Evergreen.V412.VisibleMessages
import Evergreen.V412.WordSpellingGame
import Evergreen.V412.X25519
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
    | LoginFormMsg Evergreen.V412.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V412.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V412.Pages.Admin.Msg
    | PressedLogOut Evergreen.V412.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V412.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V412.Route.Route
    | SelectedFilesToAttach ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | PressedImportChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V412.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V412.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V412.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V412.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V412.NonemptyDict.NonemptyDict Int Evergreen.V412.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V412.NonemptyDict.NonemptyDict Int Evergreen.V412.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRoute Evergreen.V412.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V412.NonemptySet.NonemptySet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V412.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V412.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V412.AiChat.Msg
    | GameMsg Evergreen.V412.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V412.Id.GuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V412.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V412.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V412.Editable.Msg Evergreen.V412.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V412.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) (Maybe Evergreen.V412.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute )
        { fileId : Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute )
        { fileId : Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V412.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V412.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V412.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V412.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V412.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V412.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V412.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | PressedDisableE2ee (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | TypedPrivateKey (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) String
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
    | TextEditorMsg Evergreen.V412.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId
        , otherUserId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V412.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRoute Evergreen.V412.MessageInput.Msg
    | MessageInputMsg Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRoute Evergreen.V412.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V412.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V412.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V412.Range.Range, Evergreen.V412.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V412.Range.Range, Evergreen.V412.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V412.Call.FromJs)
    | VoiceChatMsg Evergreen.V412.Call.Msg
    | PressedChannelHeaderTab Evergreen.V412.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V412.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V412.Audio.LoadError Evergreen.V412.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V412.Route.Route
    | PressedMuteChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V412.Id.AnyGuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V412.Id.AnyGuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) Evergreen.V412.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V412.Encryption.FromJs (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V412.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V412.UserSession.UserSession
    , currentlyViewing : Evergreen.V412.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) Evergreen.V412.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId) Evergreen.V412.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    , user : Evergreen.V412.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.User.FrontendUser
    , discordUsers : Evergreen.V412.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V412.SessionIdHash.SessionIdHash Evergreen.V412.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V412.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId) Evergreen.V412.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId) Evergreen.V412.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V412.Call.CallId (Evergreen.V412.NonemptyDict.NonemptyDict ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V412.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V412.Go.PublicGoMatchData Evergreen.V412.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V412.Route.Route
    , windowSize : Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V412.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V412.Audio.LoadError Evergreen.V412.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Encryption.EncryptedData (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.NonemptyDict.NonemptyDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Encryption.EncryptedData (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V412.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V412.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V412.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData) (List Evergreen.V412.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V412.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V412.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.ChannelName.ChannelName Evergreen.V412.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.ChannelName.ChannelName Evergreen.V412.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V412.GuildName.GuildName (Evergreen.V412.UserSession.ToBeFilledInByBackend (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V412.Id.Viewing_DiscordDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V412.SetViewing.SetViewing
    | Local_SetName Evergreen.V412.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V412.Id.GuildOrDmId (Evergreen.V412.VisibleMessages.PageRequest Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend Evergreen.V412.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V412.Id.GuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.VisibleMessages.PageRequest Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V412.Id.SlackGuildOrDmId (Evergreen.V412.VisibleMessages.PageRequest Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V412.Id.SlackGuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.VisibleMessages.PageRequest Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V412.Id.DiscordGuildOrDmId (Evergreen.V412.VisibleMessages.PageRequest Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V412.Id.DiscordGuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.VisibleMessages.PageRequest Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V412.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V412.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V412.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.QuestionId Evergreen.V412.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V412.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V412.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V412.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V412.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V412.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V412.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V412.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V412.NonemptySet.NonemptySet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V412.Call.LocalChange
    | Local_Game Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Game.LocalChange
    | Local_Drawing Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Drawing.AnchorType Evergreen.V412.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V412.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V412.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V412.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V412.X25519.PublicKey (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V412.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V412.Id.Viewing_DmId (List ( Evergreen.V412.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V412.FileStatus.FileHash, Evergreen.V412.Encryption.EncryptedData (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V412.Id.Viewing_DmId (Evergreen.V412.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V412.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V412.Id.ThreadRouteWithMessage, Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V412.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V412.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V412.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V412.FileStatus.FileHash) (Evergreen.V412.Encryption.EncryptedData (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))) (Evergreen.V412.Encryption.EncryptedData String) Evergreen.V412.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V412.Id.Viewing_DmId Evergreen.V412.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V412.FileStatus.FileHash) (Evergreen.V412.Encryption.EncryptedData (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    | RepliedToGame Evergreen.V412.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
        , sender : Evergreen.V412.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V412.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
        , threadRoute : Evergreen.V412.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId) Evergreen.V412.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData) (Maybe (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) Evergreen.V412.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V412.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
        (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId) Evergreen.V412.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId) Evergreen.V412.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId) Evergreen.V412.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId) Evergreen.V412.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V412.Id.DiscordGuildOrDmId Evergreen.V412.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))) Evergreen.V412.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId) Evergreen.V412.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.ChannelName.ChannelName Evergreen.V412.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.ChannelName.ChannelName Evergreen.V412.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.User.FrontendUser
    | Server_MemberLeft (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V412.LocalState.JoinGuildError
            { guildId : Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId
            , guild : Evergreen.V412.LocalState.FrontendGuild
            , owner : Evergreen.V412.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V412.Id.Viewing_DiscordDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Maybe Evergreen.V412.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Maybe Evergreen.V412.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V412.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V412.SessionIdHash.SessionIdHash Evergreen.V412.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V412.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V412.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V412.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V412.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V412.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Bool Evergreen.V412.ChannelName.ChannelName (Evergreen.V412.Discord.OptionalData (Maybe String)) (List Evergreen.V412.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
        (Evergreen.V412.NonemptyDict.NonemptyDict
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) Evergreen.V412.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Maybe (Evergreen.V412.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V412.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V412.Log.Log
    | Server_BackupGenerated Evergreen.V412.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V412.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V412.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V412.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V412.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (Evergreen.V412.Discord.OptionalData (Maybe String)) (Evergreen.V412.Discord.OptionalData (Maybe String)) (List Evergreen.V412.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.GuildName.GuildName (Maybe Evergreen.V412.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId) Evergreen.V412.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId) Evergreen.V412.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
        (Evergreen.V412.MembersAndOwner.MembersAndOwner
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.PersonName.PersonName Evergreen.V412.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId) Evergreen.V412.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId) Evergreen.V412.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V412.Call.ServerChange
    | Server_Game (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Game.LocalChange
    | Server_Drawing (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Drawing.AnchorType Evergreen.V412.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) Evergreen.V412.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V412.Id.Viewing_DmId ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Evergreen.V412.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V412.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V412.Id.Viewing_DmId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | Server_E2eeAccepted Evergreen.V412.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
        , sender : Evergreen.V412.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V412.Id.Viewing_DmId
        , content : Evergreen.V412.Encryption.EncryptedData (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
        , threadRoute : Evergreen.V412.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V412.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.Viewing_DmId Evergreen.V412.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V412.FileStatus.FileHash) (Evergreen.V412.Encryption.EncryptedData (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V412.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V412.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V412.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V412.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V412.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V412.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V412.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V412.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V412.Id.AnyGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V412.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels) (Maybe Evergreen.V412.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V412.SheepGame.Input (Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels) (Maybe Evergreen.V412.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V412.Id.GuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V412.Id.GuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId) (Evergreen.V412.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V412.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V412.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V412.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V412.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , threadRoute : Evergreen.V412.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V412.Encryption.BytesHash
    , id : Evergreen.V412.Id.Viewing_DmId
    , senderId : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , threadRoute : Evergreen.V412.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V412.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V412.Id.Viewing_DmId
    , messages : List Evergreen.V412.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V412.Id.Viewing_DmId
    , messages : List ( Evergreen.V412.Id.ThreadRouteWithMessage, Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V412.Id.Viewing_DmId
    , threadRoute : Evergreen.V412.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute )
    , fileId : Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V412.Id.Id Evergreen.V412.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V412.Id.Id Evergreen.V412.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V412.Id.Id Evergreen.V412.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V412.Id.Id Evergreen.V412.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V412.Id.Id Evergreen.V412.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V412.Local.Local LocalMsg Evergreen.V412.LocalState.LocalState
    , admin : Evergreen.V412.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId, Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V412.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V412.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.Message.RepliedTo Evergreen.V412.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V412.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V412.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V412.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.ThreadRoute ) (Evergreen.V412.NonemptyDict.NonemptyDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V412.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V412.Scroll.ScrollPosition
    , textEditor : Evergreen.V412.TextEditor.Model
    , profilePictureEditor : Evergreen.V412.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId, Evergreen.V412.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V412.Emoji.Model
    , voiceChat : Evergreen.V412.Call.Model
    , games : SeqDict.SeqDict Evergreen.V412.Id.GuildOrDmId Evergreen.V412.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V412.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V412.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V412.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V412.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V412.Range.Range
                , direction : Evergreen.V412.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V412.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V412.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V412.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V412.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V412.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V412.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V412.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V412.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V412.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V412.MyUi.LastCopy
    , drag : Evergreen.V412.Touch.Drag
    , dragPrevious : Evergreen.V412.Touch.Drag
    , aiChatModel : Evergreen.V412.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V412.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V412.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V412.Audio.LoadError Evergreen.V412.Audio.Source
    , startupData : Evergreen.V412.Ports.StartupData
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
    Evergreen.V412.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V412.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V412.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V412.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    , messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.Slack.Id Evergreen.V412.Slack.MessageId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V412.Slack.User
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V412.Slack.User
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , linkedTo : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V412.Slack.SlackToken
    , cookie : Evergreen.V412.Slack.SlackCookie
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
    { fileHash : Evergreen.V412.FileStatus.FileHash
    , metadata : Maybe Evergreen.V412.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId
    , members : Evergreen.V412.NonemptySet.NonemptySet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    , messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.Slack.Id Evergreen.V412.Slack.MessageId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V412.FileStatus.FileHash
    , metadata : Maybe Evergreen.V412.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId, Evergreen.V412.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId, Evergreen.V412.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V412.DmChannelId.DmChannelId, Evergreen.V412.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId, Evergreen.V412.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId, Evergreen.V412.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId, Evergreen.V412.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V412.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V412.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V412.LocalState.BackupContents
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
    { users : Evergreen.V412.NonemptyDict.NonemptyDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V412.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V412.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V412.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V412.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V412.DmChannelId.DmChannelId Evergreen.V412.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) Evergreen.V412.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V412.FileStatus.FileHash Evergreen.V412.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V412.FileStatus.FileHash
    , privateVapidKey : Evergreen.V412.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    , textEditor : Evergreen.V412.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId, Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V412.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V412.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V412.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V412.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.LocalState.LoadingDiscordChannel Evergreen.V412.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V412.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V412.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V412.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId) Evergreen.V412.Sticker.StickerData
    , discordStickers : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.Discord.Id Evergreen.V412.Discord.StickerId) (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId) Evergreen.V412.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V412.OneToOne.OneToOne Evergreen.V412.RichText.DiscordCustomEmojiIdAndName (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V412.Postmark.ApiKey
    , serverSecret : Evergreen.V412.SecretId.SecretId Evergreen.V412.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V412.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.GamePublicId) ( Evergreen.V412.DmChannelId.GuildOrFullDmId, Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V412.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V412.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V412.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.Id.ThreadRoute (Maybe Evergreen.V412.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V412.DmChannelId.DmChannelId Evergreen.V412.Id.ThreadRoute (Maybe Evergreen.V412.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V412.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V412.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V412.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V412.UserAgent.UserAgent
    | AdminToBackend Evergreen.V412.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V412.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V412.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V412.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V412.PersonName.PersonName Evergreen.V412.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V412.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V412.Discord.UserAuth
    | LinkSlackRequest Evergreen.V412.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V412.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V412.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
        { fileName : String
        , json : String
        }


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V412.Slack.Channel, Evergreen.V412.Slack.History )
    , dmChannels : List ( Evergreen.V412.Slack.DmChannel, Evergreen.V412.Slack.History )
    , users : List ( Evergreen.V412.Slack.User, Maybe Evergreen.V412.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V412.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V412.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V412.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V412.EmailAddress.EmailAddress (Result Evergreen.V412.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V412.EmailAddress.EmailAddress (Result Evergreen.V412.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V412.EmailAddress.EmailAddress (Result Evergreen.V412.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V412.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMaybeMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Result Evergreen.V412.Discord.HttpError Evergreen.V412.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V412.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Result Evergreen.V412.Discord.HttpError Evergreen.V412.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V412.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData) (Result Evergreen.V412.Slack.HttpError ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.MessageId, List ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.FileId, Evergreen.V412.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) (Result Evergreen.V412.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) (Result Evergreen.V412.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) (Result Evergreen.V412.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) (Result Evergreen.V412.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji (Result Evergreen.V412.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji (Result Evergreen.V412.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji (Result Evergreen.V412.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji (Result Evergreen.V412.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V412.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V412.Discord.HttpError (List ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId, Maybe Evergreen.V412.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Effect.Time.Posix Evergreen.V412.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Result Evergreen.V412.Slack.HttpError ( Evergreen.V412.Slack.User, Maybe Evergreen.V412.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V412.Slack.User (Maybe Evergreen.V412.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V412.Id.SlackGuildOrDmId (Result Evergreen.V412.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V412.Id.SlackGuildOrDmId (Result Evergreen.V412.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V412.Id.SlackGuildOrDmId (Result Evergreen.V412.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V412.Slack.SlackToken, Result Evergreen.V412.Slack.HttpError Evergreen.V412.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Result Evergreen.V412.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (List Evergreen.V412.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Result Evergreen.V412.Slack.HttpError Evergreen.V412.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V412.Slack.HttpError ) ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Discord.UserAuth (Result Evergreen.V412.Discord.HttpError Evergreen.V412.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Result Evergreen.V412.Discord.HttpError Evergreen.V412.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
        (Result
            Evergreen.V412.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId
                    , members : List (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
                    , messages : List Evergreen.V412.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId
                    , { guild : Evergreen.V412.Discord.GatewayGuild
                      , channels : List Evergreen.V412.Discord.Channel
                      , icon : Maybe Evergreen.V412.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (List Evergreen.V412.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V412.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V412.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V412.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V412.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.AttachmentId, Evergreen.V412.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V412.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.AttachmentId, Evergreen.V412.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V412.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V412.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V412.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V412.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (Result Evergreen.V412.Discord.HttpError Evergreen.V412.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Result Evergreen.V412.Discord.HttpError (List Evergreen.V412.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V412.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V412.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V412.DmChannelId.DmChannelId Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V412.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V412.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V412.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V412.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
        (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V412.Discord.HttpError
            { guild : Evergreen.V412.Discord.GatewayGuild
            , channels : List Evergreen.V412.Discord.Channel
            , icon : Maybe Evergreen.V412.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Maybe Evergreen.V412.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Result Evergreen.V412.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V412.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V412.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (List ( Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId, Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId, Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (List ( Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (List ( Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V412.Discord.HttpError (List Evergreen.V412.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V412.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V412.SecretId.SecretId Evergreen.V412.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V412.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V412.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V412.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V412.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Result Evergreen.V412.Discord.HttpError ( Evergreen.V412.Discord.Guild, List Evergreen.V412.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V412.FileStatus.FileHash Int (Maybe (Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) String.Nonempty.NonemptyString
