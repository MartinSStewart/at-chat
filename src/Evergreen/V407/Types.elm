module Evergreen.V407.Types exposing (..)

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
import Evergreen.V407.AiChat
import Evergreen.V407.Audio
import Evergreen.V407.BackendMsgLog
import Evergreen.V407.Call
import Evergreen.V407.ChannelDescription
import Evergreen.V407.ChannelName
import Evergreen.V407.Coord
import Evergreen.V407.CssPixels
import Evergreen.V407.CustomEmoji
import Evergreen.V407.Discord
import Evergreen.V407.DiscordAttachmentId
import Evergreen.V407.DiscordUserData
import Evergreen.V407.DmChannel
import Evergreen.V407.DmChannelId
import Evergreen.V407.Drawing
import Evergreen.V407.Editable
import Evergreen.V407.EmailAddress
import Evergreen.V407.Embed
import Evergreen.V407.Emoji
import Evergreen.V407.Encryption
import Evergreen.V407.FileStatus
import Evergreen.V407.Game
import Evergreen.V407.Go
import Evergreen.V407.GuildName
import Evergreen.V407.Id
import Evergreen.V407.IdArray
import Evergreen.V407.ImageEditor
import Evergreen.V407.ImageViewer
import Evergreen.V407.LinkedAndOtherDiscordUsers
import Evergreen.V407.Local
import Evergreen.V407.LocalState
import Evergreen.V407.Log
import Evergreen.V407.LoginForm
import Evergreen.V407.MembersAndOwner
import Evergreen.V407.Message
import Evergreen.V407.MessageInput
import Evergreen.V407.MessageView
import Evergreen.V407.MuteSettings
import Evergreen.V407.MyUi
import Evergreen.V407.NonemptyDict
import Evergreen.V407.NonemptySet
import Evergreen.V407.OneOrGreater
import Evergreen.V407.OneToOne
import Evergreen.V407.Pages.Admin
import Evergreen.V407.Pagination
import Evergreen.V407.PersonName
import Evergreen.V407.Ports
import Evergreen.V407.Postmark
import Evergreen.V407.Range
import Evergreen.V407.RateLimit
import Evergreen.V407.RecoveryLogin
import Evergreen.V407.RichText
import Evergreen.V407.Route
import Evergreen.V407.Scroll
import Evergreen.V407.SecretId
import Evergreen.V407.SessionIdHash
import Evergreen.V407.SetViewing
import Evergreen.V407.SheepGame
import Evergreen.V407.Slack
import Evergreen.V407.Sticker
import Evergreen.V407.TextEditor
import Evergreen.V407.Thread
import Evergreen.V407.ToBackendLog
import Evergreen.V407.Touch
import Evergreen.V407.TwoFactorAuthentication
import Evergreen.V407.Ui.Anim
import Evergreen.V407.User
import Evergreen.V407.UserAgent
import Evergreen.V407.UserColor
import Evergreen.V407.UserSession
import Evergreen.V407.VisibleMessages
import Evergreen.V407.WordSpellingGame
import Evergreen.V407.X25519
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
    | LoginFormMsg Evergreen.V407.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V407.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V407.Pages.Admin.Msg
    | PressedLogOut Evergreen.V407.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V407.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V407.Route.Route
    | SelectedFilesToAttach ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | PressedImportChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V407.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V407.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V407.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V407.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V407.NonemptyDict.NonemptyDict Int Evergreen.V407.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V407.NonemptyDict.NonemptyDict Int Evergreen.V407.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRoute Evergreen.V407.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V407.NonemptySet.NonemptySet (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V407.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V407.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V407.AiChat.Msg
    | GameMsg Evergreen.V407.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V407.Id.GuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V407.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V407.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V407.Editable.Msg Evergreen.V407.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V407.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) (Maybe Evergreen.V407.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute )
        { fileId : Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute )
        { fileId : Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V407.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V407.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V407.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V407.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V407.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V407.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V407.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | PressedDisableE2ee (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | TypedPrivateKey (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) String
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
    | TextEditorMsg Evergreen.V407.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId
        , otherUserId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V407.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRoute Evergreen.V407.MessageInput.Msg
    | MessageInputMsg Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRoute Evergreen.V407.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V407.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V407.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V407.Range.Range, Evergreen.V407.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V407.Range.Range, Evergreen.V407.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V407.Call.FromJs)
    | VoiceChatMsg Evergreen.V407.Call.Msg
    | PressedChannelHeaderTab Evergreen.V407.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V407.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V407.Audio.LoadError Evergreen.V407.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V407.Route.Route
    | PressedMuteChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V407.Id.AnyGuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V407.Id.AnyGuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) Evergreen.V407.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V407.Encryption.FromJs (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V407.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V407.UserSession.UserSession
    , currentlyViewing : Evergreen.V407.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) Evergreen.V407.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) Evergreen.V407.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId) Evergreen.V407.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Evergreen.V407.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
    , user : Evergreen.V407.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.User.FrontendUser
    , discordUsers : Evergreen.V407.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V407.SessionIdHash.SessionIdHash Evergreen.V407.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V407.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId) Evergreen.V407.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId) Evergreen.V407.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V407.Call.CallId (Evergreen.V407.NonemptyDict.NonemptyDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V407.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V407.Go.PublicGoMatchData Evergreen.V407.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V407.Route.Route
    , windowSize : Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V407.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V407.Audio.LoadError Evergreen.V407.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Encryption.EncryptedData (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.NonemptyDict.NonemptyDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Encryption.EncryptedData (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V407.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V407.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V407.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData) (List Evergreen.V407.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V407.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V407.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRoute String.Nonempty.NonemptyString
    | Local_Slack_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.ChannelName.ChannelName Evergreen.V407.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.ChannelName.ChannelName Evergreen.V407.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V407.GuildName.GuildName (Evergreen.V407.UserSession.ToBeFilledInByBackend (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V407.Id.Viewing_DiscordDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V407.SetViewing.SetViewing
    | Local_SetName Evergreen.V407.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V407.Id.GuildOrDmId (Evergreen.V407.VisibleMessages.PageRequest Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend Evergreen.V407.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V407.Id.GuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.VisibleMessages.PageRequest Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V407.Id.SlackGuildOrDmId (Evergreen.V407.VisibleMessages.PageRequest Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))))
    | Local_Slack_LoadThreadMessages Evergreen.V407.Id.SlackGuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.VisibleMessages.PageRequest Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V407.Id.DiscordGuildOrDmId (Evergreen.V407.VisibleMessages.PageRequest Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V407.Id.DiscordGuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.VisibleMessages.PageRequest Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V407.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V407.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V407.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.QuestionId Evergreen.V407.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V407.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V407.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V407.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V407.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V407.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V407.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V407.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V407.NonemptySet.NonemptySet (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V407.Call.LocalChange
    | Local_Game Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Game.LocalChange
    | Local_Drawing Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Drawing.AnchorType Evergreen.V407.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V407.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V407.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V407.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V407.X25519.PublicKey (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V407.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V407.Id.Viewing_DmId (List ( Evergreen.V407.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V407.FileStatus.FileHash, Evergreen.V407.Encryption.EncryptedData (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V407.Id.Viewing_DmId (Evergreen.V407.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V407.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V407.Id.ThreadRouteWithMessage, Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V407.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V407.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V407.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V407.FileStatus.FileHash) (Evergreen.V407.Encryption.EncryptedData (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))) (Evergreen.V407.Encryption.EncryptedData String) Evergreen.V407.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V407.Id.Viewing_DmId Evergreen.V407.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V407.FileStatus.FileHash) (Evergreen.V407.Encryption.EncryptedData (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    | RepliedToGame Evergreen.V407.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
        , sender : Evergreen.V407.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V407.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
        , threadRoute : Evergreen.V407.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId) Evergreen.V407.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRoute (List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))) (Maybe (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | Server_Slack_UnlinkUser (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
    | Server_Slack_UserLoaded (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Evergreen.V407.UserSession.SlackFrontendUser
    | Server_Slack_AddReactionEmoji (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_Slack_RemoveReactionEmoji (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V407.Id.DiscordGuildOrDmId Evergreen.V407.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))) Evergreen.V407.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId) Evergreen.V407.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.ChannelName.ChannelName Evergreen.V407.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.ChannelName.ChannelName Evergreen.V407.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.User.FrontendUser
    | Server_MemberLeft (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V407.LocalState.JoinGuildError
            { guildId : Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId
            , guild : Evergreen.V407.LocalState.FrontendGuild
            , owner : Evergreen.V407.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V407.Id.Viewing_DiscordDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Maybe Evergreen.V407.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Maybe Evergreen.V407.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V407.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V407.SessionIdHash.SessionIdHash Evergreen.V407.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V407.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V407.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V407.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V407.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V407.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Bool Evergreen.V407.ChannelName.ChannelName (Evergreen.V407.Discord.OptionalData (Maybe String)) (List Evergreen.V407.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
        (Evergreen.V407.NonemptyDict.NonemptyDict
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) Evergreen.V407.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Maybe (Evergreen.V407.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V407.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V407.Log.Log
    | Server_BackupGenerated Evergreen.V407.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V407.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V407.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V407.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V407.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (Evergreen.V407.Discord.OptionalData (Maybe String)) (Evergreen.V407.Discord.OptionalData (Maybe String)) (List Evergreen.V407.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.GuildName.GuildName (Maybe Evergreen.V407.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId) Evergreen.V407.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId) Evergreen.V407.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
        (Evergreen.V407.MembersAndOwner.MembersAndOwner
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.PersonName.PersonName Evergreen.V407.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId) Evergreen.V407.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId) Evergreen.V407.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V407.Call.ServerChange
    | Server_Game (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Game.LocalChange
    | Server_Drawing (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Drawing.AnchorType Evergreen.V407.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V407.Id.Viewing_DmId ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V407.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V407.Id.Viewing_DmId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | Server_E2eeAccepted Evergreen.V407.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
        , sender : Evergreen.V407.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V407.Id.Viewing_DmId
        , content : Evergreen.V407.Encryption.EncryptedData (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
        , threadRoute : Evergreen.V407.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V407.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.Viewing_DmId Evergreen.V407.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V407.FileStatus.FileHash) (Evergreen.V407.Encryption.EncryptedData (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V407.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V407.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V407.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V407.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V407.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V407.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V407.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V407.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V407.Id.AnyGuildOrDmId Evergreen.V407.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V407.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels) (Maybe Evergreen.V407.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V407.SheepGame.Input (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels) (Maybe Evergreen.V407.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V407.Id.GuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V407.Id.GuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.NonemptySet.NonemptySet Int))
    }


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result Evergreen.V407.Slack.HttpError String))


type alias UserOptionsModel =
    { name : Evergreen.V407.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V407.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V407.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , threadRoute : Evergreen.V407.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V407.Encryption.BytesHash
    , id : Evergreen.V407.Id.Viewing_DmId
    , senderId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , threadRoute : Evergreen.V407.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V407.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V407.Id.Viewing_DmId
    , messages : List Evergreen.V407.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V407.Id.Viewing_DmId
    , messages : List ( Evergreen.V407.Id.ThreadRouteWithMessage, Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V407.Id.Viewing_DmId
    , threadRoute : Evergreen.V407.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute )
    , fileId : Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V407.Id.Id Evergreen.V407.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V407.Id.Id Evergreen.V407.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V407.Id.Id Evergreen.V407.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V407.Id.Id Evergreen.V407.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V407.Id.Id Evergreen.V407.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V407.Local.Local LocalMsg Evergreen.V407.LocalState.LocalState
    , admin : Evergreen.V407.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V407.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V407.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.Message.RepliedTo Evergreen.V407.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V407.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V407.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V407.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.ThreadRoute ) (Evergreen.V407.NonemptyDict.NonemptyDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V407.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V407.Scroll.ScrollPosition
    , textEditor : Evergreen.V407.TextEditor.Model
    , profilePictureEditor : Evergreen.V407.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId, Evergreen.V407.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V407.Emoji.Model
    , voiceChat : Evergreen.V407.Call.Model
    , games : SeqDict.SeqDict Evergreen.V407.Id.GuildOrDmId Evergreen.V407.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V407.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V407.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V407.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V407.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V407.Range.Range
                , direction : Evergreen.V407.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V407.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V407.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V407.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V407.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V407.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V407.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V407.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V407.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V407.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V407.MyUi.LastCopy
    , drag : Evergreen.V407.Touch.Drag
    , dragPrevious : Evergreen.V407.Touch.Drag
    , aiChatModel : Evergreen.V407.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V407.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V407.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V407.Audio.LoadError Evergreen.V407.Audio.Source
    , startupData : Evergreen.V407.Ports.StartupData
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
    Evergreen.V407.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V407.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V407.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V407.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
    , messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.Slack.Id Evergreen.V407.Slack.MessageId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.SlackBackendThread
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId) SlackBackendChannel
    }


type alias SlackBasicUserData =
    { user : Evergreen.V407.Slack.User
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    }


type alias SlackLinkedUser =
    { user : Evergreen.V407.Slack.User
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , linkedTo : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V407.Slack.SlackToken
    , cookie : Evergreen.V407.Slack.SlackCookie
    , websocket : Maybe Effect.Websocket.Connection
    , reconnect :
        { failedAttempts : Int
        , seed : Int
        }
    }


type SlackUserData
    = SlackBasicData SlackBasicUserData
    | SlackFullData SlackLinkedUser


type alias SlackFileData =
    { fileHash : Evergreen.V407.FileStatus.FileHash
    , metadata : Maybe Evergreen.V407.FileStatus.FileMetadata
    }


type alias SlackDmChannel =
    { teamId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId
    , members : Evergreen.V407.NonemptySet.NonemptySet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
    , messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.Slack.Id Evergreen.V407.Slack.MessageId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.SlackBackendThread
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V407.FileStatus.FileHash
    , metadata : Maybe Evergreen.V407.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId, Evergreen.V407.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId, Evergreen.V407.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V407.DmChannelId.DmChannelId, Evergreen.V407.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId, Evergreen.V407.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId, Evergreen.V407.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId, Evergreen.V407.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V407.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V407.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V407.LocalState.BackupContents
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
    { users : Evergreen.V407.NonemptyDict.NonemptyDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V407.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V407.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V407.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V407.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V407.DmChannelId.DmChannelId Evergreen.V407.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) Evergreen.V407.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) SlackUserData
    , slackFiles : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.FileId) SlackFileData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId) SlackDmChannel
    , orphanedSlackWorkspacesLastHour : SeqSet.SeqSet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
    , orphanedSlackDmChannelsLastHour : SeqSet.SeqSet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId)
    , files : SeqDict.SeqDict Evergreen.V407.FileStatus.FileHash Evergreen.V407.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V407.FileStatus.FileHash
    , privateVapidKey : Evergreen.V407.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V407.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId, Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V407.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V407.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V407.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V407.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.LocalState.LoadingDiscordChannel Evergreen.V407.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , slackLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V407.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V407.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V407.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId) Evergreen.V407.Sticker.StickerData
    , discordStickers : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.Discord.Id Evergreen.V407.Discord.StickerId) (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId) Evergreen.V407.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V407.OneToOne.OneToOne Evergreen.V407.RichText.DiscordCustomEmojiIdAndName (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V407.Postmark.ApiKey
    , serverSecret : Evergreen.V407.SecretId.SecretId Evergreen.V407.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V407.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.GamePublicId) ( Evergreen.V407.DmChannelId.GuildOrFullDmId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V407.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V407.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId, String ) Int
    , pendingSlackUserLookups : SeqSet.SeqSet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Duration.Duration
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V407.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.Id.ThreadRoute (Maybe Evergreen.V407.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V407.DmChannelId.DmChannelId Evergreen.V407.Id.ThreadRoute (Maybe Evergreen.V407.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V407.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V407.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V407.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V407.UserAgent.UserAgent
    | AdminToBackend Evergreen.V407.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V407.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V407.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V407.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V407.PersonName.PersonName Evergreen.V407.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V407.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V407.Discord.UserAuth
    | LinkSlackRequest Evergreen.V407.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V407.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V407.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V407.EmailAddress.EmailAddress (Result Evergreen.V407.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V407.EmailAddress.EmailAddress (Result Evergreen.V407.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V407.EmailAddress.EmailAddress (Result Evergreen.V407.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V407.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMaybeMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Result Evergreen.V407.Discord.HttpError Evergreen.V407.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V407.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Result Evergreen.V407.Discord.HttpError Evergreen.V407.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V407.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Id.ThreadRoute String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))) (Result Evergreen.V407.Slack.HttpError (Evergreen.V407.Slack.Id Evergreen.V407.Slack.MessageId))
    | SlackWebsocketCreatedHandle (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) (Result Evergreen.V407.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) (Result Evergreen.V407.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) (Result Evergreen.V407.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) (Result Evergreen.V407.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji (Result Evergreen.V407.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji (Result Evergreen.V407.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji (Result Evergreen.V407.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji (Result Evergreen.V407.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V407.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V407.Discord.HttpError (List ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId, Maybe Evergreen.V407.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Effect.Time.Posix Evergreen.V407.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackUser (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Result Evergreen.V407.Slack.HttpError ( Evergreen.V407.Slack.User, Maybe Evergreen.V407.FileStatus.FileHash ))
    | SlackMessageFilesUploaded (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Evergreen.V407.Slack.WebsocketEvent (SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.FileId) SlackFileData)
    | SlackChangedReaction Effect.Time.Posix Evergreen.V407.Id.SlackGuildOrDmId (Result Evergreen.V407.Slack.HttpError ())
    | SlackDeletedMessage Effect.Time.Posix Evergreen.V407.Id.SlackGuildOrDmId (Result Evergreen.V407.Slack.HttpError ())
    | SlackEditedMessage Effect.Time.Posix Evergreen.V407.Id.SlackGuildOrDmId (Result Evergreen.V407.Slack.HttpError ())
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V407.Slack.SlackToken, Result Evergreen.V407.Slack.HttpError Evergreen.V407.Slack.UserBoot ))
    | LinkSlackUserStep2
        Effect.Time.Posix
        (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
        (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
        (Result
            Evergreen.V407.Slack.HttpError
            { channels : List ( Evergreen.V407.Slack.Channel, Evergreen.V407.Slack.History )
            , dmChannels : List ( Evergreen.V407.Slack.DmChannel, Evergreen.V407.Slack.History )
            , users : List ( Evergreen.V407.Slack.User, Maybe Evergreen.V407.FileStatus.FileHash )
            , selfIcon : Maybe Evergreen.V407.FileStatus.FileHash
            , workspaceIcon : Maybe Evergreen.V407.FileStatus.FileHash
            , files : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.FileId) SlackFileData
            }
        )
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Discord.UserAuth (Result Evergreen.V407.Discord.HttpError Evergreen.V407.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Result Evergreen.V407.Discord.HttpError Evergreen.V407.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
        (Result
            Evergreen.V407.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId
                    , members : List (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
                    , messages : List Evergreen.V407.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId
                    , { guild : Evergreen.V407.Discord.GatewayGuild
                      , channels : List Evergreen.V407.Discord.Channel
                      , icon : Maybe Evergreen.V407.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (List Evergreen.V407.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V407.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V407.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V407.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V407.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.AttachmentId, Evergreen.V407.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V407.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.AttachmentId, Evergreen.V407.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V407.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V407.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V407.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V407.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (Result Evergreen.V407.Discord.HttpError Evergreen.V407.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Result Evergreen.V407.Discord.HttpError (List Evergreen.V407.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V407.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V407.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V407.DmChannelId.DmChannelId Evergreen.V407.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V407.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V407.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V407.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
        (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V407.Discord.HttpError
            { guild : Evergreen.V407.Discord.GatewayGuild
            , channels : List Evergreen.V407.Discord.Channel
            , icon : Maybe Evergreen.V407.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Maybe Evergreen.V407.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Result Evergreen.V407.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V407.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V407.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (List ( Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId, Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId, Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (List ( Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V407.Discord.HttpError (List Evergreen.V407.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V407.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V407.SecretId.SecretId Evergreen.V407.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V407.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V407.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V407.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V407.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Result Evergreen.V407.Discord.HttpError ( Evergreen.V407.Discord.Guild, List Evergreen.V407.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V407.FileStatus.FileHash Int (Maybe (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Call.CallId
