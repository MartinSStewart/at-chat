module Evergreen.V401.Types exposing (..)

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
import Evergreen.V401.AiChat
import Evergreen.V401.Audio
import Evergreen.V401.BackendMsgLog
import Evergreen.V401.Call
import Evergreen.V401.ChannelDescription
import Evergreen.V401.ChannelName
import Evergreen.V401.Coord
import Evergreen.V401.CssPixels
import Evergreen.V401.CustomEmoji
import Evergreen.V401.Discord
import Evergreen.V401.DiscordAttachmentId
import Evergreen.V401.DiscordUserData
import Evergreen.V401.DmChannel
import Evergreen.V401.DmChannelId
import Evergreen.V401.Drawing
import Evergreen.V401.Editable
import Evergreen.V401.EmailAddress
import Evergreen.V401.Embed
import Evergreen.V401.Emoji
import Evergreen.V401.Encryption
import Evergreen.V401.FileStatus
import Evergreen.V401.Game
import Evergreen.V401.Go
import Evergreen.V401.GuildName
import Evergreen.V401.Id
import Evergreen.V401.IdArray
import Evergreen.V401.ImageEditor
import Evergreen.V401.ImageViewer
import Evergreen.V401.LinkedAndOtherDiscordUsers
import Evergreen.V401.Local
import Evergreen.V401.LocalState
import Evergreen.V401.Log
import Evergreen.V401.LoginForm
import Evergreen.V401.MembersAndOwner
import Evergreen.V401.Message
import Evergreen.V401.MessageInput
import Evergreen.V401.MessageView
import Evergreen.V401.MuteSettings
import Evergreen.V401.MyUi
import Evergreen.V401.NonemptyDict
import Evergreen.V401.NonemptySet
import Evergreen.V401.OneOrGreater
import Evergreen.V401.OneToOne
import Evergreen.V401.Pages.Admin
import Evergreen.V401.Pagination
import Evergreen.V401.PersonName
import Evergreen.V401.Ports
import Evergreen.V401.Postmark
import Evergreen.V401.Range
import Evergreen.V401.RateLimit
import Evergreen.V401.RecoveryLogin
import Evergreen.V401.RichText
import Evergreen.V401.Route
import Evergreen.V401.Scroll
import Evergreen.V401.SecretId
import Evergreen.V401.SessionIdHash
import Evergreen.V401.SetViewing
import Evergreen.V401.SheepGame
import Evergreen.V401.Slack
import Evergreen.V401.Sticker
import Evergreen.V401.TextEditor
import Evergreen.V401.ToBackendLog
import Evergreen.V401.Touch
import Evergreen.V401.TwoFactorAuthentication
import Evergreen.V401.Ui.Anim
import Evergreen.V401.User
import Evergreen.V401.UserAgent
import Evergreen.V401.UserColor
import Evergreen.V401.UserSession
import Evergreen.V401.WordSpellingGame
import Evergreen.V401.X25519
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
    | LoginFormMsg Evergreen.V401.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V401.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V401.Pages.Admin.Msg
    | PressedLogOut Evergreen.V401.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V401.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V401.Route.Route
    | SelectedFilesToAttach ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | PressedImportChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V401.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V401.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V401.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V401.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V401.NonemptyDict.NonemptyDict Int Evergreen.V401.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V401.NonemptyDict.NonemptyDict Int Evergreen.V401.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRoute Evergreen.V401.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V401.NonemptySet.NonemptySet (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String) (Maybe Int)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V401.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V401.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V401.AiChat.Msg
    | GameMsg Evergreen.V401.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V401.Id.GuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V401.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V401.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V401.Editable.Msg Evergreen.V401.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V401.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) (Maybe Evergreen.V401.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute )
        { fileId : Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute )
        { fileId : Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage Evergreen.V401.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V401.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V401.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V401.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V401.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V401.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V401.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V401.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | PressedDisableE2ee (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | TypedPrivateKey (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) String
    | PageHasFocusChanged Bool
    | PageFocusSettled
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V401.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId
        , otherUserId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V401.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRoute Evergreen.V401.MessageInput.Msg
    | MessageInputMsg Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRoute Evergreen.V401.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V401.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V401.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V401.Range.Range, Evergreen.V401.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V401.Range.Range, Evergreen.V401.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V401.Call.FromJs)
    | VoiceChatMsg Evergreen.V401.Call.Msg
    | PressedChannelHeaderTab Evergreen.V401.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V401.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V401.Audio.LoadError Evergreen.V401.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V401.Id.AnyGuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V401.Id.AnyGuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) Evergreen.V401.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V401.Encryption.FromJs (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V401.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V401.UserSession.UserSession
    , currentlyViewing : Evergreen.V401.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) Evergreen.V401.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.LocalState.DiscordFrontendGuild
    , user : Evergreen.V401.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.User.FrontendUser
    , discordUsers : Evergreen.V401.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V401.SessionIdHash.SessionIdHash Evergreen.V401.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V401.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId) Evergreen.V401.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId) Evergreen.V401.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V401.Call.CallId (Evergreen.V401.NonemptyDict.NonemptyDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V401.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V401.Go.PublicGoMatchData Evergreen.V401.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V401.Route.Route
    , windowSize : Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V401.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V401.Audio.LoadError Evergreen.V401.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Encryption.EncryptedData (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.NonemptyDict.NonemptyDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Encryption.EncryptedData (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V401.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V401.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V401.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData) (List Evergreen.V401.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V401.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V401.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.ChannelName.ChannelName Evergreen.V401.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.ChannelName.ChannelName Evergreen.V401.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.UserSession.ToBeFilledInByBackend (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V401.GuildName.GuildName (Evergreen.V401.UserSession.ToBeFilledInByBackend (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V401.Id.Viewing_DiscordDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V401.SetViewing.SetViewing
    | Local_SetName Evergreen.V401.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V401.Id.GuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.UserSession.ToBeFilledInByBackend Evergreen.V401.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V401.Id.GuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V401.Id.DiscordGuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V401.Id.DiscordGuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V401.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V401.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V401.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.QuestionId Evergreen.V401.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V401.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V401.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V401.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V401.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V401.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V401.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V401.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V401.NonemptySet.NonemptySet (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V401.Call.LocalChange
    | Local_Game Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Game.LocalChange
    | Local_Drawing Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Drawing.AnchorType Evergreen.V401.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V401.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V401.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V401.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V401.X25519.PublicKey (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V401.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V401.Id.Viewing_DmId (List ( Evergreen.V401.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V401.FileStatus.FileHash, Evergreen.V401.Encryption.EncryptedData (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V401.Id.Viewing_DmId (Evergreen.V401.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V401.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V401.Id.ThreadRouteWithMessage, Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V401.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V401.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V401.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V401.FileStatus.FileHash) (Evergreen.V401.Encryption.EncryptedData (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))) (Evergreen.V401.Encryption.EncryptedData String) Evergreen.V401.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V401.Id.Viewing_DmId Evergreen.V401.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V401.FileStatus.FileHash) (Evergreen.V401.Encryption.EncryptedData (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    | RepliedToGame Evergreen.V401.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
        , sender : Evergreen.V401.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V401.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V401.RichText.RichText (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
        , threadRoute : Evergreen.V401.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId) Evergreen.V401.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V401.Id.DiscordGuildOrDmId Evergreen.V401.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V401.RichText.RichText (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))) Evergreen.V401.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId) Evergreen.V401.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.ChannelName.ChannelName Evergreen.V401.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.ChannelName.ChannelName Evergreen.V401.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.User.FrontendUser
    | Server_MemberLeft (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V401.LocalState.JoinGuildError
            { guildId : Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId
            , guild : Evergreen.V401.LocalState.FrontendGuild
            , owner : Evergreen.V401.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V401.RichText.RichText (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V401.RichText.RichText (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V401.Id.Viewing_DiscordDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V401.RichText.RichText (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Maybe Evergreen.V401.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Maybe Evergreen.V401.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V401.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V401.SessionIdHash.SessionIdHash Evergreen.V401.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V401.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V401.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V401.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V401.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V401.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Bool Evergreen.V401.ChannelName.ChannelName (Evergreen.V401.Discord.OptionalData (Maybe String)) (List Evergreen.V401.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
        (Evergreen.V401.NonemptyDict.NonemptyDict
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) Evergreen.V401.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Maybe (Evergreen.V401.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V401.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V401.Log.Log
    | Server_BackupGenerated Evergreen.V401.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V401.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V401.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V401.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V401.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (Evergreen.V401.Discord.OptionalData (Maybe String)) (Evergreen.V401.Discord.OptionalData (Maybe String)) (List Evergreen.V401.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.GuildName.GuildName (Maybe Evergreen.V401.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId) Evergreen.V401.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId) Evergreen.V401.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
        (Evergreen.V401.MembersAndOwner.MembersAndOwner
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.PersonName.PersonName Evergreen.V401.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId) Evergreen.V401.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId) Evergreen.V401.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V401.Call.ServerChange
    | Server_Game (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Game.LocalChange
    | Server_Drawing (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Drawing.AnchorType Evergreen.V401.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V401.Id.Viewing_DmId ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V401.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V401.Id.Viewing_DmId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | Server_E2eeAccepted Evergreen.V401.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
        , sender : Evergreen.V401.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V401.Id.Viewing_DmId
        , content : Evergreen.V401.Encryption.EncryptedData (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
        , threadRoute : Evergreen.V401.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V401.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.Viewing_DmId Evergreen.V401.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V401.FileStatus.FileHash) (Evergreen.V401.Encryption.EncryptedData (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V401.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V401.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V401.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V401.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V401.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V401.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V401.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V401.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions
    | ReactionPopup Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage Int


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V401.Id.AnyGuildOrDmId Evergreen.V401.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V401.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels) (Maybe Evergreen.V401.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V401.SheepGame.Input (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels) (Maybe Evergreen.V401.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V401.Id.GuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V401.Id.GuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V401.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V401.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V401.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , threadRoute : Evergreen.V401.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V401.Encryption.BytesHash
    , id : Evergreen.V401.Id.Viewing_DmId
    , senderId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , threadRoute : Evergreen.V401.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V401.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V401.Id.Viewing_DmId
    , messages : List Evergreen.V401.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V401.Id.Viewing_DmId
    , messages : List ( Evergreen.V401.Id.ThreadRouteWithMessage, Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V401.Id.Viewing_DmId
    , threadRoute : Evergreen.V401.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute )
    , fileId : Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V401.Id.Id Evergreen.V401.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V401.Id.Id Evergreen.V401.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V401.Id.Id Evergreen.V401.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V401.Id.Id Evergreen.V401.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V401.Id.Id Evergreen.V401.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V401.Local.Local LocalMsg Evergreen.V401.LocalState.LocalState
    , admin : Evergreen.V401.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V401.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V401.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.Message.RepliedTo Evergreen.V401.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V401.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V401.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V401.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.ThreadRoute ) (Evergreen.V401.NonemptyDict.NonemptyDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V401.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V401.Scroll.ScrollPosition
    , textEditor : Evergreen.V401.TextEditor.Model
    , profilePictureEditor : Evergreen.V401.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId, Evergreen.V401.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V401.Emoji.Model
    , voiceChat : Evergreen.V401.Call.Model
    , games : SeqDict.SeqDict Evergreen.V401.Id.GuildOrDmId Evergreen.V401.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V401.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V401.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V401.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V401.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V401.Range.Range
                , direction : Evergreen.V401.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V401.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V401.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V401.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V401.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V401.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | ProfilePictureEditorToFrontend Evergreen.V401.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V401.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V401.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V401.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V401.MyUi.LastCopy
    , drag : Evergreen.V401.Touch.Drag
    , dragPrevious : Evergreen.V401.Touch.Drag
    , aiChatModel : Evergreen.V401.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V401.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V401.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V401.Audio.LoadError Evergreen.V401.Audio.Source
    , startupData : Evergreen.V401.Ports.StartupData
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
    Evergreen.V401.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V401.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V401.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V401.FileStatus.FileHash
    , metadata : Maybe Evergreen.V401.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId, Evergreen.V401.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId, Evergreen.V401.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V401.DmChannelId.DmChannelId, Evergreen.V401.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId, Evergreen.V401.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId, Evergreen.V401.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId, Evergreen.V401.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V401.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V401.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V401.LocalState.BackupContents
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
    { users : Evergreen.V401.NonemptyDict.NonemptyDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V401.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V401.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V401.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V401.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V401.DmChannelId.DmChannelId Evergreen.V401.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) Evergreen.V401.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.Slack.Id Evergreen.V401.Slack.ChannelId) Evergreen.V401.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V401.OneToOne.OneToOne String (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    , slackUsers : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.Slack.Id Evergreen.V401.Slack.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    , slackServers : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.Slack.Id Evergreen.V401.Slack.TeamId) (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    , slackToken : Maybe Evergreen.V401.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V401.FileStatus.FileHash Evergreen.V401.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V401.FileStatus.FileHash
    , privateVapidKey : Evergreen.V401.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V401.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V401.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId, Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V401.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V401.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V401.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V401.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.LocalState.LoadingDiscordChannel Evergreen.V401.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V401.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V401.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V401.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId) Evergreen.V401.Sticker.StickerData
    , discordStickers : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.Discord.Id Evergreen.V401.Discord.StickerId) (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId) Evergreen.V401.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V401.OneToOne.OneToOne Evergreen.V401.RichText.DiscordCustomEmojiIdAndName (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V401.Postmark.ApiKey
    , serverSecret : Evergreen.V401.SecretId.SecretId Evergreen.V401.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V401.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.GamePublicId) ( Evergreen.V401.DmChannelId.GuildOrFullDmId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V401.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V401.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V401.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.Id.ThreadRoute (Maybe Evergreen.V401.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V401.DmChannelId.DmChannelId Evergreen.V401.Id.ThreadRoute (Maybe Evergreen.V401.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V401.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V401.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V401.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V401.UserAgent.UserAgent
    | AdminToBackend Evergreen.V401.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V401.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V401.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V401.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V401.PersonName.PersonName Evergreen.V401.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V401.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V401.Slack.OAuthCode Evergreen.V401.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V401.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V401.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V401.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V401.EmailAddress.EmailAddress (Result Evergreen.V401.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V401.EmailAddress.EmailAddress (Result Evergreen.V401.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V401.EmailAddress.EmailAddress (Result Evergreen.V401.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V401.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMaybeMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Result Evergreen.V401.Discord.HttpError Evergreen.V401.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V401.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Result Evergreen.V401.Discord.HttpError Evergreen.V401.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) (Result Evergreen.V401.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) (Result Evergreen.V401.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) (Result Evergreen.V401.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) (Result Evergreen.V401.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji (Result Evergreen.V401.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji (Result Evergreen.V401.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji (Result Evergreen.V401.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji (Result Evergreen.V401.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V401.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V401.Discord.HttpError (List ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId, Maybe Evergreen.V401.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Effect.Time.Posix Evergreen.V401.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V401.Slack.CurrentUser
            , team : Evergreen.V401.Slack.Team
            , users : List Evergreen.V401.Slack.User
            , channels : List ( Evergreen.V401.Slack.Channel, List Evergreen.V401.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Result Effect.Http.Error Evergreen.V401.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Discord.UserAuth (Result Evergreen.V401.Discord.HttpError Evergreen.V401.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Result Evergreen.V401.Discord.HttpError Evergreen.V401.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
        (Result
            Evergreen.V401.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId
                    , members : List (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
                    , messages : List Evergreen.V401.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId
                    , { guild : Evergreen.V401.Discord.GatewayGuild
                      , channels : List Evergreen.V401.Discord.Channel
                      , icon : Maybe Evergreen.V401.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (List Evergreen.V401.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V401.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V401.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V401.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V401.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.AttachmentId, Evergreen.V401.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V401.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.AttachmentId, Evergreen.V401.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V401.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V401.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V401.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V401.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (Result Evergreen.V401.Discord.HttpError Evergreen.V401.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Result Evergreen.V401.Discord.HttpError (List Evergreen.V401.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V401.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V401.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V401.DmChannelId.DmChannelId Evergreen.V401.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V401.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V401.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V401.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
        (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V401.Discord.HttpError
            { guild : Evergreen.V401.Discord.GatewayGuild
            , channels : List Evergreen.V401.Discord.Channel
            , icon : Maybe Evergreen.V401.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Maybe Evergreen.V401.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Result Evergreen.V401.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V401.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V401.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (List ( Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId, Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId, Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (List ( Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V401.Discord.HttpError (List Evergreen.V401.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V401.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V401.SecretId.SecretId Evergreen.V401.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V401.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V401.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V401.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V401.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Result Evergreen.V401.Discord.HttpError ( Evergreen.V401.Discord.Guild, List Evergreen.V401.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V401.FileStatus.FileHash Int (Maybe (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Call.CallId
