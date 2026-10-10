module Evergreen.V402.Types exposing (..)

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
import Evergreen.V402.AiChat
import Evergreen.V402.Audio
import Evergreen.V402.BackendMsgLog
import Evergreen.V402.Call
import Evergreen.V402.ChannelDescription
import Evergreen.V402.ChannelName
import Evergreen.V402.Coord
import Evergreen.V402.CssPixels
import Evergreen.V402.CustomEmoji
import Evergreen.V402.Discord
import Evergreen.V402.DiscordAttachmentId
import Evergreen.V402.DiscordUserData
import Evergreen.V402.DmChannel
import Evergreen.V402.DmChannelId
import Evergreen.V402.Drawing
import Evergreen.V402.Editable
import Evergreen.V402.EmailAddress
import Evergreen.V402.Embed
import Evergreen.V402.Emoji
import Evergreen.V402.Encryption
import Evergreen.V402.FileStatus
import Evergreen.V402.Game
import Evergreen.V402.Go
import Evergreen.V402.GuildName
import Evergreen.V402.Id
import Evergreen.V402.IdArray
import Evergreen.V402.ImageEditor
import Evergreen.V402.ImageViewer
import Evergreen.V402.LinkedAndOtherDiscordUsers
import Evergreen.V402.Local
import Evergreen.V402.LocalState
import Evergreen.V402.Log
import Evergreen.V402.LoginForm
import Evergreen.V402.MembersAndOwner
import Evergreen.V402.Message
import Evergreen.V402.MessageInput
import Evergreen.V402.MessageView
import Evergreen.V402.MuteSettings
import Evergreen.V402.MyUi
import Evergreen.V402.NonemptyDict
import Evergreen.V402.NonemptySet
import Evergreen.V402.OneOrGreater
import Evergreen.V402.OneToOne
import Evergreen.V402.Pages.Admin
import Evergreen.V402.Pagination
import Evergreen.V402.PersonName
import Evergreen.V402.Ports
import Evergreen.V402.Postmark
import Evergreen.V402.Range
import Evergreen.V402.RateLimit
import Evergreen.V402.RecoveryLogin
import Evergreen.V402.RichText
import Evergreen.V402.Route
import Evergreen.V402.Scroll
import Evergreen.V402.SecretId
import Evergreen.V402.SessionIdHash
import Evergreen.V402.SetViewing
import Evergreen.V402.SheepGame
import Evergreen.V402.Slack
import Evergreen.V402.Sticker
import Evergreen.V402.TextEditor
import Evergreen.V402.ToBackendLog
import Evergreen.V402.Touch
import Evergreen.V402.TwoFactorAuthentication
import Evergreen.V402.Ui.Anim
import Evergreen.V402.User
import Evergreen.V402.UserAgent
import Evergreen.V402.UserColor
import Evergreen.V402.UserSession
import Evergreen.V402.WordSpellingGame
import Evergreen.V402.X25519
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
    | LoginFormMsg Evergreen.V402.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V402.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V402.Pages.Admin.Msg
    | PressedLogOut Evergreen.V402.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V402.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V402.Route.Route
    | SelectedFilesToAttach ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | PressedImportChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V402.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V402.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V402.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V402.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V402.NonemptyDict.NonemptyDict Int Evergreen.V402.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V402.NonemptyDict.NonemptyDict Int Evergreen.V402.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRoute Evergreen.V402.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V402.NonemptySet.NonemptySet (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V402.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V402.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V402.AiChat.Msg
    | GameMsg Evergreen.V402.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V402.Id.GuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V402.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V402.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V402.Editable.Msg Evergreen.V402.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V402.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) (Maybe Evergreen.V402.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute )
        { fileId : Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute )
        { fileId : Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage Evergreen.V402.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V402.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V402.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V402.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V402.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V402.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V402.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V402.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | PressedDisableE2ee (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | TypedPrivateKey (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) String
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
    | TextEditorMsg Evergreen.V402.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId
        , otherUserId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V402.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRoute Evergreen.V402.MessageInput.Msg
    | MessageInputMsg Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRoute Evergreen.V402.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V402.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V402.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V402.Range.Range, Evergreen.V402.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V402.Range.Range, Evergreen.V402.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V402.Call.FromJs)
    | VoiceChatMsg Evergreen.V402.Call.Msg
    | PressedChannelHeaderTab Evergreen.V402.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V402.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V402.Audio.LoadError Evergreen.V402.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | TypedSearchOverlay String
    | PressedSearchOverlayArrowKey Int
    | PressedSearchOverlayEnter
    | PressedSearchOverlayResult Evergreen.V402.Route.Route
    | PressedMuteChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V402.Id.AnyGuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V402.Id.AnyGuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) Evergreen.V402.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V402.Encryption.FromJs (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V402.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V402.UserSession.UserSession
    , currentlyViewing : Evergreen.V402.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) Evergreen.V402.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.LocalState.DiscordFrontendGuild
    , user : Evergreen.V402.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.User.FrontendUser
    , discordUsers : Evergreen.V402.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V402.SessionIdHash.SessionIdHash Evergreen.V402.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V402.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId) Evergreen.V402.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId) Evergreen.V402.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V402.Call.CallId (Evergreen.V402.NonemptyDict.NonemptyDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V402.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V402.Go.PublicGoMatchData Evergreen.V402.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V402.Route.Route
    , windowSize : Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V402.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V402.Audio.LoadError Evergreen.V402.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Encryption.EncryptedData (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.NonemptyDict.NonemptyDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Encryption.EncryptedData (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V402.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V402.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V402.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileData) (List Evergreen.V402.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V402.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V402.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.ChannelName.ChannelName Evergreen.V402.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.ChannelName.ChannelName Evergreen.V402.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.UserSession.ToBeFilledInByBackend (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V402.GuildName.GuildName (Evergreen.V402.UserSession.ToBeFilledInByBackend (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V402.Id.Viewing_DiscordDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V402.SetViewing.SetViewing
    | Local_SetName Evergreen.V402.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V402.Id.GuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.UserSession.ToBeFilledInByBackend Evergreen.V402.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V402.Id.GuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V402.Id.DiscordGuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V402.Id.DiscordGuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V402.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V402.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V402.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.QuestionId Evergreen.V402.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V402.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V402.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V402.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V402.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V402.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V402.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V402.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V402.NonemptySet.NonemptySet (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V402.Call.LocalChange
    | Local_Game Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Game.LocalChange
    | Local_Drawing Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Drawing.AnchorType Evergreen.V402.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V402.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V402.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V402.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V402.X25519.PublicKey (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V402.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V402.Id.Viewing_DmId (List ( Evergreen.V402.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V402.FileStatus.FileHash, Evergreen.V402.Encryption.EncryptedData (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V402.Id.Viewing_DmId (Evergreen.V402.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V402.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V402.Id.ThreadRouteWithMessage, Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V402.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V402.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V402.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V402.FileStatus.FileHash) (Evergreen.V402.Encryption.EncryptedData (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))) (Evergreen.V402.Encryption.EncryptedData String) Evergreen.V402.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V402.Id.Viewing_DmId Evergreen.V402.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V402.FileStatus.FileHash) (Evergreen.V402.Encryption.EncryptedData (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    | RepliedToGame Evergreen.V402.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
        , sender : Evergreen.V402.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V402.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V402.RichText.RichText (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
        , threadRoute : Evergreen.V402.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId) Evergreen.V402.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V402.Id.DiscordGuildOrDmId Evergreen.V402.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V402.RichText.RichText (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))) Evergreen.V402.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId) Evergreen.V402.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.ChannelName.ChannelName Evergreen.V402.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.ChannelName.ChannelName Evergreen.V402.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.User.FrontendUser
    | Server_MemberLeft (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V402.LocalState.JoinGuildError
            { guildId : Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId
            , guild : Evergreen.V402.LocalState.FrontendGuild
            , owner : Evergreen.V402.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V402.RichText.RichText (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V402.RichText.RichText (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V402.Id.Viewing_DiscordDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V402.RichText.RichText (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Maybe Evergreen.V402.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Maybe Evergreen.V402.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V402.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V402.SessionIdHash.SessionIdHash Evergreen.V402.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V402.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V402.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V402.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V402.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V402.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Bool Evergreen.V402.ChannelName.ChannelName (Evergreen.V402.Discord.OptionalData (Maybe String)) (List Evergreen.V402.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
        (Evergreen.V402.NonemptyDict.NonemptyDict
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) Evergreen.V402.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Maybe (Evergreen.V402.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V402.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V402.Log.Log
    | Server_BackupGenerated Evergreen.V402.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V402.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V402.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V402.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V402.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (Evergreen.V402.Discord.OptionalData (Maybe String)) (Evergreen.V402.Discord.OptionalData (Maybe String)) (List Evergreen.V402.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.GuildName.GuildName (Maybe Evergreen.V402.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId) Evergreen.V402.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId) Evergreen.V402.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
        (Evergreen.V402.MembersAndOwner.MembersAndOwner
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.PersonName.PersonName Evergreen.V402.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId) Evergreen.V402.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId) Evergreen.V402.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V402.Call.ServerChange
    | Server_Game (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Game.LocalChange
    | Server_Drawing (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Drawing.AnchorType Evergreen.V402.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V402.Id.Viewing_DmId ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V402.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V402.Id.Viewing_DmId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | Server_E2eeAccepted Evergreen.V402.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
        , sender : Evergreen.V402.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V402.Id.Viewing_DmId
        , content : Evergreen.V402.Encryption.EncryptedData (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
        , threadRoute : Evergreen.V402.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V402.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.Viewing_DmId Evergreen.V402.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V402.FileStatus.FileHash) (Evergreen.V402.Encryption.EncryptedData (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V402.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V402.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V402.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V402.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V402.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V402.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V402.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V402.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V402.Id.AnyGuildOrDmId Evergreen.V402.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V402.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels) (Maybe Evergreen.V402.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V402.SheepGame.Input (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels) (Maybe Evergreen.V402.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V402.Id.GuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V402.Id.GuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V402.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V402.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V402.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , threadRoute : Evergreen.V402.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V402.Encryption.BytesHash
    , id : Evergreen.V402.Id.Viewing_DmId
    , senderId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , threadRoute : Evergreen.V402.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V402.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V402.Id.Viewing_DmId
    , messages : List Evergreen.V402.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V402.Id.Viewing_DmId
    , messages : List ( Evergreen.V402.Id.ThreadRouteWithMessage, Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V402.Id.Viewing_DmId
    , threadRoute : Evergreen.V402.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute )
    , fileId : Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V402.Id.Id Evergreen.V402.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V402.Id.Id Evergreen.V402.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V402.Id.Id Evergreen.V402.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V402.Id.Id Evergreen.V402.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V402.Id.Id Evergreen.V402.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V402.Local.Local LocalMsg Evergreen.V402.LocalState.LocalState
    , admin : Evergreen.V402.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V402.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V402.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.Message.RepliedTo Evergreen.V402.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V402.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V402.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V402.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.ThreadRoute ) (Evergreen.V402.NonemptyDict.NonemptyDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V402.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V402.Scroll.ScrollPosition
    , textEditor : Evergreen.V402.TextEditor.Model
    , profilePictureEditor : Evergreen.V402.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId, Evergreen.V402.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V402.Emoji.Model
    , voiceChat : Evergreen.V402.Call.Model
    , games : SeqDict.SeqDict Evergreen.V402.Id.GuildOrDmId Evergreen.V402.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V402.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , searchOverlayQuery : String
    , searchOverlaySelection : Int
    , showNewPrivateKey : Maybe Evergreen.V402.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V402.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V402.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V402.Range.Range
                , direction : Evergreen.V402.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V402.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V402.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V402.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V402.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V402.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | ProfilePictureEditorToFrontend Evergreen.V402.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V402.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V402.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels
    , visualViewportHeight : Int
    , visualViewportTop : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V402.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V402.MyUi.LastCopy
    , drag : Evergreen.V402.Touch.Drag
    , dragPrevious : Evergreen.V402.Touch.Drag
    , aiChatModel : Evergreen.V402.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V402.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V402.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V402.Audio.LoadError Evergreen.V402.Audio.Source
    , startupData : Evergreen.V402.Ports.StartupData
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
    Evergreen.V402.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V402.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V402.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V402.FileStatus.FileHash
    , metadata : Maybe Evergreen.V402.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId, Evergreen.V402.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId, Evergreen.V402.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V402.DmChannelId.DmChannelId, Evergreen.V402.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId, Evergreen.V402.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId, Evergreen.V402.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId, Evergreen.V402.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V402.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V402.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V402.LocalState.BackupContents
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
    { users : Evergreen.V402.NonemptyDict.NonemptyDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V402.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V402.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V402.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V402.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V402.DmChannelId.DmChannelId Evergreen.V402.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) Evergreen.V402.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.Slack.Id Evergreen.V402.Slack.ChannelId) Evergreen.V402.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V402.OneToOne.OneToOne String (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    , slackUsers : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.Slack.Id Evergreen.V402.Slack.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    , slackServers : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.Slack.Id Evergreen.V402.Slack.TeamId) (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    , slackToken : Maybe Evergreen.V402.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V402.FileStatus.FileHash Evergreen.V402.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V402.FileStatus.FileHash
    , privateVapidKey : Evergreen.V402.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V402.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V402.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId, Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V402.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V402.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V402.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V402.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.LocalState.LoadingDiscordChannel Evergreen.V402.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V402.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V402.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V402.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId) Evergreen.V402.Sticker.StickerData
    , discordStickers : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.Discord.Id Evergreen.V402.Discord.StickerId) (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId) Evergreen.V402.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V402.OneToOne.OneToOne Evergreen.V402.RichText.DiscordCustomEmojiIdAndName (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V402.Postmark.ApiKey
    , serverSecret : Evergreen.V402.SecretId.SecretId Evergreen.V402.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V402.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.GamePublicId) ( Evergreen.V402.DmChannelId.GuildOrFullDmId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V402.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V402.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V402.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.Id.ThreadRoute (Maybe Evergreen.V402.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V402.DmChannelId.DmChannelId Evergreen.V402.Id.ThreadRoute (Maybe Evergreen.V402.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V402.Id.Id Evergreen.V402.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V402.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V402.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V402.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V402.UserAgent.UserAgent
    | AdminToBackend Evergreen.V402.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V402.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V402.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V402.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V402.PersonName.PersonName Evergreen.V402.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V402.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V402.Slack.OAuthCode Evergreen.V402.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V402.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V402.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V402.Id.Id Evergreen.V402.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V402.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V402.EmailAddress.EmailAddress (Result Evergreen.V402.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V402.EmailAddress.EmailAddress (Result Evergreen.V402.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V402.EmailAddress.EmailAddress (Result Evergreen.V402.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V402.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMaybeMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Result Evergreen.V402.Discord.HttpError Evergreen.V402.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V402.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Result Evergreen.V402.Discord.HttpError Evergreen.V402.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) (Result Evergreen.V402.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) (Result Evergreen.V402.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) (Result Evergreen.V402.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) (Result Evergreen.V402.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji (Result Evergreen.V402.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji (Result Evergreen.V402.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji (Result Evergreen.V402.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji (Result Evergreen.V402.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V402.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V402.Discord.HttpError (List ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId, Maybe Evergreen.V402.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Effect.Time.Posix Evergreen.V402.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V402.Slack.CurrentUser
            , team : Evergreen.V402.Slack.Team
            , users : List Evergreen.V402.Slack.User
            , channels : List ( Evergreen.V402.Slack.Channel, List Evergreen.V402.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Result Effect.Http.Error Evergreen.V402.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Discord.UserAuth (Result Evergreen.V402.Discord.HttpError Evergreen.V402.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Result Evergreen.V402.Discord.HttpError Evergreen.V402.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
        (Result
            Evergreen.V402.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId
                    , members : List (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
                    , messages : List Evergreen.V402.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId
                    , { guild : Evergreen.V402.Discord.GatewayGuild
                      , channels : List Evergreen.V402.Discord.Channel
                      , icon : Maybe Evergreen.V402.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (List Evergreen.V402.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V402.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V402.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V402.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V402.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.AttachmentId, Evergreen.V402.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V402.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.AttachmentId, Evergreen.V402.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V402.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V402.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V402.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V402.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (Result Evergreen.V402.Discord.HttpError Evergreen.V402.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Result Evergreen.V402.Discord.HttpError (List Evergreen.V402.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V402.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V402.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V402.DmChannelId.DmChannelId Evergreen.V402.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V402.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V402.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V402.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
        (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V402.Discord.HttpError
            { guild : Evergreen.V402.Discord.GatewayGuild
            , channels : List Evergreen.V402.Discord.Channel
            , icon : Maybe Evergreen.V402.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Maybe Evergreen.V402.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Result Evergreen.V402.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V402.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V402.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (List ( Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId, Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId, Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (List ( Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V402.Discord.HttpError (List Evergreen.V402.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V402.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V402.SecretId.SecretId Evergreen.V402.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V402.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V402.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V402.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V402.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Result Evergreen.V402.Discord.HttpError ( Evergreen.V402.Discord.Guild, List Evergreen.V402.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V402.FileStatus.FileHash Int (Maybe (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Call.CallId
