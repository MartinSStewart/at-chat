module Evergreen.V405.Types exposing (..)

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
import Evergreen.V405.AiChat
import Evergreen.V405.Audio
import Evergreen.V405.BackendMsgLog
import Evergreen.V405.Call
import Evergreen.V405.ChannelDescription
import Evergreen.V405.ChannelName
import Evergreen.V405.Coord
import Evergreen.V405.CssPixels
import Evergreen.V405.CustomEmoji
import Evergreen.V405.Discord
import Evergreen.V405.DiscordAttachmentId
import Evergreen.V405.DiscordUserData
import Evergreen.V405.DmChannel
import Evergreen.V405.DmChannelId
import Evergreen.V405.Drawing
import Evergreen.V405.Editable
import Evergreen.V405.EmailAddress
import Evergreen.V405.Embed
import Evergreen.V405.Emoji
import Evergreen.V405.Encryption
import Evergreen.V405.FileStatus
import Evergreen.V405.Game
import Evergreen.V405.Go
import Evergreen.V405.GuildName
import Evergreen.V405.Id
import Evergreen.V405.IdArray
import Evergreen.V405.ImageEditor
import Evergreen.V405.ImageViewer
import Evergreen.V405.LinkedAndOtherDiscordUsers
import Evergreen.V405.Local
import Evergreen.V405.LocalState
import Evergreen.V405.Log
import Evergreen.V405.LoginForm
import Evergreen.V405.MembersAndOwner
import Evergreen.V405.Message
import Evergreen.V405.MessageInput
import Evergreen.V405.MessageView
import Evergreen.V405.MuteSettings
import Evergreen.V405.MyUi
import Evergreen.V405.NonemptyDict
import Evergreen.V405.NonemptySet
import Evergreen.V405.OneOrGreater
import Evergreen.V405.OneToOne
import Evergreen.V405.Pages.Admin
import Evergreen.V405.Pagination
import Evergreen.V405.PersonName
import Evergreen.V405.Ports
import Evergreen.V405.Postmark
import Evergreen.V405.Range
import Evergreen.V405.RateLimit
import Evergreen.V405.RecoveryLogin
import Evergreen.V405.RichText
import Evergreen.V405.Route
import Evergreen.V405.Scroll
import Evergreen.V405.SecretId
import Evergreen.V405.SessionIdHash
import Evergreen.V405.SetViewing
import Evergreen.V405.SheepGame
import Evergreen.V405.Slack
import Evergreen.V405.Sticker
import Evergreen.V405.TextEditor
import Evergreen.V405.ToBackendLog
import Evergreen.V405.Touch
import Evergreen.V405.TwoFactorAuthentication
import Evergreen.V405.Ui.Anim
import Evergreen.V405.User
import Evergreen.V405.UserAgent
import Evergreen.V405.UserColor
import Evergreen.V405.UserSession
import Evergreen.V405.VisibleMessages
import Evergreen.V405.WordSpellingGame
import Evergreen.V405.X25519
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
    | LoginFormMsg Evergreen.V405.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V405.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V405.Pages.Admin.Msg
    | PressedLogOut Evergreen.V405.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V405.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V405.Route.Route
    | SelectedFilesToAttach ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | PressedImportChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V405.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V405.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V405.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V405.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V405.NonemptyDict.NonemptyDict Int Evergreen.V405.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V405.NonemptyDict.NonemptyDict Int Evergreen.V405.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRoute Evergreen.V405.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V405.NonemptySet.NonemptySet (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V405.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V405.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V405.AiChat.Msg
    | GameMsg Evergreen.V405.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V405.Id.GuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V405.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V405.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V405.Editable.Msg Evergreen.V405.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V405.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) (Maybe Evergreen.V405.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute )
        { fileId : Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute )
        { fileId : Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage Evergreen.V405.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V405.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V405.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V405.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V405.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V405.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V405.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V405.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | PressedDisableE2ee (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | TypedPrivateKey (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) String
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
    | TextEditorMsg Evergreen.V405.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId
        , otherUserId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V405.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRoute Evergreen.V405.MessageInput.Msg
    | MessageInputMsg Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRoute Evergreen.V405.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V405.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V405.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V405.Range.Range, Evergreen.V405.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V405.Range.Range, Evergreen.V405.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V405.Call.FromJs)
    | VoiceChatMsg Evergreen.V405.Call.Msg
    | PressedChannelHeaderTab Evergreen.V405.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V405.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V405.Audio.LoadError Evergreen.V405.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V405.Route.Route
    | PressedMuteChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V405.Id.AnyGuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V405.Id.AnyGuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) Evergreen.V405.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V405.Encryption.FromJs (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))))
    | TypedSlackCookie String
    | TypedSlackTeamsJson String
    | PressedSubmitSlackData
    | PressedUnlinkSlackUser (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V405.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V405.UserSession.UserSession
    , currentlyViewing : Evergreen.V405.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) Evergreen.V405.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.LocalState.DiscordFrontendGuild
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId) Evergreen.V405.LocalState.SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId) Evergreen.V405.LocalState.SlackFrontendDmChannel
    , slackUsers : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) Evergreen.V405.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId)
    , user : Evergreen.V405.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.User.FrontendUser
    , discordUsers : Evergreen.V405.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V405.SessionIdHash.SessionIdHash Evergreen.V405.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V405.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId) Evergreen.V405.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId) Evergreen.V405.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V405.Call.CallId (Evergreen.V405.NonemptyDict.NonemptyDict ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V405.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V405.Go.PublicGoMatchData Evergreen.V405.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V405.Route.Route
    , windowSize : Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V405.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V405.Audio.LoadError Evergreen.V405.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Encryption.EncryptedData (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.NonemptyDict.NonemptyDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.Encryption.EncryptedData (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V405.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V405.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V405.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData) (List Evergreen.V405.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V405.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V405.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData)
    | Local_Slack_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V405.Id.SlackGuildOrDmId String.Nonempty.NonemptyString
    | Local_Slack_UnlinkUser (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.ChannelName.ChannelName Evergreen.V405.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.ChannelName.ChannelName Evergreen.V405.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V405.GuildName.GuildName (Evergreen.V405.UserSession.ToBeFilledInByBackend (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V405.Id.Viewing_DiscordDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V405.SetViewing.SetViewing
    | Local_SetName Evergreen.V405.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V405.Id.GuildOrDmId (Evergreen.V405.VisibleMessages.PageRequest Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend Evergreen.V405.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V405.Id.GuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.VisibleMessages.PageRequest Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))))
    | Local_Slack_LoadChannelMessages Evergreen.V405.Id.SlackGuildOrDmId (Evergreen.V405.VisibleMessages.PageRequest Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V405.Id.DiscordGuildOrDmId (Evergreen.V405.VisibleMessages.PageRequest Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V405.Id.DiscordGuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.VisibleMessages.PageRequest Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V405.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V405.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V405.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.QuestionId Evergreen.V405.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V405.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V405.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V405.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V405.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V405.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V405.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V405.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V405.NonemptySet.NonemptySet (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V405.Call.LocalChange
    | Local_Game Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Game.LocalChange
    | Local_Drawing Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Drawing.AnchorType Evergreen.V405.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V405.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V405.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V405.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V405.X25519.PublicKey (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V405.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V405.Id.Viewing_DmId (List ( Evergreen.V405.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V405.FileStatus.FileHash, Evergreen.V405.Encryption.EncryptedData (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V405.Id.Viewing_DmId (Evergreen.V405.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V405.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V405.Id.ThreadRouteWithMessage, Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V405.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V405.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V405.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V405.FileStatus.FileHash) (Evergreen.V405.Encryption.EncryptedData (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))) (Evergreen.V405.Encryption.EncryptedData String) Evergreen.V405.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V405.Id.Viewing_DmId Evergreen.V405.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V405.FileStatus.FileHash) (Evergreen.V405.Encryption.EncryptedData (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V405.Message.Message Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    | RepliedToGame Evergreen.V405.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
        , sender : Evergreen.V405.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V405.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
        , threadRoute : Evergreen.V405.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId) Evergreen.V405.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Slack_SendMessage Effect.Time.Posix Evergreen.V405.Id.SlackGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId)))
    | Server_Slack_EditMessage Effect.Time.Posix Evergreen.V405.Id.SlackGuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId)))
    | Server_Slack_DeleteMessage Evergreen.V405.Id.SlackGuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    | Server_Slack_UnlinkUser (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V405.Id.DiscordGuildOrDmId Evergreen.V405.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))) Evergreen.V405.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId) Evergreen.V405.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.ChannelName.ChannelName Evergreen.V405.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.ChannelName.ChannelName Evergreen.V405.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.User.FrontendUser
    | Server_MemberLeft (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V405.LocalState.JoinGuildError
            { guildId : Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId
            , guild : Evergreen.V405.LocalState.FrontendGuild
            , owner : Evergreen.V405.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V405.Id.Viewing_DiscordDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Maybe Evergreen.V405.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Maybe Evergreen.V405.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V405.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V405.SessionIdHash.SessionIdHash Evergreen.V405.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V405.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V405.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V405.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V405.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V405.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Bool Evergreen.V405.ChannelName.ChannelName (Evergreen.V405.Discord.OptionalData (Maybe String)) (List Evergreen.V405.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
        (Evergreen.V405.NonemptyDict.NonemptyDict
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) Evergreen.V405.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Maybe (Evergreen.V405.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V405.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V405.Log.Log
    | Server_BackupGenerated Evergreen.V405.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V405.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V405.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V405.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V405.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (Evergreen.V405.Discord.OptionalData (Maybe String)) (Evergreen.V405.Discord.OptionalData (Maybe String)) (List Evergreen.V405.Discord.Overwrite)
    | Server_DiscordChannelDeleted (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)
    | Server_DiscordUpdateGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.GuildName.GuildName (Maybe Evergreen.V405.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId) Evergreen.V405.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId) Evergreen.V405.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
        (Evergreen.V405.MembersAndOwner.MembersAndOwner
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.PersonName.PersonName Evergreen.V405.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId) Evergreen.V405.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId) Evergreen.V405.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V405.Call.ServerChange
    | Server_Game (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Game.LocalChange
    | Server_Drawing (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Drawing.AnchorType Evergreen.V405.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V405.Id.Viewing_DmId ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Evergreen.V405.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V405.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V405.Id.Viewing_DmId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | Server_E2eeAccepted Evergreen.V405.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
        , sender : Evergreen.V405.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V405.Id.Viewing_DmId
        , content : Evergreen.V405.Encryption.EncryptedData (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
        , threadRoute : Evergreen.V405.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V405.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.Viewing_DmId Evergreen.V405.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V405.FileStatus.FileHash) (Evergreen.V405.Encryption.EncryptedData (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V405.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V405.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V405.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V405.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V405.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V405.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V405.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V405.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V405.Id.AnyGuildOrDmId Evergreen.V405.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V405.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels) (Maybe Evergreen.V405.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V405.SheepGame.Input (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels) (Maybe Evergreen.V405.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V405.Id.GuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V405.Id.GuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId) (Evergreen.V405.NonemptySet.NonemptySet Int))
    }


type LinkSlackResult
    = SlackLinkingDisabled
    | LoadedSlackWorkspaces (List.Nonempty.Nonempty (Result Evergreen.V405.Slack.HttpError String))


type alias UserOptionsModel =
    { name : Evergreen.V405.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V405.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    , slackCookie : String
    , slackTeamsJson : String
    , pressedSubmitSlackData : Bool
    , linkSlackResult : Maybe LinkSlackResult
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V405.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , threadRoute : Evergreen.V405.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V405.Encryption.BytesHash
    , id : Evergreen.V405.Id.Viewing_DmId
    , senderId : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , threadRoute : Evergreen.V405.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V405.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V405.Id.Viewing_DmId
    , messages : List Evergreen.V405.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V405.Id.Viewing_DmId
    , messages : List ( Evergreen.V405.Id.ThreadRouteWithMessage, Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V405.Id.Viewing_DmId
    , threadRoute : Evergreen.V405.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute )
    , fileId : Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V405.Id.Id Evergreen.V405.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V405.Id.Id Evergreen.V405.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V405.Id.Id Evergreen.V405.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V405.Id.Id Evergreen.V405.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V405.Id.Id Evergreen.V405.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V405.Local.Local LocalMsg Evergreen.V405.LocalState.LocalState
    , admin : Evergreen.V405.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId, Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V405.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V405.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.Message.RepliedTo Evergreen.V405.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V405.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V405.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V405.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.ThreadRoute ) (Evergreen.V405.NonemptyDict.NonemptyDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V405.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V405.Scroll.ScrollPosition
    , textEditor : Evergreen.V405.TextEditor.Model
    , profilePictureEditor : Evergreen.V405.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId, Evergreen.V405.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V405.Emoji.Model
    , voiceChat : Evergreen.V405.Call.Model
    , games : SeqDict.SeqDict Evergreen.V405.Id.GuildOrDmId Evergreen.V405.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V405.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V405.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V405.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V405.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V405.Range.Range
                , direction : Evergreen.V405.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V405.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V405.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V405.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V405.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V405.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | LinkSlackResponse LinkSlackResult
    | ProfilePictureEditorToFrontend Evergreen.V405.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V405.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V405.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V405.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V405.MyUi.LastCopy
    , drag : Evergreen.V405.Touch.Drag
    , dragPrevious : Evergreen.V405.Touch.Drag
    , aiChatModel : Evergreen.V405.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V405.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V405.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V405.Audio.LoadError Evergreen.V405.Audio.Source
    , startupData : Evergreen.V405.Ports.StartupData
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
    Evergreen.V405.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V405.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V405.EmailAddress.EmailAddress
        }


type alias SlackBackendChannel =
    { name : Evergreen.V405.ChannelName.ChannelName
    , isPrivate : Bool
    , linkedMembers : SeqSet.SeqSet (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
    , messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V405.OneToOne.OneToOne (Evergreen.V405.Slack.Id Evergreen.V405.Slack.MessageId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    }


type alias SlackBackendWorkspace =
    { name : String
    , domain : String
    , icon : String
    , channels : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId) SlackBackendChannel
    }


type alias SlackLinkedUser =
    { user : Evergreen.V405.Slack.User
    , linkedTo : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , linkedAt : Effect.Time.Posix
    , token : Evergreen.V405.Slack.SlackToken
    , cookie : Evergreen.V405.Slack.SlackCookie
    , websocket : Maybe Effect.Websocket.Connection
    , reconnect :
        { failedAttempts : Int
        , seed : Int
        }
    }


type SlackUserData
    = SlackBasicData Evergreen.V405.Slack.User
    | SlackFullData SlackLinkedUser


type alias SlackDmChannel =
    { teamId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId
    , members : Evergreen.V405.NonemptySet.NonemptySet (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
    , messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V405.OneToOne.OneToOne (Evergreen.V405.Slack.Id Evergreen.V405.Slack.MessageId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V405.FileStatus.FileHash
    , metadata : Maybe Evergreen.V405.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId, Evergreen.V405.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId, Evergreen.V405.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V405.DmChannelId.DmChannelId, Evergreen.V405.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId, Evergreen.V405.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId, Evergreen.V405.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId, Evergreen.V405.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V405.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V405.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V405.LocalState.BackupContents
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
    { users : Evergreen.V405.NonemptyDict.NonemptyDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V405.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V405.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V405.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V405.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.LocalState.DiscordBackendGuild
    , orphanedDiscordGuildsLastHour : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    , dmChannels : SeqDict.SeqDict Evergreen.V405.DmChannelId.DmChannelId Evergreen.V405.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) Evergreen.V405.DmChannel.DiscordDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId) SlackBackendWorkspace
    , slackUsers : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) SlackUserData
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId) SlackDmChannel
    , files : SeqDict.SeqDict Evergreen.V405.FileStatus.FileHash Evergreen.V405.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V405.FileStatus.FileHash
    , privateVapidKey : Evergreen.V405.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V405.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId, Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V405.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V405.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V405.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V405.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.LocalState.LoadingDiscordChannel Evergreen.V405.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , slackLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V405.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V405.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V405.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId) Evergreen.V405.Sticker.StickerData
    , discordStickers : Evergreen.V405.OneToOne.OneToOne (Evergreen.V405.Discord.Id Evergreen.V405.Discord.StickerId) (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId) Evergreen.V405.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V405.OneToOne.OneToOne Evergreen.V405.RichText.DiscordCustomEmojiIdAndName (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V405.Postmark.ApiKey
    , serverSecret : Evergreen.V405.SecretId.SecretId Evergreen.V405.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V405.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V405.OneToOne.OneToOne (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.GamePublicId) ( Evergreen.V405.DmChannelId.GuildOrFullDmId, Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V405.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V405.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) PendingGatewayReconnect
    , pendingSlackSends : SeqDict.SeqDict ( Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId, String ) Int
    , pendingSlackReconnects : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V405.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.Id.ThreadRoute (Maybe Evergreen.V405.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V405.DmChannelId.DmChannelId Evergreen.V405.Id.ThreadRoute (Maybe Evergreen.V405.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V405.Id.Id Evergreen.V405.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V405.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V405.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V405.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V405.UserAgent.UserAgent
    | AdminToBackend Evergreen.V405.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V405.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V405.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V405.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V405.PersonName.PersonName Evergreen.V405.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V405.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkDiscordRequest Evergreen.V405.Discord.UserAuth
    | LinkSlackRequest Evergreen.V405.Slack.SlackData
    | ProfilePictureEditorToBackend Evergreen.V405.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V405.Id.Id Evergreen.V405.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V405.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V405.EmailAddress.EmailAddress (Result Evergreen.V405.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V405.EmailAddress.EmailAddress (Result Evergreen.V405.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V405.EmailAddress.EmailAddress (Result Evergreen.V405.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V405.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMaybeMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Result Evergreen.V405.Discord.HttpError Evergreen.V405.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V405.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Result Evergreen.V405.Discord.HttpError Evergreen.V405.Discord.Message)
    | SentSlackMessage Effect.Time.Posix Evergreen.V405.Local.ChangeId Effect.Lamdera.ClientId Effect.Time.Zone Evergreen.V405.Id.SlackGuildOrDmId String.Nonempty.NonemptyString (List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId))) (Result Evergreen.V405.Slack.HttpError (Evergreen.V405.Slack.Id Evergreen.V405.Slack.MessageId))
    | SlackWebsocketCreatedHandle (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) Effect.Websocket.Connection
    | SlackWebsocketClosedByBackend
    | SlackWebsocketMsg (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SlackWebsocketSentData (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Result Effect.Websocket.SendError ())
    | SlackWebsocketReconnectTick
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) (Result Evergreen.V405.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) (Result Evergreen.V405.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) (Result Evergreen.V405.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) (Result Evergreen.V405.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji (Result Evergreen.V405.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji (Result Evergreen.V405.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji (Result Evergreen.V405.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji (Result Evergreen.V405.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V405.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V405.Discord.HttpError (List ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId, Maybe Evergreen.V405.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Effect.Time.Posix Evergreen.V405.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | LinkSlackUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Slack.SlackCookie (List.Nonempty.Nonempty ( Evergreen.V405.Slack.SlackToken, Result Evergreen.V405.Slack.HttpError Evergreen.V405.Slack.UserBoot ))
    | LinkSlackUserStep2
        Effect.Time.Posix
        (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId)
        (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
        (Result
            Evergreen.V405.Slack.HttpError
            { channels : List ( Evergreen.V405.Slack.Channel, List Evergreen.V405.Slack.Message )
            , dmChannels : List ( Evergreen.V405.Slack.DmChannel, List Evergreen.V405.Slack.Message )
            , users : List Evergreen.V405.Slack.User
            }
        )
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Discord.UserAuth (Result Evergreen.V405.Discord.HttpError Evergreen.V405.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Result Evergreen.V405.Discord.HttpError Evergreen.V405.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
        (Result
            Evergreen.V405.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId
                    , members : List (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
                    , messages : List Evergreen.V405.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId
                    , { guild : Evergreen.V405.Discord.GatewayGuild
                      , channels : List Evergreen.V405.Discord.Channel
                      , icon : Maybe Evergreen.V405.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (List Evergreen.V405.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V405.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V405.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V405.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V405.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.AttachmentId, Evergreen.V405.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V405.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.AttachmentId, Evergreen.V405.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V405.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V405.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V405.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V405.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (Result Evergreen.V405.Discord.HttpError Evergreen.V405.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Result Evergreen.V405.Discord.HttpError (List Evergreen.V405.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V405.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V405.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V405.DmChannelId.DmChannelId Evergreen.V405.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V405.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V405.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V405.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
        (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V405.Discord.HttpError
            { guild : Evergreen.V405.Discord.GatewayGuild
            , channels : List Evergreen.V405.Discord.Channel
            , icon : Maybe Evergreen.V405.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Maybe Evergreen.V405.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Result Evergreen.V405.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V405.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V405.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (List ( Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId, Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId, Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (List ( Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V405.Discord.HttpError (List Evergreen.V405.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V405.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V405.SecretId.SecretId Evergreen.V405.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V405.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V405.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V405.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V405.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Result Evergreen.V405.Discord.HttpError ( Evergreen.V405.Discord.Guild, List Evergreen.V405.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V405.FileStatus.FileHash Int (Maybe (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Call.CallId
