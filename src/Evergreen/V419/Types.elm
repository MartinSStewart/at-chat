module Evergreen.V419.Types exposing (..)

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
import Evergreen.V419.AiChat
import Evergreen.V419.Audio
import Evergreen.V419.BackendMsgLog
import Evergreen.V419.Call
import Evergreen.V419.ChannelDescription
import Evergreen.V419.ChannelName
import Evergreen.V419.Coord
import Evergreen.V419.CssPixels
import Evergreen.V419.CustomEmoji
import Evergreen.V419.Discord
import Evergreen.V419.DiscordAttachmentId
import Evergreen.V419.DiscordUserData
import Evergreen.V419.DmChannel
import Evergreen.V419.DmChannelId
import Evergreen.V419.Drawing
import Evergreen.V419.Editable
import Evergreen.V419.EmailAddress
import Evergreen.V419.Embed
import Evergreen.V419.Emoji
import Evergreen.V419.Encryption
import Evergreen.V419.FileStatus
import Evergreen.V419.Game
import Evergreen.V419.Go
import Evergreen.V419.GuildName
import Evergreen.V419.Id
import Evergreen.V419.IdArray
import Evergreen.V419.ImageEditor
import Evergreen.V419.ImageViewer
import Evergreen.V419.LinkedAndOtherDiscordUsers
import Evergreen.V419.Local
import Evergreen.V419.LocalState
import Evergreen.V419.Log
import Evergreen.V419.LoginForm
import Evergreen.V419.MembersAndOwner
import Evergreen.V419.Message
import Evergreen.V419.MessageInput
import Evergreen.V419.MessageView
import Evergreen.V419.MuteSettings
import Evergreen.V419.MyUi
import Evergreen.V419.NonemptyDict
import Evergreen.V419.NonemptySet
import Evergreen.V419.OneOrGreater
import Evergreen.V419.OneToOne
import Evergreen.V419.Pages.Admin
import Evergreen.V419.Pagination
import Evergreen.V419.PersonName
import Evergreen.V419.Ports
import Evergreen.V419.Postmark
import Evergreen.V419.Range
import Evergreen.V419.RateLimit
import Evergreen.V419.RecoveryLogin
import Evergreen.V419.RichText
import Evergreen.V419.Route
import Evergreen.V419.Scroll
import Evergreen.V419.SecretId
import Evergreen.V419.SessionIdHash
import Evergreen.V419.SetViewing
import Evergreen.V419.SheepGame
import Evergreen.V419.Slack
import Evergreen.V419.Sticker
import Evergreen.V419.TextEditor
import Evergreen.V419.Thread
import Evergreen.V419.ToBackendLog
import Evergreen.V419.Touch
import Evergreen.V419.TwoFactorAuthentication
import Evergreen.V419.Ui.Anim
import Evergreen.V419.User
import Evergreen.V419.UserAgent
import Evergreen.V419.UserColor
import Evergreen.V419.UserSession
import Evergreen.V419.VisibleMessages
import Evergreen.V419.WordSpellingGame
import Evergreen.V419.X25519
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
    | LoginFormMsg Evergreen.V419.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V419.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V419.Pages.Admin.Msg
    | PressedLogOut Evergreen.V419.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V419.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V419.Route.Route
    | SelectedFilesToAttach ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | PressedImportChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V419.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V419.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V419.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V419.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V419.NonemptyDict.NonemptyDict Int Evergreen.V419.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V419.NonemptyDict.NonemptyDict Int Evergreen.V419.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRoute Evergreen.V419.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V419.NonemptySet.NonemptySet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V419.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V419.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V419.AiChat.Msg
    | GameMsg Evergreen.V419.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V419.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V419.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V419.Editable.Msg Evergreen.V419.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V419.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) (Maybe Evergreen.V419.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute )
        { fileId : Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute )
        { fileId : Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V419.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V419.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V419.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V419.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V419.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.User.NotificationLevel
    | PressedSlackWorkspaceNotificationLevel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V419.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V419.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | PressedDisableE2ee (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | TypedPrivateKey (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) String
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
    | TextEditorMsg Evergreen.V419.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedSlackAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId
        , otherUserId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V419.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRoute Evergreen.V419.MessageInput.Msg
    | MessageInputMsg Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRoute Evergreen.V419.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V419.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V419.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V419.Range.Range, Evergreen.V419.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V419.Range.Range, Evergreen.V419.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V419.Call.FromJs)
    | VoiceChatMsg Evergreen.V419.Call.Msg
    | PressedChannelHeaderTab Evergreen.V419.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V419.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V419.Audio.LoadError Evergreen.V419.Audio.Source)
    | PressedShowSearchOverlay
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V419.Route.Route
    | PressedMuteChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMuteSlackWorkspace (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMuteSlackChannel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | PressedMuteSlackThread (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V419.Id.AnyGuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V419.Id.AnyGuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) Evergreen.V419.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V419.Encryption.FromJs (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedRemoveSlackTeam (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    | PressedReloadSlackUser (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V419.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V419.UserSession.UserSession
    , currentlyViewing : Evergreen.V419.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) Evergreen.V419.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId) Evergreen.V419.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    , user : Evergreen.V419.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.User.FrontendUser
    , discordUsers : Evergreen.V419.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V419.SessionIdHash.SessionIdHash Evergreen.V419.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V419.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId) Evergreen.V419.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId) Evergreen.V419.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V419.Call.CallId (Evergreen.V419.NonemptyDict.NonemptyDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V419.Call.RemoteCallData)
    , callRecordings : SeqDict.SeqDict Evergreen.V419.Call.CallId Evergreen.V419.Call.RecordingStatus
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
    | PublicGoMatch_Loaded Evergreen.V419.Go.PublicGoMatchData Evergreen.V419.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V419.Route.Route
    , windowSize : Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V419.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V419.Audio.LoadError Evergreen.V419.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Encryption.EncryptedData (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.NonemptyDict.NonemptyDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Encryption.EncryptedData (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V419.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V419.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V419.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData) (List Evergreen.V419.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V419.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V419.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRoute String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData)
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    | Local_Slack_ReloadUser (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.ChannelName.ChannelName Evergreen.V419.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.ChannelName.ChannelName Evergreen.V419.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V419.GuildName.GuildName (Evergreen.V419.UserSession.ToBeFilledInByBackend (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V419.Id.Viewing_DiscordDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V419.SetViewing.SetViewing
    | Local_SetName Evergreen.V419.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.VisibleMessages.PageRequest Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend Evergreen.V419.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.VisibleMessages.PageRequest Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V419.Id.SlackGuildOrDmId (Evergreen.V419.VisibleMessages.PageRequest Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V419.Id.SlackGuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.VisibleMessages.PageRequest Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V419.Id.DiscordGuildOrDmId (Evergreen.V419.VisibleMessages.PageRequest Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V419.Id.DiscordGuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.VisibleMessages.PageRequest Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.User.NotificationLevel
    | Local_SetSlackWorkspaceNotificationLevel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V419.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V419.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V419.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.QuestionId Evergreen.V419.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V419.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V419.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V419.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V419.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_LinkSlackAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V419.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V419.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V419.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V419.NonemptySet.NonemptySet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V419.Call.LocalChange
    | Local_Game Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Game.LocalChange
    | Local_Drawing Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Drawing.AnchorType Evergreen.V419.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteSlackWorkspace (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteSlackChannel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | Local_SetMuteSlackThread (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V419.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V419.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V419.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V419.X25519.PublicKey (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V419.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V419.Id.Viewing_DmId (List ( Evergreen.V419.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V419.FileStatus.FileHash, Evergreen.V419.Encryption.EncryptedData (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V419.Id.Viewing_DmId (Evergreen.V419.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V419.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V419.Id.ThreadRouteWithMessage, Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V419.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V419.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V419.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V419.FileStatus.FileHash) (Evergreen.V419.Encryption.EncryptedData (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))) (Evergreen.V419.Encryption.EncryptedData String) Evergreen.V419.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V419.Id.Viewing_DmId Evergreen.V419.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V419.FileStatus.FileHash) (Evergreen.V419.Encryption.EncryptedData (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    | RepliedToGame Evergreen.V419.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
        , sender : Evergreen.V419.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V419.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
        , threadRoute : Evergreen.V419.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId) Evergreen.V419.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData) (Maybe (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.UserSession.SlackFrontendUser
    | Server_Slack_WorkspaceRenamed (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) String
    | Server_Slack_ChannelRenamed (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) Evergreen.V419.ChannelName.ChannelName
    | Server_Slack_NeedsAuthAgain (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    | Server_Slack_GotMessageEmbed Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V419.Embed.EmbedData )
    | Server_Slack_LinkedUserLoaded
        (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
        (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
        { workspaces : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.LocalState.SlackFrontendWorkspace
        , dmChannels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId) Evergreen.V419.LocalState.SlackFrontendDmChannel
        , users : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.UserSession.SlackFrontendUser
        , customEmojis : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId) Evergreen.V419.CustomEmoji.CustomEmojiData
        , markNewDmsAsViewed : Bool
        }
    | Server_Slack_CustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId) Evergreen.V419.CustomEmoji.CustomEmojiData)
    | Server_Slack_CustomEmojiAdded (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId) Evergreen.V419.CustomEmoji.CustomEmojiData
    | Server_Slack_AddReactionEmoji (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V419.Id.DiscordGuildOrDmId Evergreen.V419.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))) Evergreen.V419.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId) Evergreen.V419.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.ChannelName.ChannelName Evergreen.V419.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.ChannelName.ChannelName Evergreen.V419.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.User.FrontendUser
    | Server_MemberLeft (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V419.LocalState.JoinGuildError
            { guildId : Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId
            , guild : Evergreen.V419.LocalState.FrontendGuild
            , owner : Evergreen.V419.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_CallRecordingStarted Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Effect.Time.Posix (Evergreen.V419.NonemptySet.NonemptySet (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    | Server_CallRecordingUploadProgress Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.CallRecordingFile (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    | Server_CallRecordingUploadFinished Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | Server_CallRecordingZipBuilt Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Message.CallRecordingZip
    | Server_RemoveReactionEmoji (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V419.Id.Viewing_DiscordDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Maybe Evergreen.V419.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Maybe Evergreen.V419.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.User.NotificationLevel
    | Server_SetSlackWorkspaceNotificationLevel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V419.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V419.SessionIdHash.SessionIdHash Evergreen.V419.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V419.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V419.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V419.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V419.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V419.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Bool Evergreen.V419.ChannelName.ChannelName (Evergreen.V419.Discord.OptionalData (Maybe String)) (List Evergreen.V419.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
        (Evergreen.V419.NonemptyDict.NonemptyDict
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) Evergreen.V419.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Maybe (Evergreen.V419.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V419.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V419.Log.Log
    | Server_BackupGenerated Evergreen.V419.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V419.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V419.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V419.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V419.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (Evergreen.V419.Discord.OptionalData (Maybe String)) (Evergreen.V419.Discord.OptionalData (Maybe String)) (List Evergreen.V419.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.GuildName.GuildName (Maybe Evergreen.V419.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId) Evergreen.V419.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId) Evergreen.V419.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
        (Evergreen.V419.MembersAndOwner.MembersAndOwner
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.PersonName.PersonName Evergreen.V419.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId) Evergreen.V419.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId) Evergreen.V419.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V419.Call.ServerChange
    | Server_Game (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Game.LocalChange
    | Server_Drawing (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Drawing.AnchorType Evergreen.V419.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteSlackWorkspace (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteSlackChannel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) Evergreen.V419.MuteSettings.IsMuted
    | Server_SetMuteSlackThread (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V419.Id.Viewing_DmId ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V419.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V419.Id.Viewing_DmId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | Server_E2eeAccepted Evergreen.V419.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
        , sender : Evergreen.V419.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V419.Id.Viewing_DmId
        , content : Evergreen.V419.Encryption.EncryptedData (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
        , threadRoute : Evergreen.V419.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V419.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.Viewing_DmId Evergreen.V419.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V419.FileStatus.FileHash) (Evergreen.V419.Encryption.EncryptedData (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V419.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V419.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V419.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V419.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V419.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V419.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V419.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V419.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V419.Id.AnyGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V419.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels) (Maybe Evergreen.V419.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V419.SheepGame.Input (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels) (Maybe Evergreen.V419.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V419.Id.GuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.NonemptySet.NonemptySet Int))
    }


type LinkSlackWorkspaceError
    = SlackWorkspaceHttpError Evergreen.V419.Slack.HttpError
    | SlackLinkLimitReached


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result LinkSlackWorkspaceError String))


type alias UserOptionsModel =
    { name : Evergreen.V419.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V419.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , removedSlackTeams : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V419.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , threadRoute : Evergreen.V419.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V419.Encryption.BytesHash
    , id : Evergreen.V419.Id.Viewing_DmId
    , senderId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , threadRoute : Evergreen.V419.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V419.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V419.Id.Viewing_DmId
    , messages : List Evergreen.V419.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V419.Id.Viewing_DmId
    , messages : List ( Evergreen.V419.Id.ThreadRouteWithMessage, Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V419.Id.Viewing_DmId
    , threadRoute : Evergreen.V419.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute )
    , fileId : Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V419.Id.Id Evergreen.V419.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V419.Id.Id Evergreen.V419.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V419.Id.Id Evergreen.V419.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V419.Id.Id Evergreen.V419.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V419.Id.Id Evergreen.V419.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V419.Local.Local LocalMsg Evergreen.V419.LocalState.LocalState
    , admin : Evergreen.V419.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V419.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V419.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.Message.RepliedTo Evergreen.V419.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V419.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V419.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V419.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.ThreadRoute ) (Evergreen.V419.NonemptyDict.NonemptyDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V419.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V419.Scroll.ScrollPosition
    , textEditor : Evergreen.V419.TextEditor.Model
    , profilePictureEditor : Evergreen.V419.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId, Evergreen.V419.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V419.Emoji.Model
    , voiceChat : Evergreen.V419.Call.Model
    , games : SeqDict.SeqDict Evergreen.V419.Id.GuildOrDmId Evergreen.V419.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V419.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V419.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V419.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V419.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V419.Range.Range
                , direction : Evergreen.V419.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V419.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V419.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V419.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V419.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V419.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V419.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V419.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V419.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V419.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V419.MyUi.LastCopy
    , drag : Evergreen.V419.Touch.Drag
    , dragPrevious : Evergreen.V419.Touch.Drag
    , aiChatModel : Evergreen.V419.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V419.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V419.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V419.Audio.LoadError Evergreen.V419.Audio.Source
    , startupData : Evergreen.V419.Ports.StartupData
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
    Evergreen.V419.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V419.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V419.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V419.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    , messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.Slack.Id Evergreen.V419.Slack.MessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) SlackBackendChannel
    , customEmojis : SeqDict.SeqDict String (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    }


type alias SlackBasicUserData =
    { user : Evergreen.V419.Slack.User
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V419.Slack.User
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , linkedTo : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V419.Slack.SlackToken
    , cookie : Evergreen.V419.Slack.SlackCookie
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
    { fileHash : Evergreen.V419.FileStatus.FileHash
    , metadata : Maybe Evergreen.V419.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId
    , members : Evergreen.V419.NonemptySet.NonemptySet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    , messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.Slack.Id Evergreen.V419.Slack.MessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V419.FileStatus.FileHash
    , metadata : Maybe Evergreen.V419.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId, Evergreen.V419.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId, Evergreen.V419.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V419.DmChannelId.DmChannelId, Evergreen.V419.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId, Evergreen.V419.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId, Evergreen.V419.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId, Evergreen.V419.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V419.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V419.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V419.LocalState.BackupContents
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
    { users : Evergreen.V419.NonemptyDict.NonemptyDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V419.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V419.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V419.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V419.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V419.DmChannelId.DmChannelId Evergreen.V419.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) Evergreen.V419.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V419.FileStatus.FileHash Evergreen.V419.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V419.FileStatus.FileHash
    , privateVapidKey : Evergreen.V419.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    , textEditor : Evergreen.V419.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId, Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V419.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V419.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V419.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V419.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.LocalState.LoadingDiscordChannel Evergreen.V419.LocalState.DiscordChannelReload)
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
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V419.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V419.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V419.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId) Evergreen.V419.Sticker.StickerData
    , discordStickers : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.Discord.Id Evergreen.V419.Discord.StickerId) (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId) Evergreen.V419.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V419.OneToOne.OneToOne Evergreen.V419.RichText.DiscordCustomEmojiIdAndName (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V419.Postmark.ApiKey
    , serverSecret : Evergreen.V419.SecretId.SecretId Evergreen.V419.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V419.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.GamePublicId) ( Evergreen.V419.DmChannelId.GuildOrFullDmId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V419.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V419.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    , refreshingSlackConversations : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Duration.Duration
    , callRecordings : SeqDict.SeqDict Evergreen.V419.Call.SharedCallId Evergreen.V419.Call.RecordingStatus
    }


type alias FrontendMsg =
    Evergreen.V419.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.Id.ThreadRoute (Maybe Evergreen.V419.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V419.DmChannelId.DmChannelId Evergreen.V419.Id.ThreadRoute (Maybe Evergreen.V419.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V419.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V419.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V419.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V419.UserAgent.UserAgent
    | AdminToBackend Evergreen.V419.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V419.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V419.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V419.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V419.PersonName.PersonName Evergreen.V419.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V419.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V419.Discord.UserAuth
    | LinkSlackRequest Evergreen.V419.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V419.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V419.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
        { fileName : String
        , json : String
        }


type alias LoadedSlackWorkspace =
    { channels : List ( Evergreen.V419.Slack.Channel, Evergreen.V419.Slack.History )
    , dmChannels : List ( Evergreen.V419.Slack.DmChannel, Evergreen.V419.Slack.History )
    , users : List ( Evergreen.V419.Slack.User, Maybe Evergreen.V419.FileStatus.FileHash )
    , selfIcon : Maybe Evergreen.V419.FileStatus.FileHash
    , workspaceIcon : Maybe Evergreen.V419.FileStatus.FileHash
    , files : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.FileId) SlackFileData
    , customEmojis : List ( String, Evergreen.V419.Slack.CustomEmojiSource )
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V419.EmailAddress.EmailAddress (Result Evergreen.V419.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | RecordingRequestTick Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V419.EmailAddress.EmailAddress (Result Evergreen.V419.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V419.EmailAddress.EmailAddress (Result Evergreen.V419.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V419.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMaybeMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Result Evergreen.V419.Discord.HttpError Evergreen.V419.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V419.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Result Evergreen.V419.Discord.HttpError Evergreen.V419.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V419.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData) (Result Evergreen.V419.Slack.HttpError ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.MessageId, List ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.FileId, Evergreen.V419.FileStatus.FileData ) ))
    | SlackWebsocketCreatedHandle (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) (Result Evergreen.V419.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) (Result Evergreen.V419.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) (Result Evergreen.V419.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) (Result Evergreen.V419.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji (Result Evergreen.V419.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji (Result Evergreen.V419.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji (Result Evergreen.V419.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji (Result Evergreen.V419.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V419.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V419.Discord.HttpError (List ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId, Maybe Evergreen.V419.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Effect.Time.Posix Evergreen.V419.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Result Evergreen.V419.Slack.HttpError ( Evergreen.V419.Slack.User, Maybe Evergreen.V419.FileStatus.FileHash ))
    | GotChangedSlackUser Evergreen.V419.Slack.User (Maybe Evergreen.V419.FileStatus.FileHash)
    | SlackMessageFilesUploaded (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V419.Id.SlackGuildOrDmId (Result Evergreen.V419.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V419.Id.SlackGuildOrDmId (Result Evergreen.V419.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V419.Id.SlackGuildOrDmId (Result Evergreen.V419.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V419.Slack.SlackToken, Result Evergreen.V419.Slack.HttpError Evergreen.V419.Slack.UserBoot ))
    | LinkSlackUserStep2 Effect.Time.Posix (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Result Evergreen.V419.Slack.HttpError LoadedSlackWorkspace)
    | CaughtUpSlackMessages (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (List Evergreen.V419.Slack.WebsocketEvent)
    | CheckedSlackAuth (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Result Evergreen.V419.Slack.HttpError Evergreen.V419.Slack.UserBoot)
    | RefreshedSlackConversations (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Result ( Effect.Time.Posix, Evergreen.V419.Slack.HttpError ) ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId, LoadedSlackWorkspace ))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Discord.UserAuth (Result Evergreen.V419.Discord.HttpError Evergreen.V419.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Result Evergreen.V419.Discord.HttpError Evergreen.V419.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
        (Result
            Evergreen.V419.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId
                    , members : List (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
                    , messages : List Evergreen.V419.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId
                    , { guild : Evergreen.V419.Discord.GatewayGuild
                      , channels : List Evergreen.V419.Discord.Channel
                      , icon : Maybe Evergreen.V419.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (List Evergreen.V419.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V419.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V419.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V419.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V419.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.AttachmentId, Evergreen.V419.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V419.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.AttachmentId, Evergreen.V419.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V419.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V419.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V419.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V419.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (Result Evergreen.V419.Discord.HttpError Evergreen.V419.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Result Evergreen.V419.Discord.HttpError (List Evergreen.V419.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V419.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V419.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V419.DmChannelId.DmChannelId Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V419.Embed.EmbedData )
    | SlackGotMessageEmbed Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V419.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V419.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V419.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
        (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V419.Discord.HttpError
            { guild : Evergreen.V419.Discord.GatewayGuild
            , channels : List Evergreen.V419.Discord.Channel
            , icon : Maybe Evergreen.V419.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Maybe Evergreen.V419.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Result Evergreen.V419.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V419.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V419.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (List ( Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId, Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId, Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (List ( Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotSlackCustomEmojis (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (List ( Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V419.Discord.HttpError (List Evergreen.V419.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V419.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V419.SecretId.SecretId Evergreen.V419.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V419.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V419.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V419.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V419.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Result Evergreen.V419.Discord.HttpError ( Evergreen.V419.Discord.Guild, List Evergreen.V419.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V419.FileStatus.FileHash Int (Maybe (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Call.CallId
    | Rpc_NotifyAdmins Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) String.Nonempty.NonemptyString
    | Rpc_RecordingUploadProgress Evergreen.V419.Call.SharedCallId Effect.Time.Posix (Evergreen.V419.Message.CallRecordingFile (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    | Rpc_RecordingUploadFinished Evergreen.V419.Call.SharedCallId Effect.Time.Posix (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | Rpc_RecordingZipBuilt Evergreen.V419.Call.SharedCallId Effect.Time.Posix Evergreen.V419.Message.CallRecordingZip
