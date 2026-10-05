module Evergreen.V398.Types exposing (..)

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
import Evergreen.V398.AiChat
import Evergreen.V398.Audio
import Evergreen.V398.BackendMsgLog
import Evergreen.V398.Call
import Evergreen.V398.ChannelDescription
import Evergreen.V398.ChannelName
import Evergreen.V398.Coord
import Evergreen.V398.CssPixels
import Evergreen.V398.CustomEmoji
import Evergreen.V398.Discord
import Evergreen.V398.DiscordAttachmentId
import Evergreen.V398.DiscordUserData
import Evergreen.V398.DmChannel
import Evergreen.V398.DmChannelId
import Evergreen.V398.Drawing
import Evergreen.V398.Editable
import Evergreen.V398.EmailAddress
import Evergreen.V398.Embed
import Evergreen.V398.Emoji
import Evergreen.V398.Encryption
import Evergreen.V398.FileStatus
import Evergreen.V398.Game
import Evergreen.V398.Go
import Evergreen.V398.GuildName
import Evergreen.V398.Id
import Evergreen.V398.IdArray
import Evergreen.V398.ImageEditor
import Evergreen.V398.ImageViewer
import Evergreen.V398.LinkedAndOtherDiscordUsers
import Evergreen.V398.Local
import Evergreen.V398.LocalState
import Evergreen.V398.Log
import Evergreen.V398.LoginForm
import Evergreen.V398.MembersAndOwner
import Evergreen.V398.Message
import Evergreen.V398.MessageInput
import Evergreen.V398.MessageView
import Evergreen.V398.MuteSettings
import Evergreen.V398.MyUi
import Evergreen.V398.NonemptyDict
import Evergreen.V398.NonemptySet
import Evergreen.V398.OneOrGreater
import Evergreen.V398.OneToOne
import Evergreen.V398.Pages.Admin
import Evergreen.V398.Pagination
import Evergreen.V398.PersonName
import Evergreen.V398.Ports
import Evergreen.V398.Postmark
import Evergreen.V398.Range
import Evergreen.V398.RateLimit
import Evergreen.V398.RecoveryLogin
import Evergreen.V398.RichText
import Evergreen.V398.Route
import Evergreen.V398.Scroll
import Evergreen.V398.SecretId
import Evergreen.V398.SessionIdHash
import Evergreen.V398.SetViewing
import Evergreen.V398.SheepGame
import Evergreen.V398.Slack
import Evergreen.V398.Sticker
import Evergreen.V398.TextEditor
import Evergreen.V398.ToBackendLog
import Evergreen.V398.Touch
import Evergreen.V398.TwoFactorAuthentication
import Evergreen.V398.Ui.Anim
import Evergreen.V398.User
import Evergreen.V398.UserAgent
import Evergreen.V398.UserColor
import Evergreen.V398.UserSession
import Evergreen.V398.WordSpellingGame
import Evergreen.V398.X25519
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
    | LoginFormMsg Evergreen.V398.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V398.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V398.Pages.Admin.Msg
    | PressedLogOut Evergreen.V398.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V398.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V398.Route.Route
    | SelectedFilesToAttach ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | PressedImportChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V398.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V398.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V398.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V398.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V398.NonemptyDict.NonemptyDict Int Evergreen.V398.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V398.NonemptyDict.NonemptyDict Int Evergreen.V398.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRoute Evergreen.V398.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V398.NonemptySet.NonemptySet (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V398.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V398.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V398.AiChat.Msg
    | GameMsg Evergreen.V398.Game.Msg
    | CheckedSheepGameSaveDebounce Evergreen.V398.Id.GuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.SheepGame.Input Int
    | CheckedSheepGameQuestionsDebounce Evergreen.V398.Id.GuildOrDmId Int
    | GoSpectatorMsg Evergreen.V398.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V398.Editable.Msg Evergreen.V398.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V398.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) (Maybe Evergreen.V398.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute )
        { fileId : Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute )
        { fileId : Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage Evergreen.V398.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V398.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V398.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V398.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V398.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V398.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V398.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V398.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | PressedDisableE2ee (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | TypedPrivateKey (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) String
    | PageHasFocusChanged Bool
    | PageFocusSettled
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V398.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId
        , otherUserId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V398.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRoute Evergreen.V398.MessageInput.Msg
    | MessageInputMsg Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRoute Evergreen.V398.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V398.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V398.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V398.Range.Range, Evergreen.V398.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V398.Range.Range, Evergreen.V398.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V398.Call.FromJs)
    | VoiceChatMsg Evergreen.V398.Call.Msg
    | PressedChannelHeaderTab Evergreen.V398.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V398.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V398.Audio.LoadError Evergreen.V398.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V398.Id.AnyGuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V398.Id.AnyGuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) Evergreen.V398.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V398.Encryption.FromJs (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V398.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V398.UserSession.UserSession
    , currentlyViewing : Evergreen.V398.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) Evergreen.V398.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.LocalState.DiscordFrontendGuild
    , user : Evergreen.V398.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.User.FrontendUser
    , discordUsers : Evergreen.V398.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V398.SessionIdHash.SessionIdHash Evergreen.V398.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V398.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId) Evergreen.V398.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId) Evergreen.V398.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V398.Call.CallId (Evergreen.V398.NonemptyDict.NonemptyDict ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V398.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V398.Go.PublicGoMatchData Evergreen.V398.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V398.Route.Route
    , windowSize : Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V398.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V398.Audio.LoadError Evergreen.V398.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Encryption.EncryptedData (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.NonemptyDict.NonemptyDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.Encryption.EncryptedData (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V398.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V398.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V398.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileData) (List Evergreen.V398.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V398.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V398.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.ChannelName.ChannelName Evergreen.V398.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.ChannelName.ChannelName Evergreen.V398.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.UserSession.ToBeFilledInByBackend (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V398.GuildName.GuildName (Evergreen.V398.UserSession.ToBeFilledInByBackend (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V398.Id.Viewing_DiscordDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V398.SetViewing.SetViewing
    | Local_SetName Evergreen.V398.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V398.Id.GuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.UserSession.ToBeFilledInByBackend Evergreen.V398.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V398.Id.GuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.Message.Message Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V398.Id.DiscordGuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V398.Id.DiscordGuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.Message.Message Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V398.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V398.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V398.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.QuestionId Evergreen.V398.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V398.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V398.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V398.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V398.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V398.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V398.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V398.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V398.NonemptySet.NonemptySet (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V398.Call.LocalChange
    | Local_Game Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Game.LocalChange
    | Local_Drawing Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Drawing.AnchorType Evergreen.V398.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V398.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V398.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V398.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V398.X25519.PublicKey (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V398.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V398.Id.Viewing_DmId (List ( Evergreen.V398.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V398.FileStatus.FileHash, Evergreen.V398.Encryption.EncryptedData (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V398.Id.Viewing_DmId (Evergreen.V398.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V398.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V398.Id.ThreadRouteWithMessage, Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V398.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V398.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V398.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V398.FileStatus.FileHash) (Evergreen.V398.Encryption.EncryptedData (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))) (Evergreen.V398.Encryption.EncryptedData String) Evergreen.V398.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V398.Id.Viewing_DmId Evergreen.V398.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V398.FileStatus.FileHash) (Evergreen.V398.Encryption.EncryptedData (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)))


type RepliedToData
    = NoReplyData
    | RepliedToMessage (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    | RepliedToThreadMessage (Evergreen.V398.Message.Message Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    | RepliedToGame Evergreen.V398.Game.LoadedMatch


type ServerChange
    = Server_SendMessage
        { senderId : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
        , sender : Evergreen.V398.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , guildOrDmId : Evergreen.V398.Id.GuildOrDmId
        , content : List.Nonempty.Nonempty (Evergreen.V398.RichText.RichText (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
        , threadRoute : Evergreen.V398.Message.ThreadRouteWithRepliedTo
        , attachedFiles : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileData
        , stickers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId) Evergreen.V398.Sticker.StickerData
        , repliedToData : RepliedToData
        }
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V398.Id.DiscordGuildOrDmId Evergreen.V398.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V398.RichText.RichText (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))) Evergreen.V398.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId) Evergreen.V398.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.ChannelName.ChannelName Evergreen.V398.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.ChannelName.ChannelName Evergreen.V398.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.User.FrontendUser
    | Server_MemberLeft (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V398.LocalState.JoinGuildError
            { guildId : Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId
            , guild : Evergreen.V398.LocalState.FrontendGuild
            , owner : Evergreen.V398.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V398.RichText.RichText (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V398.RichText.RichText (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V398.Id.Viewing_DiscordDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V398.RichText.RichText (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Maybe Evergreen.V398.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Maybe Evergreen.V398.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V398.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V398.SessionIdHash.SessionIdHash Evergreen.V398.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V398.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V398.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V398.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V398.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V398.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Bool Evergreen.V398.ChannelName.ChannelName (Evergreen.V398.Discord.OptionalData (Maybe String)) (List Evergreen.V398.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
        (Evergreen.V398.NonemptyDict.NonemptyDict
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) Evergreen.V398.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Maybe (Evergreen.V398.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V398.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V398.Log.Log
    | Server_BackupGenerated Evergreen.V398.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V398.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V398.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V398.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V398.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (Evergreen.V398.Discord.OptionalData (Maybe String)) (Evergreen.V398.Discord.OptionalData (Maybe String)) (List Evergreen.V398.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.GuildName.GuildName (Maybe Evergreen.V398.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId) Evergreen.V398.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId) Evergreen.V398.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
        (Evergreen.V398.MembersAndOwner.MembersAndOwner
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.PersonName.PersonName Evergreen.V398.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId) Evergreen.V398.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId) Evergreen.V398.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V398.Call.ServerChange
    | Server_Game (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Game.LocalChange
    | Server_Drawing (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Drawing.AnchorType Evergreen.V398.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V398.Id.Viewing_DmId ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Evergreen.V398.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V398.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V398.Id.Viewing_DmId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | Server_E2eeAccepted Evergreen.V398.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.X25519.PublicKey
    | Server_SendEncryptedMessage
        { senderId : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
        , sender : Evergreen.V398.User.FrontendUser
        , sentAt : Effect.Time.Posix
        , id : Evergreen.V398.Id.Viewing_DmId
        , content : Evergreen.V398.Encryption.EncryptedData (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
        , threadRoute : Evergreen.V398.Message.ThreadRouteWithRepliedTo
        , fileHashes : SeqSet.SeqSet Evergreen.V398.FileStatus.FileHash
        , repliedToData : RepliedToData
        }
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.Viewing_DmId Evergreen.V398.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V398.FileStatus.FileHash) (Evergreen.V398.Encryption.EncryptedData (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V398.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V398.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V398.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V398.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V398.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V398.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V398.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V398.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V398.Id.AnyGuildOrDmId Evergreen.V398.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V398.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels) (Maybe Evergreen.V398.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V398.SheepGame.Input (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels) (Maybe Evergreen.V398.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V398.Id.GuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V398.Id.GuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId) (Evergreen.V398.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V398.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V398.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V398.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , threadRoute : Evergreen.V398.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V398.Encryption.BytesHash
    , id : Evergreen.V398.Id.Viewing_DmId
    , senderId : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , threadRoute : Evergreen.V398.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V398.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V398.Id.Viewing_DmId
    , messages : List Evergreen.V398.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V398.Id.Viewing_DmId
    , messages : List ( Evergreen.V398.Id.ThreadRouteWithMessage, Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V398.Id.Viewing_DmId
    , threadRoute : Evergreen.V398.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute )
    , fileId : Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V398.Id.Id Evergreen.V398.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V398.Id.Id Evergreen.V398.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V398.Id.Id Evergreen.V398.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V398.Id.Id Evergreen.V398.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V398.Id.Id Evergreen.V398.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V398.Local.Local LocalMsg Evergreen.V398.LocalState.LocalState
    , admin : Evergreen.V398.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId, Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V398.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V398.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.Message.RepliedTo Evergreen.V398.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V398.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V398.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V398.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.ThreadRoute ) (Evergreen.V398.NonemptyDict.NonemptyDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V398.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V398.Scroll.ScrollPosition
    , textEditor : Evergreen.V398.TextEditor.Model
    , profilePictureEditor : Evergreen.V398.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId, Evergreen.V398.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V398.Emoji.Model
    , voiceChat : Evergreen.V398.Call.Model
    , games : SeqDict.SeqDict Evergreen.V398.Id.GuildOrDmId Evergreen.V398.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V398.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V398.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V398.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V398.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V398.Range.Range
                , direction : Evergreen.V398.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V398.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V398.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V398.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V398.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V398.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | ProfilePictureEditorToFrontend Evergreen.V398.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V398.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V398.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V398.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V398.MyUi.LastCopy
    , drag : Evergreen.V398.Touch.Drag
    , dragPrevious : Evergreen.V398.Touch.Drag
    , aiChatModel : Evergreen.V398.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V398.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V398.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V398.Audio.LoadError Evergreen.V398.Audio.Source
    , startupData : Evergreen.V398.Ports.StartupData
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
    Evergreen.V398.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V398.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V398.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V398.FileStatus.FileHash
    , metadata : Maybe Evergreen.V398.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId, Evergreen.V398.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId, Evergreen.V398.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V398.DmChannelId.DmChannelId, Evergreen.V398.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId, Evergreen.V398.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId, Evergreen.V398.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId, Evergreen.V398.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V398.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V398.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V398.LocalState.BackupContents
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
    { users : Evergreen.V398.NonemptyDict.NonemptyDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V398.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V398.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V398.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V398.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V398.DmChannelId.DmChannelId Evergreen.V398.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) Evergreen.V398.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.Slack.Id Evergreen.V398.Slack.ChannelId) Evergreen.V398.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V398.OneToOne.OneToOne String (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    , slackUsers : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.Slack.Id Evergreen.V398.Slack.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    , slackServers : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.Slack.Id Evergreen.V398.Slack.TeamId) (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    , slackToken : Maybe Evergreen.V398.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V398.FileStatus.FileHash Evergreen.V398.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V398.FileStatus.FileHash
    , privateVapidKey : Evergreen.V398.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V398.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V398.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId, Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V398.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V398.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V398.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V398.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.LocalState.LoadingDiscordChannel Evergreen.V398.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V398.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V398.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V398.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId) Evergreen.V398.Sticker.StickerData
    , discordStickers : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.Discord.Id Evergreen.V398.Discord.StickerId) (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId) Evergreen.V398.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V398.OneToOne.OneToOne Evergreen.V398.RichText.DiscordCustomEmojiIdAndName (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V398.Postmark.ApiKey
    , serverSecret : Evergreen.V398.SecretId.SecretId Evergreen.V398.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V398.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.GamePublicId) ( Evergreen.V398.DmChannelId.GuildOrFullDmId, Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V398.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V398.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V398.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.Id.ThreadRoute (Maybe Evergreen.V398.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V398.DmChannelId.DmChannelId Evergreen.V398.Id.ThreadRoute (Maybe Evergreen.V398.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V398.Id.Id Evergreen.V398.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V398.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V398.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V398.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V398.UserAgent.UserAgent
    | AdminToBackend Evergreen.V398.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V398.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V398.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V398.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V398.PersonName.PersonName Evergreen.V398.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V398.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V398.Slack.OAuthCode Evergreen.V398.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V398.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V398.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V398.Id.Id Evergreen.V398.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V398.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V398.EmailAddress.EmailAddress (Result Evergreen.V398.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V398.EmailAddress.EmailAddress (Result Evergreen.V398.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V398.EmailAddress.EmailAddress (Result Evergreen.V398.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V398.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMaybeMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Result Evergreen.V398.Discord.HttpError Evergreen.V398.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V398.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Result Evergreen.V398.Discord.HttpError Evergreen.V398.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) (Result Evergreen.V398.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) (Result Evergreen.V398.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) (Result Evergreen.V398.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) (Result Evergreen.V398.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji (Result Evergreen.V398.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji (Result Evergreen.V398.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji (Result Evergreen.V398.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji (Result Evergreen.V398.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V398.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V398.Discord.HttpError (List ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId, Maybe Evergreen.V398.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Effect.Time.Posix Evergreen.V398.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V398.Slack.CurrentUser
            , team : Evergreen.V398.Slack.Team
            , users : List Evergreen.V398.Slack.User
            , channels : List ( Evergreen.V398.Slack.Channel, List Evergreen.V398.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Result Effect.Http.Error Evergreen.V398.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Discord.UserAuth (Result Evergreen.V398.Discord.HttpError Evergreen.V398.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Result Evergreen.V398.Discord.HttpError Evergreen.V398.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
        (Result
            Evergreen.V398.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId
                    , members : List (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
                    , messages : List Evergreen.V398.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId
                    , { guild : Evergreen.V398.Discord.GatewayGuild
                      , channels : List Evergreen.V398.Discord.Channel
                      , icon : Maybe Evergreen.V398.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (List Evergreen.V398.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V398.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V398.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V398.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V398.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.AttachmentId, Evergreen.V398.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V398.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.AttachmentId, Evergreen.V398.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V398.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V398.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V398.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V398.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (Result Evergreen.V398.Discord.HttpError Evergreen.V398.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Result Evergreen.V398.Discord.HttpError (List Evergreen.V398.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V398.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V398.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V398.DmChannelId.DmChannelId Evergreen.V398.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V398.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V398.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V398.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
        (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V398.Discord.HttpError
            { guild : Evergreen.V398.Discord.GatewayGuild
            , channels : List Evergreen.V398.Discord.Channel
            , icon : Maybe Evergreen.V398.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Maybe Evergreen.V398.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Result Evergreen.V398.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V398.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V398.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (List ( Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId, Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId, Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (List ( Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V398.Discord.HttpError (List Evergreen.V398.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V398.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V398.SecretId.SecretId Evergreen.V398.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V398.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V398.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V398.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V398.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Result Evergreen.V398.Discord.HttpError ( Evergreen.V398.Discord.Guild, List Evergreen.V398.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V398.FileStatus.FileHash Int (Maybe (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Call.CallId
