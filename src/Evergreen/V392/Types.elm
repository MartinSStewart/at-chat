module Evergreen.V392.Types exposing (..)

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
import Evergreen.V392.AiChat
import Evergreen.V392.Audio
import Evergreen.V392.BackendMsgLog
import Evergreen.V392.Call
import Evergreen.V392.ChannelDescription
import Evergreen.V392.ChannelName
import Evergreen.V392.Coord
import Evergreen.V392.CssPixels
import Evergreen.V392.CustomEmoji
import Evergreen.V392.Discord
import Evergreen.V392.DiscordAttachmentId
import Evergreen.V392.DiscordUserData
import Evergreen.V392.DmChannel
import Evergreen.V392.DmChannelId
import Evergreen.V392.Drawing
import Evergreen.V392.Editable
import Evergreen.V392.EmailAddress
import Evergreen.V392.Embed
import Evergreen.V392.Emoji
import Evergreen.V392.Encryption
import Evergreen.V392.FileStatus
import Evergreen.V392.Game
import Evergreen.V392.Go
import Evergreen.V392.GuildName
import Evergreen.V392.Id
import Evergreen.V392.IdArray
import Evergreen.V392.ImageEditor
import Evergreen.V392.ImageViewer
import Evergreen.V392.LinkedAndOtherDiscordUsers
import Evergreen.V392.Local
import Evergreen.V392.LocalState
import Evergreen.V392.Log
import Evergreen.V392.LoginForm
import Evergreen.V392.MembersAndOwner
import Evergreen.V392.Message
import Evergreen.V392.MessageInput
import Evergreen.V392.MessageView
import Evergreen.V392.MuteSettings
import Evergreen.V392.MyUi
import Evergreen.V392.NonemptyDict
import Evergreen.V392.NonemptySet
import Evergreen.V392.OneOrGreater
import Evergreen.V392.OneToOne
import Evergreen.V392.Pages.Admin
import Evergreen.V392.Pagination
import Evergreen.V392.PersonName
import Evergreen.V392.Ports
import Evergreen.V392.Postmark
import Evergreen.V392.Range
import Evergreen.V392.RateLimit
import Evergreen.V392.RecoveryLogin
import Evergreen.V392.RichText
import Evergreen.V392.Route
import Evergreen.V392.Scroll
import Evergreen.V392.SecretId
import Evergreen.V392.SessionIdHash
import Evergreen.V392.SetViewing
import Evergreen.V392.SheepGame
import Evergreen.V392.Slack
import Evergreen.V392.Sticker
import Evergreen.V392.TextEditor
import Evergreen.V392.ToBackendLog
import Evergreen.V392.Touch
import Evergreen.V392.TwoFactorAuthentication
import Evergreen.V392.Ui.Anim
import Evergreen.V392.User
import Evergreen.V392.UserAgent
import Evergreen.V392.UserColor
import Evergreen.V392.UserSession
import Evergreen.V392.WordSpellingGame
import Evergreen.V392.X25519
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
    | LoginFormMsg Evergreen.V392.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V392.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V392.Pages.Admin.Msg
    | PressedLogOut Evergreen.V392.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V392.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V392.Route.Route
    | SelectedFilesToAttach ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | PressedImportChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V392.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V392.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V392.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V392.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V392.NonemptyDict.NonemptyDict Int Evergreen.V392.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V392.NonemptyDict.NonemptyDict Int Evergreen.V392.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRoute Evergreen.V392.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V392.NonemptySet.NonemptySet (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V392.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V392.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V392.AiChat.Msg
    | GameMsg Evergreen.V392.Game.Msg
    | GoSpectatorMsg Evergreen.V392.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V392.Editable.Msg Evergreen.V392.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V392.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) (Maybe Evergreen.V392.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute )
        { fileId : Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute )
        { fileId : Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage Evergreen.V392.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V392.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V392.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V392.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V392.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V392.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V392.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V392.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | PressedDisableE2ee (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | TypedPrivateKey (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V392.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId
        , otherUserId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V392.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRoute Evergreen.V392.MessageInput.Msg
    | MessageInputMsg Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRoute Evergreen.V392.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V392.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V392.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V392.Range.Range, Evergreen.V392.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V392.Range.Range, Evergreen.V392.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V392.Call.FromJs)
    | VoiceChatMsg Evergreen.V392.Call.Msg
    | PressedChannelHeaderTab Evergreen.V392.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V392.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V392.Audio.LoadError Evergreen.V392.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V392.Id.AnyGuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V392.Id.AnyGuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) Evergreen.V392.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V392.Encryption.FromJs (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V392.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V392.UserSession.UserSession
    , currentlyViewing : Evergreen.V392.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) Evergreen.V392.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.LocalState.DiscordFrontendGuild
    , user : Evergreen.V392.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.User.FrontendUser
    , discordUsers : Evergreen.V392.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V392.SessionIdHash.SessionIdHash Evergreen.V392.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V392.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId) Evergreen.V392.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId) Evergreen.V392.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V392.Call.CallId (Evergreen.V392.NonemptyDict.NonemptyDict ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V392.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V392.Go.PublicGoMatchData Evergreen.V392.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V392.Route.Route
    , windowSize : Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V392.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V392.Audio.LoadError Evergreen.V392.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Encryption.EncryptedData (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.NonemptyDict.NonemptyDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.Encryption.EncryptedData (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V392.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V392.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V392.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData) (List Evergreen.V392.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V392.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V392.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.ChannelName.ChannelName Evergreen.V392.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.ChannelName.ChannelName Evergreen.V392.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.UserSession.ToBeFilledInByBackend (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V392.GuildName.GuildName (Evergreen.V392.UserSession.ToBeFilledInByBackend (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V392.Id.Viewing_DiscordDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V392.SetViewing.SetViewing
    | Local_SetName Evergreen.V392.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V392.Id.GuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.UserSession.ToBeFilledInByBackend Evergreen.V392.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V392.Id.GuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.Message.Message Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V392.Id.DiscordGuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V392.Id.DiscordGuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.Message.Message Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V392.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V392.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V392.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.QuestionId Evergreen.V392.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V392.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V392.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V392.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V392.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V392.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V392.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V392.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V392.NonemptySet.NonemptySet (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V392.Call.LocalChange
    | Local_Game Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Game.LocalChange
    | Local_Drawing Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Drawing.AnchorType Evergreen.V392.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V392.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V392.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V392.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V392.X25519.PublicKey (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V392.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V392.Id.Viewing_DmId (List ( Evergreen.V392.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V392.FileStatus.FileHash, Evergreen.V392.Encryption.EncryptedData (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V392.Id.Viewing_DmId (Evergreen.V392.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V392.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V392.Id.ThreadRouteWithMessage, Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V392.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V392.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V392.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V392.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V392.FileStatus.FileHash) (Evergreen.V392.Encryption.EncryptedData (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))) (Evergreen.V392.Encryption.EncryptedData String) Evergreen.V392.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V392.Id.Viewing_DmId Evergreen.V392.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V392.FileStatus.FileHash) (Evergreen.V392.Encryption.EncryptedData (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.User.FrontendUser Effect.Time.Posix Evergreen.V392.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V392.RichText.RichText (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))) Evergreen.V392.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId) Evergreen.V392.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V392.Id.DiscordGuildOrDmId Evergreen.V392.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V392.RichText.RichText (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))) Evergreen.V392.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId) Evergreen.V392.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.ChannelName.ChannelName Evergreen.V392.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.ChannelName.ChannelName Evergreen.V392.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.User.FrontendUser
    | Server_MemberLeft (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V392.LocalState.JoinGuildError
            { guildId : Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId
            , guild : Evergreen.V392.LocalState.FrontendGuild
            , owner : Evergreen.V392.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V392.RichText.RichText (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V392.RichText.RichText (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V392.Id.Viewing_DiscordDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V392.RichText.RichText (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Maybe Evergreen.V392.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Maybe Evergreen.V392.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V392.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V392.SessionIdHash.SessionIdHash Evergreen.V392.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V392.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V392.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V392.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V392.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V392.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Evergreen.V392.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Bool Evergreen.V392.ChannelName.ChannelName (Evergreen.V392.Discord.OptionalData (Maybe String)) (List Evergreen.V392.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId)
        (Evergreen.V392.NonemptyDict.NonemptyDict
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) Evergreen.V392.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Evergreen.V392.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Maybe (Evergreen.V392.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V392.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V392.Log.Log
    | Server_BackupGenerated Evergreen.V392.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V392.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V392.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V392.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V392.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (Evergreen.V392.Discord.OptionalData (Maybe String)) (Evergreen.V392.Discord.OptionalData (Maybe String)) (List Evergreen.V392.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.GuildName.GuildName (Maybe Evergreen.V392.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId) Evergreen.V392.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId) Evergreen.V392.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId)
        (Evergreen.V392.MembersAndOwner.MembersAndOwner
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Evergreen.V392.PersonName.PersonName Evergreen.V392.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId) Evergreen.V392.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId) Evergreen.V392.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V392.Call.ServerChange
    | Server_Game (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Game.LocalChange
    | Server_Drawing (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Drawing.AnchorType Evergreen.V392.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Evergreen.V392.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V392.Id.Viewing_DmId ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Evergreen.V392.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V392.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V392.Id.Viewing_DmId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | Server_E2eeAccepted Evergreen.V392.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.User.FrontendUser Effect.Time.Posix Evergreen.V392.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V392.FileStatus.FileHash) (Evergreen.V392.Encryption.EncryptedData (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))) Evergreen.V392.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.Viewing_DmId Evergreen.V392.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V392.FileStatus.FileHash) (Evergreen.V392.Encryption.EncryptedData (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V392.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V392.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V392.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V392.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V392.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V392.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V392.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V392.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V392.Id.AnyGuildOrDmId Evergreen.V392.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V392.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels) (Maybe Evergreen.V392.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V392.SheepGame.Input (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels) (Maybe Evergreen.V392.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V392.Id.GuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V392.Id.GuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId) (Evergreen.V392.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V392.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V392.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V392.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , threadRoute : Evergreen.V392.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V392.Encryption.BytesHash
    , id : Evergreen.V392.Id.Viewing_DmId
    , senderId : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , threadRoute : Evergreen.V392.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V392.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V392.Id.Viewing_DmId
    , messages : List Evergreen.V392.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V392.Id.Viewing_DmId
    , messages : List ( Evergreen.V392.Id.ThreadRouteWithMessage, Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V392.Id.Viewing_DmId
    , threadRoute : Evergreen.V392.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute )
    , fileId : Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V392.Id.Id Evergreen.V392.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V392.Id.Id Evergreen.V392.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V392.Id.Id Evergreen.V392.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V392.Id.Id Evergreen.V392.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V392.Id.Id Evergreen.V392.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V392.Local.Local LocalMsg Evergreen.V392.LocalState.LocalState
    , admin : Evergreen.V392.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId, Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V392.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V392.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.Message.RepliedTo Evergreen.V392.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V392.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V392.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V392.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.ThreadRoute ) (Evergreen.V392.NonemptyDict.NonemptyDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V392.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V392.Scroll.ScrollPosition
    , textEditor : Evergreen.V392.TextEditor.Model
    , profilePictureEditor : Evergreen.V392.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId, Evergreen.V392.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V392.Emoji.Model
    , voiceChat : Evergreen.V392.Call.Model
    , games : SeqDict.SeqDict Evergreen.V392.Id.GuildOrDmId Evergreen.V392.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V392.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V392.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V392.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V392.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V392.Range.Range
                , direction : Evergreen.V392.Range.SelectionDirection
                }
        }


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup
    | RecoveryPasswordInvalid
    | UserIsDeleted


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V392.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V392.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V392.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V392.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V392.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V392.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V392.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V392.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V392.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V392.MyUi.LastCopy
    , drag : Evergreen.V392.Touch.Drag
    , dragPrevious : Evergreen.V392.Touch.Drag
    , aiChatModel : Evergreen.V392.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V392.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V392.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V392.Audio.LoadError Evergreen.V392.Audio.Source
    , startupData : Evergreen.V392.Ports.StartupData
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
    Evergreen.V392.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V392.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V392.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V392.FileStatus.FileHash
    , metadata : Maybe Evergreen.V392.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId, Evergreen.V392.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId, Evergreen.V392.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V392.DmChannelId.DmChannelId, Evergreen.V392.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId, Evergreen.V392.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId, Evergreen.V392.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId, Evergreen.V392.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V392.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V392.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V392.LocalState.BackupContents
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
    { users : Evergreen.V392.NonemptyDict.NonemptyDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V392.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V392.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V392.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V392.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) Evergreen.V392.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V392.DmChannelId.DmChannelId Evergreen.V392.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) Evergreen.V392.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.Slack.Id Evergreen.V392.Slack.ChannelId) Evergreen.V392.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V392.OneToOne.OneToOne String (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    , slackUsers : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.Slack.Id Evergreen.V392.Slack.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    , slackServers : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.Slack.Id Evergreen.V392.Slack.TeamId) (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    , slackToken : Maybe Evergreen.V392.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V392.FileStatus.FileHash Evergreen.V392.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V392.FileStatus.FileHash
    , privateVapidKey : Evergreen.V392.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V392.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V392.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Evergreen.V392.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId, Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V392.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V392.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V392.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V392.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.LocalState.LoadingDiscordChannel Evergreen.V392.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V392.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V392.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V392.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId) Evergreen.V392.Sticker.StickerData
    , discordStickers : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.Discord.Id Evergreen.V392.Discord.StickerId) (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId) Evergreen.V392.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V392.OneToOne.OneToOne Evergreen.V392.RichText.DiscordCustomEmojiIdAndName (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V392.Postmark.ApiKey
    , serverSecret : Evergreen.V392.SecretId.SecretId Evergreen.V392.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V392.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.GamePublicId) ( Evergreen.V392.DmChannelId.GuildOrFullDmId, Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V392.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V392.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V392.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.Id.ThreadRoute (Maybe Evergreen.V392.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V392.DmChannelId.DmChannelId Evergreen.V392.Id.ThreadRoute (Maybe Evergreen.V392.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V392.Id.Id Evergreen.V392.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V392.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V392.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V392.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V392.UserAgent.UserAgent
    | AdminToBackend Evergreen.V392.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V392.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V392.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V392.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V392.PersonName.PersonName Evergreen.V392.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V392.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V392.Slack.OAuthCode Evergreen.V392.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V392.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V392.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V392.Id.Id Evergreen.V392.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V392.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V392.EmailAddress.EmailAddress (Result Evergreen.V392.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V392.EmailAddress.EmailAddress (Result Evergreen.V392.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V392.EmailAddress.EmailAddress (Result Evergreen.V392.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V392.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMaybeMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Result Evergreen.V392.Discord.HttpError Evergreen.V392.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V392.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Result Evergreen.V392.Discord.HttpError Evergreen.V392.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) (Result Evergreen.V392.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) (Result Evergreen.V392.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) (Result Evergreen.V392.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) (Result Evergreen.V392.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji (Result Evergreen.V392.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji (Result Evergreen.V392.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji (Result Evergreen.V392.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji (Result Evergreen.V392.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V392.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V392.Discord.HttpError (List ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId, Maybe Evergreen.V392.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Effect.Time.Posix Evergreen.V392.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V392.Slack.CurrentUser
            , team : Evergreen.V392.Slack.Team
            , users : List Evergreen.V392.Slack.User
            , channels : List ( Evergreen.V392.Slack.Channel, List Evergreen.V392.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Result Effect.Http.Error Evergreen.V392.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Discord.UserAuth (Result Evergreen.V392.Discord.HttpError Evergreen.V392.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Result Evergreen.V392.Discord.HttpError Evergreen.V392.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
        (Result
            Evergreen.V392.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId
                    , members : List (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
                    , messages : List Evergreen.V392.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId
                    , { guild : Evergreen.V392.Discord.GatewayGuild
                      , channels : List Evergreen.V392.Discord.Channel
                      , icon : Maybe Evergreen.V392.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (List Evergreen.V392.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V392.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V392.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V392.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V392.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.AttachmentId, Evergreen.V392.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V392.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.AttachmentId, Evergreen.V392.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V392.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V392.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V392.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V392.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (Result Evergreen.V392.Discord.HttpError Evergreen.V392.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Result Evergreen.V392.Discord.HttpError (List Evergreen.V392.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V392.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V392.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V392.DmChannelId.DmChannelId Evergreen.V392.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V392.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V392.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V392.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
        (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V392.Discord.HttpError
            { guild : Evergreen.V392.Discord.GatewayGuild
            , channels : List Evergreen.V392.Discord.Channel
            , icon : Maybe Evergreen.V392.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Maybe Evergreen.V392.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Result Evergreen.V392.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V392.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V392.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (List ( Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId, Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId, Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (List ( Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V392.Discord.HttpError (List Evergreen.V392.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V392.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V392.SecretId.SecretId Evergreen.V392.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V392.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V392.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V392.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V392.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Result Evergreen.V392.Discord.HttpError ( Evergreen.V392.Discord.Guild, List Evergreen.V392.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V392.FileStatus.FileHash Int (Maybe (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Call.CallId
