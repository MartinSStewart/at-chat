module Evergreen.V396.Types exposing (..)

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
import Evergreen.V396.AiChat
import Evergreen.V396.Audio
import Evergreen.V396.BackendMsgLog
import Evergreen.V396.Call
import Evergreen.V396.ChannelDescription
import Evergreen.V396.ChannelName
import Evergreen.V396.Coord
import Evergreen.V396.CssPixels
import Evergreen.V396.CustomEmoji
import Evergreen.V396.Discord
import Evergreen.V396.DiscordAttachmentId
import Evergreen.V396.DiscordUserData
import Evergreen.V396.DmChannel
import Evergreen.V396.DmChannelId
import Evergreen.V396.Drawing
import Evergreen.V396.Editable
import Evergreen.V396.EmailAddress
import Evergreen.V396.Embed
import Evergreen.V396.Emoji
import Evergreen.V396.Encryption
import Evergreen.V396.FileStatus
import Evergreen.V396.Game
import Evergreen.V396.Go
import Evergreen.V396.GuildName
import Evergreen.V396.Id
import Evergreen.V396.IdArray
import Evergreen.V396.ImageEditor
import Evergreen.V396.ImageViewer
import Evergreen.V396.LinkedAndOtherDiscordUsers
import Evergreen.V396.Local
import Evergreen.V396.LocalState
import Evergreen.V396.Log
import Evergreen.V396.LoginForm
import Evergreen.V396.MembersAndOwner
import Evergreen.V396.Message
import Evergreen.V396.MessageInput
import Evergreen.V396.MessageView
import Evergreen.V396.MuteSettings
import Evergreen.V396.MyUi
import Evergreen.V396.NonemptyDict
import Evergreen.V396.NonemptySet
import Evergreen.V396.OneOrGreater
import Evergreen.V396.OneToOne
import Evergreen.V396.Pages.Admin
import Evergreen.V396.Pagination
import Evergreen.V396.PersonName
import Evergreen.V396.Ports
import Evergreen.V396.Postmark
import Evergreen.V396.Range
import Evergreen.V396.RateLimit
import Evergreen.V396.RecoveryLogin
import Evergreen.V396.RichText
import Evergreen.V396.Route
import Evergreen.V396.Scroll
import Evergreen.V396.SecretId
import Evergreen.V396.SessionIdHash
import Evergreen.V396.SetViewing
import Evergreen.V396.SheepGame
import Evergreen.V396.Slack
import Evergreen.V396.Sticker
import Evergreen.V396.TextEditor
import Evergreen.V396.ToBackendLog
import Evergreen.V396.Touch
import Evergreen.V396.TwoFactorAuthentication
import Evergreen.V396.Ui.Anim
import Evergreen.V396.User
import Evergreen.V396.UserAgent
import Evergreen.V396.UserColor
import Evergreen.V396.UserSession
import Evergreen.V396.WordSpellingGame
import Evergreen.V396.X25519
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
    | LoginFormMsg Evergreen.V396.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V396.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V396.Pages.Admin.Msg
    | PressedLogOut Evergreen.V396.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V396.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V396.Route.Route
    | SelectedFilesToAttach ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | PressedImportChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V396.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V396.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V396.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V396.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V396.NonemptyDict.NonemptyDict Int Evergreen.V396.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V396.NonemptyDict.NonemptyDict Int Evergreen.V396.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRoute Evergreen.V396.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V396.NonemptySet.NonemptySet (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V396.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V396.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V396.AiChat.Msg
    | GameMsg Evergreen.V396.Game.Msg
    | GoSpectatorMsg Evergreen.V396.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V396.Editable.Msg Evergreen.V396.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V396.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) (Maybe Evergreen.V396.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute )
        { fileId : Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute )
        { fileId : Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage Evergreen.V396.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V396.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V396.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V396.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V396.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V396.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V396.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V396.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | PressedDisableE2ee (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | TypedPrivateKey (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V396.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId
        , otherUserId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V396.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRoute Evergreen.V396.MessageInput.Msg
    | MessageInputMsg Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRoute Evergreen.V396.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V396.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V396.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V396.Range.Range, Evergreen.V396.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V396.Range.Range, Evergreen.V396.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V396.Call.FromJs)
    | VoiceChatMsg Evergreen.V396.Call.Msg
    | PressedChannelHeaderTab Evergreen.V396.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V396.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V396.Audio.LoadError Evergreen.V396.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V396.Id.AnyGuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V396.Id.AnyGuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) Evergreen.V396.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V396.Encryption.FromJs (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V396.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V396.UserSession.UserSession
    , currentlyViewing : Evergreen.V396.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) Evergreen.V396.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.LocalState.DiscordFrontendGuild
    , user : Evergreen.V396.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.User.FrontendUser
    , discordUsers : Evergreen.V396.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V396.SessionIdHash.SessionIdHash Evergreen.V396.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V396.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId) Evergreen.V396.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId) Evergreen.V396.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V396.Call.CallId (Evergreen.V396.NonemptyDict.NonemptyDict ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V396.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V396.Go.PublicGoMatchData Evergreen.V396.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V396.Route.Route
    , windowSize : Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V396.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V396.Audio.LoadError Evergreen.V396.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Encryption.EncryptedData (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.NonemptyDict.NonemptyDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.Encryption.EncryptedData (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V396.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V396.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V396.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileData) (List Evergreen.V396.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V396.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V396.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.ChannelName.ChannelName Evergreen.V396.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.ChannelName.ChannelName Evergreen.V396.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.UserSession.ToBeFilledInByBackend (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V396.GuildName.GuildName (Evergreen.V396.UserSession.ToBeFilledInByBackend (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V396.Id.Viewing_DiscordDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V396.SetViewing.SetViewing
    | Local_SetName Evergreen.V396.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V396.Id.GuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.UserSession.ToBeFilledInByBackend Evergreen.V396.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V396.Id.GuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.Message.Message Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V396.Id.DiscordGuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V396.Id.DiscordGuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.Message.Message Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V396.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V396.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V396.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.QuestionId Evergreen.V396.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V396.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V396.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V396.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V396.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V396.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V396.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V396.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V396.NonemptySet.NonemptySet (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V396.Call.LocalChange
    | Local_Game Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Game.LocalChange
    | Local_Drawing Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Drawing.AnchorType Evergreen.V396.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V396.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V396.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V396.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V396.X25519.PublicKey (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V396.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V396.Id.Viewing_DmId (List ( Evergreen.V396.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V396.FileStatus.FileHash, Evergreen.V396.Encryption.EncryptedData (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V396.Id.Viewing_DmId (Evergreen.V396.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V396.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V396.Id.ThreadRouteWithMessage, Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V396.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V396.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V396.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V396.FileStatus.FileHash) (Evergreen.V396.Encryption.EncryptedData (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))) (Evergreen.V396.Encryption.EncryptedData String) Evergreen.V396.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V396.Id.Viewing_DmId Evergreen.V396.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V396.FileStatus.FileHash) (Evergreen.V396.Encryption.EncryptedData (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.User.FrontendUser Effect.Time.Posix Evergreen.V396.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V396.RichText.RichText (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))) Evergreen.V396.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId) Evergreen.V396.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V396.Id.DiscordGuildOrDmId Evergreen.V396.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V396.RichText.RichText (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))) Evergreen.V396.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId) Evergreen.V396.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.ChannelName.ChannelName Evergreen.V396.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.ChannelName.ChannelName Evergreen.V396.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.User.FrontendUser
    | Server_MemberLeft (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V396.LocalState.JoinGuildError
            { guildId : Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId
            , guild : Evergreen.V396.LocalState.FrontendGuild
            , owner : Evergreen.V396.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V396.RichText.RichText (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V396.RichText.RichText (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V396.Id.Viewing_DiscordDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V396.RichText.RichText (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Maybe Evergreen.V396.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Maybe Evergreen.V396.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V396.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V396.SessionIdHash.SessionIdHash Evergreen.V396.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V396.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V396.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V396.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V396.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V396.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Bool Evergreen.V396.ChannelName.ChannelName (Evergreen.V396.Discord.OptionalData (Maybe String)) (List Evergreen.V396.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
        (Evergreen.V396.NonemptyDict.NonemptyDict
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) Evergreen.V396.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Maybe (Evergreen.V396.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V396.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V396.Log.Log
    | Server_BackupGenerated Evergreen.V396.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V396.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V396.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V396.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V396.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (Evergreen.V396.Discord.OptionalData (Maybe String)) (Evergreen.V396.Discord.OptionalData (Maybe String)) (List Evergreen.V396.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.GuildName.GuildName (Maybe Evergreen.V396.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId) Evergreen.V396.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId) Evergreen.V396.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
        (Evergreen.V396.MembersAndOwner.MembersAndOwner
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.PersonName.PersonName Evergreen.V396.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId) Evergreen.V396.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId) Evergreen.V396.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V396.Call.ServerChange
    | Server_Game (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Game.LocalChange
    | Server_Drawing (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Drawing.AnchorType Evergreen.V396.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V396.Id.Viewing_DmId ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Evergreen.V396.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V396.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V396.Id.Viewing_DmId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | Server_E2eeAccepted Evergreen.V396.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.User.FrontendUser Effect.Time.Posix Evergreen.V396.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V396.FileStatus.FileHash) (Evergreen.V396.Encryption.EncryptedData (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))) Evergreen.V396.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.Viewing_DmId Evergreen.V396.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V396.FileStatus.FileHash) (Evergreen.V396.Encryption.EncryptedData (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V396.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V396.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V396.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V396.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V396.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V396.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V396.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V396.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V396.Id.AnyGuildOrDmId Evergreen.V396.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V396.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels) (Maybe Evergreen.V396.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V396.SheepGame.Input (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels) (Maybe Evergreen.V396.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V396.Id.GuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V396.Id.GuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId) (Evergreen.V396.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V396.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V396.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V396.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , threadRoute : Evergreen.V396.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V396.Encryption.BytesHash
    , id : Evergreen.V396.Id.Viewing_DmId
    , senderId : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , threadRoute : Evergreen.V396.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V396.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V396.Id.Viewing_DmId
    , messages : List Evergreen.V396.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V396.Id.Viewing_DmId
    , messages : List ( Evergreen.V396.Id.ThreadRouteWithMessage, Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V396.Id.Viewing_DmId
    , threadRoute : Evergreen.V396.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute )
    , fileId : Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V396.Id.Id Evergreen.V396.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V396.Id.Id Evergreen.V396.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V396.Id.Id Evergreen.V396.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V396.Id.Id Evergreen.V396.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V396.Id.Id Evergreen.V396.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V396.Local.Local LocalMsg Evergreen.V396.LocalState.LocalState
    , admin : Evergreen.V396.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId, Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V396.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V396.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.Message.RepliedTo Evergreen.V396.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V396.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V396.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V396.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.ThreadRoute ) (Evergreen.V396.NonemptyDict.NonemptyDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V396.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V396.Scroll.ScrollPosition
    , textEditor : Evergreen.V396.TextEditor.Model
    , profilePictureEditor : Evergreen.V396.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId, Evergreen.V396.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V396.Emoji.Model
    , voiceChat : Evergreen.V396.Call.Model
    , games : SeqDict.SeqDict Evergreen.V396.Id.GuildOrDmId Evergreen.V396.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V396.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V396.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V396.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V396.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V396.Range.Range
                , direction : Evergreen.V396.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V396.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V396.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V396.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V396.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V396.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | ProfilePictureEditorToFrontend Evergreen.V396.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V396.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V396.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V396.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V396.MyUi.LastCopy
    , drag : Evergreen.V396.Touch.Drag
    , dragPrevious : Evergreen.V396.Touch.Drag
    , aiChatModel : Evergreen.V396.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V396.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V396.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V396.Audio.LoadError Evergreen.V396.Audio.Source
    , startupData : Evergreen.V396.Ports.StartupData
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
    Evergreen.V396.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V396.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V396.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V396.FileStatus.FileHash
    , metadata : Maybe Evergreen.V396.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId, Evergreen.V396.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId, Evergreen.V396.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V396.DmChannelId.DmChannelId, Evergreen.V396.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId, Evergreen.V396.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId, Evergreen.V396.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId, Evergreen.V396.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V396.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V396.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V396.LocalState.BackupContents
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
    { users : Evergreen.V396.NonemptyDict.NonemptyDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V396.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V396.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V396.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V396.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V396.DmChannelId.DmChannelId Evergreen.V396.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) Evergreen.V396.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.Slack.Id Evergreen.V396.Slack.ChannelId) Evergreen.V396.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V396.OneToOne.OneToOne String (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    , slackUsers : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.Slack.Id Evergreen.V396.Slack.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    , slackServers : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.Slack.Id Evergreen.V396.Slack.TeamId) (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    , slackToken : Maybe Evergreen.V396.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V396.FileStatus.FileHash Evergreen.V396.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V396.FileStatus.FileHash
    , privateVapidKey : Evergreen.V396.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V396.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V396.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId, Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V396.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V396.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V396.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V396.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.LocalState.LoadingDiscordChannel Evergreen.V396.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V396.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V396.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V396.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId) Evergreen.V396.Sticker.StickerData
    , discordStickers : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.Discord.Id Evergreen.V396.Discord.StickerId) (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId) Evergreen.V396.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V396.OneToOne.OneToOne Evergreen.V396.RichText.DiscordCustomEmojiIdAndName (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V396.Postmark.ApiKey
    , serverSecret : Evergreen.V396.SecretId.SecretId Evergreen.V396.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V396.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.GamePublicId) ( Evergreen.V396.DmChannelId.GuildOrFullDmId, Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V396.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V396.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V396.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.Id.ThreadRoute (Maybe Evergreen.V396.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V396.DmChannelId.DmChannelId Evergreen.V396.Id.ThreadRoute (Maybe Evergreen.V396.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V396.Id.Id Evergreen.V396.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V396.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V396.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V396.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V396.UserAgent.UserAgent
    | AdminToBackend Evergreen.V396.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V396.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V396.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V396.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V396.PersonName.PersonName Evergreen.V396.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V396.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V396.Slack.OAuthCode Evergreen.V396.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V396.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V396.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V396.Id.Id Evergreen.V396.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V396.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V396.EmailAddress.EmailAddress (Result Evergreen.V396.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V396.EmailAddress.EmailAddress (Result Evergreen.V396.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V396.EmailAddress.EmailAddress (Result Evergreen.V396.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V396.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMaybeMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Result Evergreen.V396.Discord.HttpError Evergreen.V396.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V396.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Result Evergreen.V396.Discord.HttpError Evergreen.V396.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) (Result Evergreen.V396.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) (Result Evergreen.V396.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) (Result Evergreen.V396.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) (Result Evergreen.V396.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji (Result Evergreen.V396.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji (Result Evergreen.V396.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji (Result Evergreen.V396.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji (Result Evergreen.V396.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V396.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V396.Discord.HttpError (List ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId, Maybe Evergreen.V396.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Effect.Time.Posix Evergreen.V396.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V396.Slack.CurrentUser
            , team : Evergreen.V396.Slack.Team
            , users : List Evergreen.V396.Slack.User
            , channels : List ( Evergreen.V396.Slack.Channel, List Evergreen.V396.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Result Effect.Http.Error Evergreen.V396.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Discord.UserAuth (Result Evergreen.V396.Discord.HttpError Evergreen.V396.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Result Evergreen.V396.Discord.HttpError Evergreen.V396.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
        (Result
            Evergreen.V396.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId
                    , members : List (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
                    , messages : List Evergreen.V396.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId
                    , { guild : Evergreen.V396.Discord.GatewayGuild
                      , channels : List Evergreen.V396.Discord.Channel
                      , icon : Maybe Evergreen.V396.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (List Evergreen.V396.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V396.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V396.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V396.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V396.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.AttachmentId, Evergreen.V396.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V396.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.AttachmentId, Evergreen.V396.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V396.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V396.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V396.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V396.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (Result Evergreen.V396.Discord.HttpError Evergreen.V396.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Result Evergreen.V396.Discord.HttpError (List Evergreen.V396.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V396.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V396.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V396.DmChannelId.DmChannelId Evergreen.V396.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V396.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V396.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V396.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
        (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V396.Discord.HttpError
            { guild : Evergreen.V396.Discord.GatewayGuild
            , channels : List Evergreen.V396.Discord.Channel
            , icon : Maybe Evergreen.V396.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Maybe Evergreen.V396.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Result Evergreen.V396.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V396.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V396.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (List ( Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId, Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId, Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (List ( Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V396.Discord.HttpError (List Evergreen.V396.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V396.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V396.SecretId.SecretId Evergreen.V396.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V396.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V396.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V396.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V396.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Result Evergreen.V396.Discord.HttpError ( Evergreen.V396.Discord.Guild, List Evergreen.V396.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V396.FileStatus.FileHash Int (Maybe (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Call.CallId
