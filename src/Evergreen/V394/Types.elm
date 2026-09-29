module Evergreen.V394.Types exposing (..)

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
import Evergreen.V394.AiChat
import Evergreen.V394.Audio
import Evergreen.V394.BackendMsgLog
import Evergreen.V394.Call
import Evergreen.V394.ChannelDescription
import Evergreen.V394.ChannelName
import Evergreen.V394.Coord
import Evergreen.V394.CssPixels
import Evergreen.V394.CustomEmoji
import Evergreen.V394.Discord
import Evergreen.V394.DiscordAttachmentId
import Evergreen.V394.DiscordUserData
import Evergreen.V394.DmChannel
import Evergreen.V394.DmChannelId
import Evergreen.V394.Drawing
import Evergreen.V394.Editable
import Evergreen.V394.EmailAddress
import Evergreen.V394.Embed
import Evergreen.V394.Emoji
import Evergreen.V394.Encryption
import Evergreen.V394.FileStatus
import Evergreen.V394.Game
import Evergreen.V394.Go
import Evergreen.V394.GuildName
import Evergreen.V394.Id
import Evergreen.V394.IdArray
import Evergreen.V394.ImageEditor
import Evergreen.V394.ImageViewer
import Evergreen.V394.LinkedAndOtherDiscordUsers
import Evergreen.V394.Local
import Evergreen.V394.LocalState
import Evergreen.V394.Log
import Evergreen.V394.LoginForm
import Evergreen.V394.MembersAndOwner
import Evergreen.V394.Message
import Evergreen.V394.MessageInput
import Evergreen.V394.MessageView
import Evergreen.V394.MuteSettings
import Evergreen.V394.MyUi
import Evergreen.V394.NonemptyDict
import Evergreen.V394.NonemptySet
import Evergreen.V394.OneOrGreater
import Evergreen.V394.OneToOne
import Evergreen.V394.Pages.Admin
import Evergreen.V394.Pagination
import Evergreen.V394.PersonName
import Evergreen.V394.Ports
import Evergreen.V394.Postmark
import Evergreen.V394.Range
import Evergreen.V394.RateLimit
import Evergreen.V394.RecoveryLogin
import Evergreen.V394.RichText
import Evergreen.V394.Route
import Evergreen.V394.Scroll
import Evergreen.V394.SecretId
import Evergreen.V394.SessionIdHash
import Evergreen.V394.SetViewing
import Evergreen.V394.SheepGame
import Evergreen.V394.Slack
import Evergreen.V394.Sticker
import Evergreen.V394.TextEditor
import Evergreen.V394.ToBackendLog
import Evergreen.V394.Touch
import Evergreen.V394.TwoFactorAuthentication
import Evergreen.V394.Ui.Anim
import Evergreen.V394.User
import Evergreen.V394.UserAgent
import Evergreen.V394.UserColor
import Evergreen.V394.UserSession
import Evergreen.V394.WordSpellingGame
import Evergreen.V394.X25519
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
    | LoginFormMsg Evergreen.V394.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V394.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V394.Pages.Admin.Msg
    | PressedLogOut Evergreen.V394.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V394.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V394.Route.Route
    | SelectedFilesToAttach ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | PressedImportChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V394.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V394.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V394.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V394.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V394.NonemptyDict.NonemptyDict Int Evergreen.V394.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V394.NonemptyDict.NonemptyDict Int Evergreen.V394.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRoute Evergreen.V394.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V394.NonemptySet.NonemptySet (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V394.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V394.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V394.AiChat.Msg
    | GameMsg Evergreen.V394.Game.Msg
    | GoSpectatorMsg Evergreen.V394.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V394.Editable.Msg Evergreen.V394.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V394.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) (Maybe Evergreen.V394.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute )
        { fileId : Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute )
        { fileId : Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage Evergreen.V394.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V394.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V394.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V394.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V394.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V394.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V394.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V394.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | PressedDisableE2ee (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | TypedPrivateKey (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V394.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId
        , otherUserId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V394.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRoute Evergreen.V394.MessageInput.Msg
    | MessageInputMsg Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRoute Evergreen.V394.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V394.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V394.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V394.Range.Range, Evergreen.V394.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V394.Range.Range, Evergreen.V394.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V394.Call.FromJs)
    | VoiceChatMsg Evergreen.V394.Call.Msg
    | PressedChannelHeaderTab Evergreen.V394.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V394.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V394.Audio.LoadError Evergreen.V394.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V394.Id.AnyGuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V394.Id.AnyGuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) Evergreen.V394.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V394.Encryption.FromJs (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V394.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V394.UserSession.UserSession
    , currentlyViewing : Evergreen.V394.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) Evergreen.V394.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.LocalState.DiscordFrontendGuild
    , user : Evergreen.V394.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.User.FrontendUser
    , discordUsers : Evergreen.V394.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V394.SessionIdHash.SessionIdHash Evergreen.V394.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V394.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId) Evergreen.V394.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId) Evergreen.V394.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V394.Call.CallId (Evergreen.V394.NonemptyDict.NonemptyDict ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V394.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V394.Go.PublicGoMatchData Evergreen.V394.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V394.Route.Route
    , windowSize : Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V394.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V394.Audio.LoadError Evergreen.V394.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Encryption.EncryptedData (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.NonemptyDict.NonemptyDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.Encryption.EncryptedData (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V394.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V394.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V394.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileData) (List Evergreen.V394.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V394.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V394.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.ChannelName.ChannelName Evergreen.V394.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.ChannelName.ChannelName Evergreen.V394.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.UserSession.ToBeFilledInByBackend (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V394.GuildName.GuildName (Evergreen.V394.UserSession.ToBeFilledInByBackend (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V394.Id.Viewing_DiscordDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V394.SetViewing.SetViewing
    | Local_SetName Evergreen.V394.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V394.Id.GuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.UserSession.ToBeFilledInByBackend Evergreen.V394.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V394.Id.GuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.Message.Message Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V394.Id.DiscordGuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V394.Id.DiscordGuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.Message.Message Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V394.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V394.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V394.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.QuestionId Evergreen.V394.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V394.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V394.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V394.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V394.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V394.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V394.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V394.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V394.NonemptySet.NonemptySet (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V394.Call.LocalChange
    | Local_Game Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Game.LocalChange
    | Local_Drawing Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Drawing.AnchorType Evergreen.V394.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V394.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V394.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V394.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V394.X25519.PublicKey (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V394.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V394.Id.Viewing_DmId (List ( Evergreen.V394.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V394.FileStatus.FileHash, Evergreen.V394.Encryption.EncryptedData (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V394.Id.Viewing_DmId (Evergreen.V394.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V394.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V394.Id.ThreadRouteWithMessage, Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V394.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V394.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V394.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V394.FileStatus.FileHash) (Evergreen.V394.Encryption.EncryptedData (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))) (Evergreen.V394.Encryption.EncryptedData String) Evergreen.V394.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V394.Id.Viewing_DmId Evergreen.V394.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V394.FileStatus.FileHash) (Evergreen.V394.Encryption.EncryptedData (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.User.FrontendUser Effect.Time.Posix Evergreen.V394.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V394.RichText.RichText (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))) Evergreen.V394.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId) Evergreen.V394.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V394.Id.DiscordGuildOrDmId Evergreen.V394.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V394.RichText.RichText (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))) Evergreen.V394.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId) Evergreen.V394.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.ChannelName.ChannelName Evergreen.V394.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.ChannelName.ChannelName Evergreen.V394.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.User.FrontendUser
    | Server_MemberLeft (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V394.LocalState.JoinGuildError
            { guildId : Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId
            , guild : Evergreen.V394.LocalState.FrontendGuild
            , owner : Evergreen.V394.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V394.RichText.RichText (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V394.RichText.RichText (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V394.Id.Viewing_DiscordDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V394.RichText.RichText (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Maybe Evergreen.V394.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Maybe Evergreen.V394.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V394.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V394.SessionIdHash.SessionIdHash Evergreen.V394.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V394.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V394.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V394.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V394.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V394.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Bool Evergreen.V394.ChannelName.ChannelName (Evergreen.V394.Discord.OptionalData (Maybe String)) (List Evergreen.V394.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
        (Evergreen.V394.NonemptyDict.NonemptyDict
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) Evergreen.V394.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Maybe (Evergreen.V394.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V394.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V394.Log.Log
    | Server_BackupGenerated Evergreen.V394.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V394.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V394.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V394.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V394.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (Evergreen.V394.Discord.OptionalData (Maybe String)) (Evergreen.V394.Discord.OptionalData (Maybe String)) (List Evergreen.V394.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.GuildName.GuildName (Maybe Evergreen.V394.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId) Evergreen.V394.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId) Evergreen.V394.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
        (Evergreen.V394.MembersAndOwner.MembersAndOwner
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.PersonName.PersonName Evergreen.V394.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId) Evergreen.V394.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId) Evergreen.V394.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V394.Call.ServerChange
    | Server_Game (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Game.LocalChange
    | Server_Drawing (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Drawing.AnchorType Evergreen.V394.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V394.Id.Viewing_DmId ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Evergreen.V394.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V394.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V394.Id.Viewing_DmId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | Server_E2eeAccepted Evergreen.V394.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.User.FrontendUser Effect.Time.Posix Evergreen.V394.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V394.FileStatus.FileHash) (Evergreen.V394.Encryption.EncryptedData (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))) Evergreen.V394.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.Viewing_DmId Evergreen.V394.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V394.FileStatus.FileHash) (Evergreen.V394.Encryption.EncryptedData (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V394.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V394.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V394.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V394.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V394.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V394.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V394.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V394.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V394.Id.AnyGuildOrDmId Evergreen.V394.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V394.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels) (Maybe Evergreen.V394.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V394.SheepGame.Input (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels) (Maybe Evergreen.V394.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V394.Id.GuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V394.Id.GuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId) (Evergreen.V394.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V394.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V394.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V394.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , threadRoute : Evergreen.V394.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V394.Encryption.BytesHash
    , id : Evergreen.V394.Id.Viewing_DmId
    , senderId : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , threadRoute : Evergreen.V394.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V394.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V394.Id.Viewing_DmId
    , messages : List Evergreen.V394.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V394.Id.Viewing_DmId
    , messages : List ( Evergreen.V394.Id.ThreadRouteWithMessage, Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V394.Id.Viewing_DmId
    , threadRoute : Evergreen.V394.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute )
    , fileId : Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V394.Id.Id Evergreen.V394.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V394.Id.Id Evergreen.V394.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V394.Id.Id Evergreen.V394.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V394.Id.Id Evergreen.V394.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V394.Id.Id Evergreen.V394.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V394.Local.Local LocalMsg Evergreen.V394.LocalState.LocalState
    , admin : Evergreen.V394.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId, Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V394.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V394.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.Message.RepliedTo Evergreen.V394.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V394.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V394.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V394.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.ThreadRoute ) (Evergreen.V394.NonemptyDict.NonemptyDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V394.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V394.Scroll.ScrollPosition
    , textEditor : Evergreen.V394.TextEditor.Model
    , profilePictureEditor : Evergreen.V394.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId, Evergreen.V394.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V394.Emoji.Model
    , voiceChat : Evergreen.V394.Call.Model
    , games : SeqDict.SeqDict Evergreen.V394.Id.GuildOrDmId Evergreen.V394.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V394.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V394.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V394.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V394.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V394.Range.Range
                , direction : Evergreen.V394.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V394.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V394.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V394.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V394.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V394.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V394.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V394.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V394.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V394.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V394.MyUi.LastCopy
    , drag : Evergreen.V394.Touch.Drag
    , dragPrevious : Evergreen.V394.Touch.Drag
    , aiChatModel : Evergreen.V394.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V394.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V394.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V394.Audio.LoadError Evergreen.V394.Audio.Source
    , startupData : Evergreen.V394.Ports.StartupData
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
    Evergreen.V394.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V394.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V394.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V394.FileStatus.FileHash
    , metadata : Maybe Evergreen.V394.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId, Evergreen.V394.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId, Evergreen.V394.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V394.DmChannelId.DmChannelId, Evergreen.V394.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId, Evergreen.V394.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId, Evergreen.V394.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId, Evergreen.V394.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V394.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V394.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V394.LocalState.BackupContents
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
    { users : Evergreen.V394.NonemptyDict.NonemptyDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V394.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V394.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V394.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V394.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V394.DmChannelId.DmChannelId Evergreen.V394.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) Evergreen.V394.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.Slack.Id Evergreen.V394.Slack.ChannelId) Evergreen.V394.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V394.OneToOne.OneToOne String (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    , slackUsers : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.Slack.Id Evergreen.V394.Slack.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    , slackServers : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.Slack.Id Evergreen.V394.Slack.TeamId) (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    , slackToken : Maybe Evergreen.V394.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V394.FileStatus.FileHash Evergreen.V394.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V394.FileStatus.FileHash
    , privateVapidKey : Evergreen.V394.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V394.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V394.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId, Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V394.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V394.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V394.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V394.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.LocalState.LoadingDiscordChannel Evergreen.V394.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V394.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V394.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V394.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId) Evergreen.V394.Sticker.StickerData
    , discordStickers : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.Discord.Id Evergreen.V394.Discord.StickerId) (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId) Evergreen.V394.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V394.OneToOne.OneToOne Evergreen.V394.RichText.DiscordCustomEmojiIdAndName (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V394.Postmark.ApiKey
    , serverSecret : Evergreen.V394.SecretId.SecretId Evergreen.V394.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V394.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.GamePublicId) ( Evergreen.V394.DmChannelId.GuildOrFullDmId, Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V394.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V394.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V394.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.Id.ThreadRoute (Maybe Evergreen.V394.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V394.DmChannelId.DmChannelId Evergreen.V394.Id.ThreadRoute (Maybe Evergreen.V394.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V394.Id.Id Evergreen.V394.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V394.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V394.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V394.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V394.UserAgent.UserAgent
    | AdminToBackend Evergreen.V394.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V394.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V394.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V394.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V394.PersonName.PersonName Evergreen.V394.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V394.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V394.Slack.OAuthCode Evergreen.V394.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V394.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V394.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V394.Id.Id Evergreen.V394.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V394.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V394.EmailAddress.EmailAddress (Result Evergreen.V394.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V394.EmailAddress.EmailAddress (Result Evergreen.V394.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V394.EmailAddress.EmailAddress (Result Evergreen.V394.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V394.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMaybeMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Result Evergreen.V394.Discord.HttpError Evergreen.V394.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V394.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Result Evergreen.V394.Discord.HttpError Evergreen.V394.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) (Result Evergreen.V394.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) (Result Evergreen.V394.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) (Result Evergreen.V394.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) (Result Evergreen.V394.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji (Result Evergreen.V394.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji (Result Evergreen.V394.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji (Result Evergreen.V394.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji (Result Evergreen.V394.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V394.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V394.Discord.HttpError (List ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId, Maybe Evergreen.V394.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Effect.Time.Posix Evergreen.V394.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V394.Slack.CurrentUser
            , team : Evergreen.V394.Slack.Team
            , users : List Evergreen.V394.Slack.User
            , channels : List ( Evergreen.V394.Slack.Channel, List Evergreen.V394.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Result Effect.Http.Error Evergreen.V394.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Discord.UserAuth (Result Evergreen.V394.Discord.HttpError Evergreen.V394.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Result Evergreen.V394.Discord.HttpError Evergreen.V394.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
        (Result
            Evergreen.V394.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId
                    , members : List (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
                    , messages : List Evergreen.V394.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId
                    , { guild : Evergreen.V394.Discord.GatewayGuild
                      , channels : List Evergreen.V394.Discord.Channel
                      , icon : Maybe Evergreen.V394.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (List Evergreen.V394.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V394.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V394.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V394.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V394.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.AttachmentId, Evergreen.V394.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V394.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.AttachmentId, Evergreen.V394.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V394.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V394.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V394.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V394.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (Result Evergreen.V394.Discord.HttpError Evergreen.V394.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Result Evergreen.V394.Discord.HttpError (List Evergreen.V394.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V394.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V394.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V394.DmChannelId.DmChannelId Evergreen.V394.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V394.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V394.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V394.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
        (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V394.Discord.HttpError
            { guild : Evergreen.V394.Discord.GatewayGuild
            , channels : List Evergreen.V394.Discord.Channel
            , icon : Maybe Evergreen.V394.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Maybe Evergreen.V394.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Result Evergreen.V394.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V394.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V394.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (List ( Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId, Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId, Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (List ( Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V394.Discord.HttpError (List Evergreen.V394.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V394.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V394.SecretId.SecretId Evergreen.V394.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V394.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V394.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V394.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V394.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Result Evergreen.V394.Discord.HttpError ( Evergreen.V394.Discord.Guild, List Evergreen.V394.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V394.FileStatus.FileHash Int (Maybe (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Call.CallId
