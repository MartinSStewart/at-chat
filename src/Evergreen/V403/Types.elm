module Evergreen.V403.Types exposing (..)

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
import Evergreen.V403.AiChat
import Evergreen.V403.Audio
import Evergreen.V403.BackendMsgLog
import Evergreen.V403.Call
import Evergreen.V403.ChannelDescription
import Evergreen.V403.ChannelName
import Evergreen.V403.Coord
import Evergreen.V403.CssPixels
import Evergreen.V403.CustomEmoji
import Evergreen.V403.Discord
import Evergreen.V403.DiscordAttachmentId
import Evergreen.V403.DiscordUserData
import Evergreen.V403.DmChannel
import Evergreen.V403.DmChannelId
import Evergreen.V403.Drawing
import Evergreen.V403.Editable
import Evergreen.V403.EmailAddress
import Evergreen.V403.Embed
import Evergreen.V403.Emoji
import Evergreen.V403.Encryption
import Evergreen.V403.FileStatus
import Evergreen.V403.Game
import Evergreen.V403.Go
import Evergreen.V403.GuildName
import Evergreen.V403.Id
import Evergreen.V403.IdArray
import Evergreen.V403.ImageEditor
import Evergreen.V403.ImageViewer
import Evergreen.V403.LinkedAndOtherDiscordUsers
import Evergreen.V403.Local
import Evergreen.V403.LocalState
import Evergreen.V403.Log
import Evergreen.V403.LoginForm
import Evergreen.V403.MembersAndOwner
import Evergreen.V403.Message
import Evergreen.V403.MessageInput
import Evergreen.V403.MessageView
import Evergreen.V403.MuteSettings
import Evergreen.V403.MyUi
import Evergreen.V403.NonemptyDict
import Evergreen.V403.NonemptySet
import Evergreen.V403.OneOrGreater
import Evergreen.V403.OneToOne
import Evergreen.V403.Pages.Admin
import Evergreen.V403.Pagination
import Evergreen.V403.PersonName
import Evergreen.V403.Ports
import Evergreen.V403.Postmark
import Evergreen.V403.Range
import Evergreen.V403.RateLimit
import Evergreen.V403.RecoveryLogin
import Evergreen.V403.RichText
import Evergreen.V403.Route
import Evergreen.V403.Scroll
import Evergreen.V403.SecretId
import Evergreen.V403.SessionIdHash
import Evergreen.V403.SetViewing
import Evergreen.V403.SheepGame
import Evergreen.V403.Slack
import Evergreen.V403.Sticker
import Evergreen.V403.TextEditor
import Evergreen.V403.ToBackendLog
import Evergreen.V403.Touch
import Evergreen.V403.TwoFactorAuthentication
import Evergreen.V403.Ui.Anim
import Evergreen.V403.User
import Evergreen.V403.UserAgent
import Evergreen.V403.UserColor
import Evergreen.V403.UserSession
import Evergreen.V403.VisibleMessages
import Evergreen.V403.WordSpellingGame
import Evergreen.V403.X25519
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
    | LoginFormMsg Evergreen.V403.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V403.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V403.Pages.Admin.Msg
    | PressedLogOut Evergreen.V403.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V403.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V403.Route.Route
    | SelectedFilesToAttach ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | PressedImportChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V403.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V403.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V403.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V403.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V403.NonemptyDict.NonemptyDict Int Evergreen.V403.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V403.NonemptyDict.NonemptyDict Int Evergreen.V403.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRoute Evergreen.V403.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V403.NonemptySet.NonemptySet (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V403.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V403.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V403.AiChat.Msg
    | GameMsg Evergreen.V403.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V403.Id.GuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V403.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V403.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V403.Editable.Msg Evergreen.V403.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V403.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) (Maybe Evergreen.V403.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute )
        { fileId : Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute )
        { fileId : Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage Evergreen.V403.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V403.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V403.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V403.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V403.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V403.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V403.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V403.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | PressedDisableE2ee (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | TypedPrivateKey (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) String
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
    | TextEditorMsg Evergreen.V403.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId
        , otherUserId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V403.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRoute Evergreen.V403.MessageInput.Msg
    | MessageInputMsg Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRoute Evergreen.V403.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V403.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V403.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V403.Range.Range, Evergreen.V403.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V403.Range.Range, Evergreen.V403.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V403.Call.FromJs)
    | VoiceChatMsg Evergreen.V403.Call.Msg
    | PressedChannelHeaderTab Evergreen.V403.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V403.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V403.Audio.LoadError Evergreen.V403.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V403.Route.Route
    | PressedMuteChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V403.Id.AnyGuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V403.Id.AnyGuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) Evergreen.V403.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V403.Encryption.FromJs (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V403.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V403.UserSession.UserSession
    , currentlyViewing : Evergreen.V403.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) Evergreen.V403.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.LocalState.DiscordFrontendGuild
    , user : Evergreen.V403.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.User.FrontendUser
    , discordUsers : Evergreen.V403.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V403.SessionIdHash.SessionIdHash Evergreen.V403.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V403.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId) Evergreen.V403.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId) Evergreen.V403.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V403.Call.CallId (Evergreen.V403.NonemptyDict.NonemptyDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V403.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V403.Go.PublicGoMatchData Evergreen.V403.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V403.Route.Route
    , windowSize : Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V403.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V403.Audio.LoadError Evergreen.V403.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Encryption.EncryptedData (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.NonemptyDict.NonemptyDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Encryption.EncryptedData (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V403.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V403.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V403.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData) (List Evergreen.V403.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V403.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V403.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.ChannelName.ChannelName Evergreen.V403.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.ChannelName.ChannelName Evergreen.V403.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.UserSession.ToBeFilledInByBackend (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V403.GuildName.GuildName (Evergreen.V403.UserSession.ToBeFilledInByBackend (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V403.Id.Viewing_DiscordDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V403.SetViewing.SetViewing
    | Local_SetName Evergreen.V403.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V403.Id.GuildOrDmId (Evergreen.V403.VisibleMessages.PageRequest Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.UserSession.ToBeFilledInByBackend Evergreen.V403.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V403.Id.GuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.VisibleMessages.PageRequest Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V403.Id.DiscordGuildOrDmId (Evergreen.V403.VisibleMessages.PageRequest Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V403.Id.DiscordGuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.VisibleMessages.PageRequest Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V403.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V403.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V403.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.QuestionId Evergreen.V403.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V403.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V403.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V403.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V403.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V403.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V403.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V403.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V403.NonemptySet.NonemptySet (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V403.Call.LocalChange
    | Local_Game Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Game.LocalChange
    | Local_Drawing Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Drawing.AnchorType Evergreen.V403.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V403.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V403.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V403.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V403.X25519.PublicKey (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V403.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V403.Id.Viewing_DmId (List ( Evergreen.V403.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V403.FileStatus.FileHash, Evergreen.V403.Encryption.EncryptedData (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V403.Id.Viewing_DmId (Evergreen.V403.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V403.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V403.Id.ThreadRouteWithMessage, Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V403.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V403.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V403.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V403.FileStatus.FileHash) (Evergreen.V403.Encryption.EncryptedData (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))) (Evergreen.V403.Encryption.EncryptedData String) Evergreen.V403.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V403.Id.Viewing_DmId Evergreen.V403.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V403.FileStatus.FileHash) (Evergreen.V403.Encryption.EncryptedData (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    | RepliedToGame Evergreen.V403.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
        , sender : Evergreen.V403.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V403.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V403.RichText.RichText (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
        , threadRoute : Evergreen.V403.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId) Evergreen.V403.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V403.Id.DiscordGuildOrDmId Evergreen.V403.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V403.RichText.RichText (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))) Evergreen.V403.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId) Evergreen.V403.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.ChannelName.ChannelName Evergreen.V403.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.ChannelName.ChannelName Evergreen.V403.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.User.FrontendUser
    | Server_MemberLeft (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V403.LocalState.JoinGuildError
            { guildId : Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId
            , guild : Evergreen.V403.LocalState.FrontendGuild
            , owner : Evergreen.V403.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V403.RichText.RichText (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V403.RichText.RichText (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V403.Id.Viewing_DiscordDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V403.RichText.RichText (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Maybe Evergreen.V403.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Maybe Evergreen.V403.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V403.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V403.SessionIdHash.SessionIdHash Evergreen.V403.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V403.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V403.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V403.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V403.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V403.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Bool Evergreen.V403.ChannelName.ChannelName (Evergreen.V403.Discord.OptionalData (Maybe String)) (List Evergreen.V403.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
        (Evergreen.V403.NonemptyDict.NonemptyDict
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) Evergreen.V403.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Maybe (Evergreen.V403.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V403.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V403.Log.Log
    | Server_BackupGenerated Evergreen.V403.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V403.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V403.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V403.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V403.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (Evergreen.V403.Discord.OptionalData (Maybe String)) (Evergreen.V403.Discord.OptionalData (Maybe String)) (List Evergreen.V403.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.GuildName.GuildName (Maybe Evergreen.V403.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId) Evergreen.V403.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId) Evergreen.V403.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
        (Evergreen.V403.MembersAndOwner.MembersAndOwner
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.PersonName.PersonName Evergreen.V403.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId) Evergreen.V403.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId) Evergreen.V403.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V403.Call.ServerChange
    | Server_Game (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Game.LocalChange
    | Server_Drawing (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Drawing.AnchorType Evergreen.V403.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V403.Id.Viewing_DmId ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V403.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V403.Id.Viewing_DmId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | Server_E2eeAccepted Evergreen.V403.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
        , sender : Evergreen.V403.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V403.Id.Viewing_DmId
        , content : Evergreen.V403.Encryption.EncryptedData (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
        , threadRoute : Evergreen.V403.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V403.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.Viewing_DmId Evergreen.V403.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V403.FileStatus.FileHash) (Evergreen.V403.Encryption.EncryptedData (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V403.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V403.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V403.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V403.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V403.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V403.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V403.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V403.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V403.Id.AnyGuildOrDmId Evergreen.V403.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V403.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels) (Maybe Evergreen.V403.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V403.SheepGame.Input (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels) (Maybe Evergreen.V403.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V403.Id.GuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V403.Id.GuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V403.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V403.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V403.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , threadRoute : Evergreen.V403.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V403.Encryption.BytesHash
    , id : Evergreen.V403.Id.Viewing_DmId
    , senderId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , threadRoute : Evergreen.V403.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V403.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V403.Id.Viewing_DmId
    , messages : List Evergreen.V403.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V403.Id.Viewing_DmId
    , messages : List ( Evergreen.V403.Id.ThreadRouteWithMessage, Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V403.Id.Viewing_DmId
    , threadRoute : Evergreen.V403.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute )
    , fileId : Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V403.Id.Id Evergreen.V403.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V403.Id.Id Evergreen.V403.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V403.Id.Id Evergreen.V403.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V403.Id.Id Evergreen.V403.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V403.Id.Id Evergreen.V403.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V403.Local.Local LocalMsg Evergreen.V403.LocalState.LocalState
    , admin : Evergreen.V403.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V403.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V403.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.Message.RepliedTo Evergreen.V403.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V403.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V403.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V403.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.ThreadRoute ) (Evergreen.V403.NonemptyDict.NonemptyDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V403.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V403.Scroll.ScrollPosition
    , textEditor : Evergreen.V403.TextEditor.Model
    , profilePictureEditor : Evergreen.V403.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId, Evergreen.V403.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V403.Emoji.Model
    , voiceChat : Evergreen.V403.Call.Model
    , games : SeqDict.SeqDict Evergreen.V403.Id.GuildOrDmId Evergreen.V403.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V403.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V403.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V403.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V403.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V403.Range.Range
                , direction : Evergreen.V403.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V403.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V403.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V403.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V403.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V403.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | ProfilePictureEditorToFrontend Evergreen.V403.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V403.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V403.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V403.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V403.MyUi.LastCopy
    , drag : Evergreen.V403.Touch.Drag
    , dragPrevious : Evergreen.V403.Touch.Drag
    , aiChatModel : Evergreen.V403.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V403.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V403.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V403.Audio.LoadError Evergreen.V403.Audio.Source
    , startupData : Evergreen.V403.Ports.StartupData
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
    Evergreen.V403.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V403.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V403.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V403.FileStatus.FileHash
    , metadata : Maybe Evergreen.V403.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId, Evergreen.V403.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId, Evergreen.V403.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V403.DmChannelId.DmChannelId, Evergreen.V403.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId, Evergreen.V403.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId, Evergreen.V403.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId, Evergreen.V403.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V403.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V403.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V403.LocalState.BackupContents
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
    { users : Evergreen.V403.NonemptyDict.NonemptyDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V403.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V403.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V403.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V403.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V403.DmChannelId.DmChannelId Evergreen.V403.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) Evergreen.V403.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.Slack.Id Evergreen.V403.Slack.ChannelId) Evergreen.V403.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V403.OneToOne.OneToOne String (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    , slackUsers : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.Slack.Id Evergreen.V403.Slack.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    , slackServers : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.Slack.Id Evergreen.V403.Slack.TeamId) (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    , slackToken : Maybe Evergreen.V403.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V403.FileStatus.FileHash Evergreen.V403.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V403.FileStatus.FileHash
    , privateVapidKey : Evergreen.V403.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V403.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V403.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId, Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V403.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V403.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V403.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V403.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.LocalState.LoadingDiscordChannel Evergreen.V403.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V403.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V403.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V403.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId) Evergreen.V403.Sticker.StickerData
    , discordStickers : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.Discord.Id Evergreen.V403.Discord.StickerId) (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId) Evergreen.V403.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V403.OneToOne.OneToOne Evergreen.V403.RichText.DiscordCustomEmojiIdAndName (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V403.Postmark.ApiKey
    , serverSecret : Evergreen.V403.SecretId.SecretId Evergreen.V403.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V403.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.GamePublicId) ( Evergreen.V403.DmChannelId.GuildOrFullDmId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V403.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V403.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V403.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.Id.ThreadRoute (Maybe Evergreen.V403.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V403.DmChannelId.DmChannelId Evergreen.V403.Id.ThreadRoute (Maybe Evergreen.V403.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V403.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V403.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V403.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V403.UserAgent.UserAgent
    | AdminToBackend Evergreen.V403.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V403.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V403.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V403.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V403.PersonName.PersonName Evergreen.V403.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V403.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V403.Slack.OAuthCode Evergreen.V403.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V403.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V403.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V403.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V403.EmailAddress.EmailAddress (Result Evergreen.V403.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V403.EmailAddress.EmailAddress (Result Evergreen.V403.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V403.EmailAddress.EmailAddress (Result Evergreen.V403.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V403.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMaybeMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Result Evergreen.V403.Discord.HttpError Evergreen.V403.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V403.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Result Evergreen.V403.Discord.HttpError Evergreen.V403.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) (Result Evergreen.V403.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) (Result Evergreen.V403.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) (Result Evergreen.V403.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) (Result Evergreen.V403.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji (Result Evergreen.V403.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji (Result Evergreen.V403.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji (Result Evergreen.V403.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji (Result Evergreen.V403.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V403.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V403.Discord.HttpError (List ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId, Maybe Evergreen.V403.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Effect.Time.Posix Evergreen.V403.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V403.Slack.CurrentUser
            , team : Evergreen.V403.Slack.Team
            , users : List Evergreen.V403.Slack.User
            , channels : List ( Evergreen.V403.Slack.Channel, List Evergreen.V403.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Result Effect.Http.Error Evergreen.V403.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Discord.UserAuth (Result Evergreen.V403.Discord.HttpError Evergreen.V403.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Result Evergreen.V403.Discord.HttpError Evergreen.V403.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
        (Result
            Evergreen.V403.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId
                    , members : List (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
                    , messages : List Evergreen.V403.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId
                    , { guild : Evergreen.V403.Discord.GatewayGuild
                      , channels : List Evergreen.V403.Discord.Channel
                      , icon : Maybe Evergreen.V403.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (List Evergreen.V403.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V403.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V403.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V403.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V403.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.AttachmentId, Evergreen.V403.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V403.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.AttachmentId, Evergreen.V403.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V403.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V403.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V403.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V403.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (Result Evergreen.V403.Discord.HttpError Evergreen.V403.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Result Evergreen.V403.Discord.HttpError (List Evergreen.V403.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V403.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V403.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V403.DmChannelId.DmChannelId Evergreen.V403.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V403.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V403.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V403.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
        (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V403.Discord.HttpError
            { guild : Evergreen.V403.Discord.GatewayGuild
            , channels : List Evergreen.V403.Discord.Channel
            , icon : Maybe Evergreen.V403.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Maybe Evergreen.V403.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Result Evergreen.V403.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V403.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V403.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (List ( Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId, Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId, Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (List ( Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V403.Discord.HttpError (List Evergreen.V403.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V403.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V403.SecretId.SecretId Evergreen.V403.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V403.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V403.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V403.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V403.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Result Evergreen.V403.Discord.HttpError ( Evergreen.V403.Discord.Guild, List Evergreen.V403.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V403.FileStatus.FileHash Int (Maybe (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Call.CallId
