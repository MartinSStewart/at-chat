module Evergreen.V395.Types exposing (..)

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
import Evergreen.V395.AiChat
import Evergreen.V395.Audio
import Evergreen.V395.BackendMsgLog
import Evergreen.V395.Call
import Evergreen.V395.ChannelDescription
import Evergreen.V395.ChannelName
import Evergreen.V395.Coord
import Evergreen.V395.CssPixels
import Evergreen.V395.CustomEmoji
import Evergreen.V395.Discord
import Evergreen.V395.DiscordAttachmentId
import Evergreen.V395.DiscordUserData
import Evergreen.V395.DmChannel
import Evergreen.V395.DmChannelId
import Evergreen.V395.Drawing
import Evergreen.V395.Editable
import Evergreen.V395.EmailAddress
import Evergreen.V395.Embed
import Evergreen.V395.Emoji
import Evergreen.V395.Encryption
import Evergreen.V395.FileStatus
import Evergreen.V395.Game
import Evergreen.V395.Go
import Evergreen.V395.GuildName
import Evergreen.V395.Id
import Evergreen.V395.IdArray
import Evergreen.V395.ImageEditor
import Evergreen.V395.ImageViewer
import Evergreen.V395.LinkedAndOtherDiscordUsers
import Evergreen.V395.Local
import Evergreen.V395.LocalState
import Evergreen.V395.Log
import Evergreen.V395.LoginForm
import Evergreen.V395.MembersAndOwner
import Evergreen.V395.Message
import Evergreen.V395.MessageInput
import Evergreen.V395.MessageView
import Evergreen.V395.MuteSettings
import Evergreen.V395.MyUi
import Evergreen.V395.NonemptyDict
import Evergreen.V395.NonemptySet
import Evergreen.V395.OneOrGreater
import Evergreen.V395.OneToOne
import Evergreen.V395.Pages.Admin
import Evergreen.V395.Pagination
import Evergreen.V395.PersonName
import Evergreen.V395.Ports
import Evergreen.V395.Postmark
import Evergreen.V395.Range
import Evergreen.V395.RateLimit
import Evergreen.V395.RecoveryLogin
import Evergreen.V395.RichText
import Evergreen.V395.Route
import Evergreen.V395.Scroll
import Evergreen.V395.SecretId
import Evergreen.V395.SessionIdHash
import Evergreen.V395.SetViewing
import Evergreen.V395.SheepGame
import Evergreen.V395.Slack
import Evergreen.V395.Sticker
import Evergreen.V395.TextEditor
import Evergreen.V395.ToBackendLog
import Evergreen.V395.Touch
import Evergreen.V395.TwoFactorAuthentication
import Evergreen.V395.Ui.Anim
import Evergreen.V395.User
import Evergreen.V395.UserAgent
import Evergreen.V395.UserColor
import Evergreen.V395.UserSession
import Evergreen.V395.WordSpellingGame
import Evergreen.V395.X25519
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
    | LoginFormMsg Evergreen.V395.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V395.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V395.Pages.Admin.Msg
    | PressedLogOut Evergreen.V395.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V395.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V395.Route.Route
    | SelectedFilesToAttach ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | PressedImportChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V395.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V395.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V395.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V395.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V395.NonemptyDict.NonemptyDict Int Evergreen.V395.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V395.NonemptyDict.NonemptyDict Int Evergreen.V395.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRoute Evergreen.V395.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V395.NonemptySet.NonemptySet (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V395.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V395.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V395.AiChat.Msg
    | GameMsg Evergreen.V395.Game.Msg
    | GoSpectatorMsg Evergreen.V395.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V395.Editable.Msg Evergreen.V395.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V395.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) (Maybe Evergreen.V395.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute )
        { fileId : Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute )
        { fileId : Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage Evergreen.V395.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V395.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V395.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V395.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V395.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V395.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V395.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V395.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | PressedDisableE2ee (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | TypedPrivateKey (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V395.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId
        , otherUserId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V395.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRoute Evergreen.V395.MessageInput.Msg
    | MessageInputMsg Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRoute Evergreen.V395.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V395.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V395.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V395.Range.Range, Evergreen.V395.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V395.Range.Range, Evergreen.V395.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V395.Call.FromJs)
    | VoiceChatMsg Evergreen.V395.Call.Msg
    | PressedChannelHeaderTab Evergreen.V395.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V395.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V395.Audio.LoadError Evergreen.V395.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V395.Id.AnyGuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V395.Id.AnyGuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) Evergreen.V395.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V395.Encryption.FromJs (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V395.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V395.UserSession.UserSession
    , currentlyViewing : Evergreen.V395.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) Evergreen.V395.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.LocalState.DiscordFrontendGuild
    , user : Evergreen.V395.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.User.FrontendUser
    , discordUsers : Evergreen.V395.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V395.SessionIdHash.SessionIdHash Evergreen.V395.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V395.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId) Evergreen.V395.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId) Evergreen.V395.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V395.Call.CallId (Evergreen.V395.NonemptyDict.NonemptyDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V395.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V395.Go.PublicGoMatchData Evergreen.V395.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V395.Route.Route
    , windowSize : Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V395.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V395.Audio.LoadError Evergreen.V395.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Encryption.EncryptedData (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.NonemptyDict.NonemptyDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Encryption.EncryptedData (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V395.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V395.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V395.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData) (List Evergreen.V395.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V395.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V395.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.ChannelName.ChannelName Evergreen.V395.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.ChannelName.ChannelName Evergreen.V395.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.UserSession.ToBeFilledInByBackend (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V395.GuildName.GuildName (Evergreen.V395.UserSession.ToBeFilledInByBackend (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V395.Id.Viewing_DiscordDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V395.SetViewing.SetViewing
    | Local_SetName Evergreen.V395.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V395.Id.GuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.UserSession.ToBeFilledInByBackend Evergreen.V395.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V395.Id.GuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V395.Id.DiscordGuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V395.Id.DiscordGuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V395.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V395.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V395.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.QuestionId Evergreen.V395.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V395.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V395.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V395.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V395.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V395.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V395.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V395.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V395.NonemptySet.NonemptySet (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V395.Call.LocalChange
    | Local_Game Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Game.LocalChange
    | Local_Drawing Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Drawing.AnchorType Evergreen.V395.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V395.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V395.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V395.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V395.X25519.PublicKey (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V395.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V395.Id.Viewing_DmId (List ( Evergreen.V395.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V395.FileStatus.FileHash, Evergreen.V395.Encryption.EncryptedData (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V395.Id.Viewing_DmId (Evergreen.V395.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V395.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V395.Id.ThreadRouteWithMessage, Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V395.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V395.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V395.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V395.FileStatus.FileHash) (Evergreen.V395.Encryption.EncryptedData (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))) (Evergreen.V395.Encryption.EncryptedData String) Evergreen.V395.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V395.Id.Viewing_DmId Evergreen.V395.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V395.FileStatus.FileHash) (Evergreen.V395.Encryption.EncryptedData (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.User.FrontendUser Effect.Time.Posix Evergreen.V395.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V395.RichText.RichText (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))) Evergreen.V395.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId) Evergreen.V395.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V395.Id.DiscordGuildOrDmId Evergreen.V395.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V395.RichText.RichText (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))) Evergreen.V395.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId) Evergreen.V395.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.ChannelName.ChannelName Evergreen.V395.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.ChannelName.ChannelName Evergreen.V395.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.User.FrontendUser
    | Server_MemberLeft (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V395.LocalState.JoinGuildError
            { guildId : Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId
            , guild : Evergreen.V395.LocalState.FrontendGuild
            , owner : Evergreen.V395.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V395.RichText.RichText (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V395.RichText.RichText (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V395.Id.Viewing_DiscordDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V395.RichText.RichText (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Maybe Evergreen.V395.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Maybe Evergreen.V395.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V395.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V395.SessionIdHash.SessionIdHash Evergreen.V395.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V395.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V395.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V395.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V395.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V395.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Bool Evergreen.V395.ChannelName.ChannelName (Evergreen.V395.Discord.OptionalData (Maybe String)) (List Evergreen.V395.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
        (Evergreen.V395.NonemptyDict.NonemptyDict
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) Evergreen.V395.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Maybe (Evergreen.V395.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V395.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V395.Log.Log
    | Server_BackupGenerated Evergreen.V395.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V395.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V395.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V395.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V395.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (Evergreen.V395.Discord.OptionalData (Maybe String)) (Evergreen.V395.Discord.OptionalData (Maybe String)) (List Evergreen.V395.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.GuildName.GuildName (Maybe Evergreen.V395.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId) Evergreen.V395.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId) Evergreen.V395.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
        (Evergreen.V395.MembersAndOwner.MembersAndOwner
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.PersonName.PersonName Evergreen.V395.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId) Evergreen.V395.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId) Evergreen.V395.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V395.Call.ServerChange
    | Server_Game (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Game.LocalChange
    | Server_Drawing (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Drawing.AnchorType Evergreen.V395.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V395.Id.Viewing_DmId ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V395.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V395.Id.Viewing_DmId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | Server_E2eeAccepted Evergreen.V395.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.User.FrontendUser Effect.Time.Posix Evergreen.V395.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V395.FileStatus.FileHash) (Evergreen.V395.Encryption.EncryptedData (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))) Evergreen.V395.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.Viewing_DmId Evergreen.V395.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V395.FileStatus.FileHash) (Evergreen.V395.Encryption.EncryptedData (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V395.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V395.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V395.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V395.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V395.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V395.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V395.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V395.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V395.Id.AnyGuildOrDmId Evergreen.V395.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V395.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels) (Maybe Evergreen.V395.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V395.SheepGame.Input (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels) (Maybe Evergreen.V395.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V395.Id.GuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V395.Id.GuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V395.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V395.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V395.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , threadRoute : Evergreen.V395.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V395.Encryption.BytesHash
    , id : Evergreen.V395.Id.Viewing_DmId
    , senderId : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , threadRoute : Evergreen.V395.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V395.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V395.Id.Viewing_DmId
    , messages : List Evergreen.V395.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V395.Id.Viewing_DmId
    , messages : List ( Evergreen.V395.Id.ThreadRouteWithMessage, Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V395.Id.Viewing_DmId
    , threadRoute : Evergreen.V395.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute )
    , fileId : Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V395.Id.Id Evergreen.V395.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V395.Id.Id Evergreen.V395.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V395.Id.Id Evergreen.V395.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V395.Id.Id Evergreen.V395.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V395.Id.Id Evergreen.V395.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V395.Local.Local LocalMsg Evergreen.V395.LocalState.LocalState
    , admin : Evergreen.V395.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V395.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V395.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.Message.RepliedTo Evergreen.V395.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V395.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V395.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V395.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.ThreadRoute ) (Evergreen.V395.NonemptyDict.NonemptyDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V395.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V395.Scroll.ScrollPosition
    , textEditor : Evergreen.V395.TextEditor.Model
    , profilePictureEditor : Evergreen.V395.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId, Evergreen.V395.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V395.Emoji.Model
    , voiceChat : Evergreen.V395.Call.Model
    , games : SeqDict.SeqDict Evergreen.V395.Id.GuildOrDmId Evergreen.V395.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V395.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V395.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V395.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V395.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V395.Range.Range
                , direction : Evergreen.V395.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V395.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V395.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V395.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V395.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V395.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | ProfilePictureEditorToFrontend Evergreen.V395.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V395.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V395.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V395.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V395.MyUi.LastCopy
    , drag : Evergreen.V395.Touch.Drag
    , dragPrevious : Evergreen.V395.Touch.Drag
    , aiChatModel : Evergreen.V395.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V395.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V395.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V395.Audio.LoadError Evergreen.V395.Audio.Source
    , startupData : Evergreen.V395.Ports.StartupData
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
    Evergreen.V395.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V395.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V395.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V395.FileStatus.FileHash
    , metadata : Maybe Evergreen.V395.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId, Evergreen.V395.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId, Evergreen.V395.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V395.DmChannelId.DmChannelId, Evergreen.V395.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId, Evergreen.V395.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId, Evergreen.V395.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId, Evergreen.V395.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V395.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V395.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V395.LocalState.BackupContents
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
    { users : Evergreen.V395.NonemptyDict.NonemptyDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V395.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V395.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V395.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V395.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V395.DmChannelId.DmChannelId Evergreen.V395.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) Evergreen.V395.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.Slack.Id Evergreen.V395.Slack.ChannelId) Evergreen.V395.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V395.OneToOne.OneToOne String (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    , slackUsers : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.Slack.Id Evergreen.V395.Slack.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    , slackServers : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.Slack.Id Evergreen.V395.Slack.TeamId) (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    , slackToken : Maybe Evergreen.V395.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V395.FileStatus.FileHash Evergreen.V395.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V395.FileStatus.FileHash
    , privateVapidKey : Evergreen.V395.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V395.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V395.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId, Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V395.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V395.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V395.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V395.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.LocalState.LoadingDiscordChannel Evergreen.V395.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V395.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V395.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V395.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId) Evergreen.V395.Sticker.StickerData
    , discordStickers : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.Discord.Id Evergreen.V395.Discord.StickerId) (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId) Evergreen.V395.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V395.OneToOne.OneToOne Evergreen.V395.RichText.DiscordCustomEmojiIdAndName (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V395.Postmark.ApiKey
    , serverSecret : Evergreen.V395.SecretId.SecretId Evergreen.V395.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V395.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.GamePublicId) ( Evergreen.V395.DmChannelId.GuildOrFullDmId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V395.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V395.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V395.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.Id.ThreadRoute (Maybe Evergreen.V395.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V395.DmChannelId.DmChannelId Evergreen.V395.Id.ThreadRoute (Maybe Evergreen.V395.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V395.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V395.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V395.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V395.UserAgent.UserAgent
    | AdminToBackend Evergreen.V395.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V395.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V395.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V395.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V395.PersonName.PersonName Evergreen.V395.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V395.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V395.Slack.OAuthCode Evergreen.V395.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V395.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V395.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V395.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V395.EmailAddress.EmailAddress (Result Evergreen.V395.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V395.EmailAddress.EmailAddress (Result Evergreen.V395.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V395.EmailAddress.EmailAddress (Result Evergreen.V395.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V395.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMaybeMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Result Evergreen.V395.Discord.HttpError Evergreen.V395.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V395.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Result Evergreen.V395.Discord.HttpError Evergreen.V395.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) (Result Evergreen.V395.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) (Result Evergreen.V395.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) (Result Evergreen.V395.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) (Result Evergreen.V395.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji (Result Evergreen.V395.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji (Result Evergreen.V395.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji (Result Evergreen.V395.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji (Result Evergreen.V395.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V395.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V395.Discord.HttpError (List ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId, Maybe Evergreen.V395.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Effect.Time.Posix Evergreen.V395.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V395.Slack.CurrentUser
            , team : Evergreen.V395.Slack.Team
            , users : List Evergreen.V395.Slack.User
            , channels : List ( Evergreen.V395.Slack.Channel, List Evergreen.V395.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Result Effect.Http.Error Evergreen.V395.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Discord.UserAuth (Result Evergreen.V395.Discord.HttpError Evergreen.V395.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Result Evergreen.V395.Discord.HttpError Evergreen.V395.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
        (Result
            Evergreen.V395.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId
                    , members : List (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
                    , messages : List Evergreen.V395.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId
                    , { guild : Evergreen.V395.Discord.GatewayGuild
                      , channels : List Evergreen.V395.Discord.Channel
                      , icon : Maybe Evergreen.V395.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (List Evergreen.V395.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V395.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V395.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V395.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V395.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.AttachmentId, Evergreen.V395.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V395.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.AttachmentId, Evergreen.V395.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V395.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V395.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V395.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V395.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (Result Evergreen.V395.Discord.HttpError Evergreen.V395.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Result Evergreen.V395.Discord.HttpError (List Evergreen.V395.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V395.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V395.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V395.DmChannelId.DmChannelId Evergreen.V395.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V395.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V395.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V395.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
        (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V395.Discord.HttpError
            { guild : Evergreen.V395.Discord.GatewayGuild
            , channels : List Evergreen.V395.Discord.Channel
            , icon : Maybe Evergreen.V395.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Maybe Evergreen.V395.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Result Evergreen.V395.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V395.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V395.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (List ( Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId, Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId, Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (List ( Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V395.Discord.HttpError (List Evergreen.V395.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V395.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V395.SecretId.SecretId Evergreen.V395.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V395.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V395.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V395.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V395.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Result Evergreen.V395.Discord.HttpError ( Evergreen.V395.Discord.Guild, List Evergreen.V395.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V395.FileStatus.FileHash Int (Maybe (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Call.CallId
