module Evergreen.V389.Types exposing (..)

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
import Evergreen.V389.AiChat
import Evergreen.V389.Audio
import Evergreen.V389.BackendMsgLog
import Evergreen.V389.Call
import Evergreen.V389.ChannelDescription
import Evergreen.V389.ChannelName
import Evergreen.V389.Coord
import Evergreen.V389.CssPixels
import Evergreen.V389.CustomEmoji
import Evergreen.V389.Discord
import Evergreen.V389.DiscordAttachmentId
import Evergreen.V389.DiscordUserData
import Evergreen.V389.DmChannel
import Evergreen.V389.DmChannelId
import Evergreen.V389.Drawing
import Evergreen.V389.Editable
import Evergreen.V389.EmailAddress
import Evergreen.V389.Embed
import Evergreen.V389.Emoji
import Evergreen.V389.Encryption
import Evergreen.V389.FileStatus
import Evergreen.V389.Game
import Evergreen.V389.Go
import Evergreen.V389.GuildName
import Evergreen.V389.Id
import Evergreen.V389.IdArray
import Evergreen.V389.ImageEditor
import Evergreen.V389.ImageViewer
import Evergreen.V389.LinkedAndOtherDiscordUsers
import Evergreen.V389.Local
import Evergreen.V389.LocalState
import Evergreen.V389.Log
import Evergreen.V389.LoginForm
import Evergreen.V389.MembersAndOwner
import Evergreen.V389.Message
import Evergreen.V389.MessageInput
import Evergreen.V389.MessageView
import Evergreen.V389.MuteSettings
import Evergreen.V389.MyUi
import Evergreen.V389.NonemptyDict
import Evergreen.V389.NonemptySet
import Evergreen.V389.OneOrGreater
import Evergreen.V389.OneToOne
import Evergreen.V389.Pages.Admin
import Evergreen.V389.Pagination
import Evergreen.V389.PersonName
import Evergreen.V389.Ports
import Evergreen.V389.Postmark
import Evergreen.V389.Range
import Evergreen.V389.RateLimit
import Evergreen.V389.RecoveryLogin
import Evergreen.V389.RichText
import Evergreen.V389.Route
import Evergreen.V389.Scroll
import Evergreen.V389.SecretId
import Evergreen.V389.SessionIdHash
import Evergreen.V389.SetViewing
import Evergreen.V389.SheepGame
import Evergreen.V389.Slack
import Evergreen.V389.Sticker
import Evergreen.V389.TextEditor
import Evergreen.V389.ToBackendLog
import Evergreen.V389.Touch
import Evergreen.V389.TwoFactorAuthentication
import Evergreen.V389.Ui.Anim
import Evergreen.V389.User
import Evergreen.V389.UserAgent
import Evergreen.V389.UserColor
import Evergreen.V389.UserSession
import Evergreen.V389.WordSpellingGame
import Evergreen.V389.X25519
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
    | LoginFormMsg Evergreen.V389.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V389.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V389.Pages.Admin.Msg
    | PressedLogOut Evergreen.V389.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V389.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V389.Route.Route
    | SelectedFilesToAttach ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | PressedImportChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V389.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V389.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V389.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V389.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V389.NonemptyDict.NonemptyDict Int Evergreen.V389.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V389.NonemptyDict.NonemptyDict Int Evergreen.V389.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRoute Evergreen.V389.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V389.NonemptySet.NonemptySet (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V389.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V389.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V389.AiChat.Msg
    | GameMsg Evergreen.V389.Game.Msg
    | GoSpectatorMsg Evergreen.V389.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V389.Editable.Msg Evergreen.V389.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V389.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) (Maybe Evergreen.V389.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute )
        { fileId : Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute )
        { fileId : Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage Evergreen.V389.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V389.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V389.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V389.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V389.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V389.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V389.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V389.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | PressedDisableE2ee (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | TypedPrivateKey (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V389.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId
        , otherUserId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V389.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRoute Evergreen.V389.MessageInput.Msg
    | MessageInputMsg Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRoute Evergreen.V389.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V389.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V389.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V389.Range.Range, Evergreen.V389.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V389.Range.Range, Evergreen.V389.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V389.Call.FromJs)
    | VoiceChatMsg Evergreen.V389.Call.Msg
    | PressedChannelHeaderTab Evergreen.V389.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V389.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V389.Audio.LoadError Evergreen.V389.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V389.Id.AnyGuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V389.Id.AnyGuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) Evergreen.V389.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V389.Encryption.FromJs (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V389.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V389.UserSession.UserSession
    , currentlyViewing : Evergreen.V389.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) Evergreen.V389.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.LocalState.DiscordFrontendGuild
    , user : Evergreen.V389.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.User.FrontendUser
    , discordUsers : Evergreen.V389.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V389.SessionIdHash.SessionIdHash Evergreen.V389.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V389.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId) Evergreen.V389.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId) Evergreen.V389.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V389.Call.CallId (Evergreen.V389.NonemptyDict.NonemptyDict ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V389.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V389.Go.PublicGoMatchData Evergreen.V389.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V389.Route.Route
    , windowSize : Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V389.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V389.Audio.LoadError Evergreen.V389.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Encryption.EncryptedData (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.NonemptyDict.NonemptyDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.Encryption.EncryptedData (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V389.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V389.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V389.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileData) (List Evergreen.V389.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V389.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V389.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.ChannelName.ChannelName Evergreen.V389.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.ChannelName.ChannelName Evergreen.V389.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.UserSession.ToBeFilledInByBackend (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V389.GuildName.GuildName (Evergreen.V389.UserSession.ToBeFilledInByBackend (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V389.Id.Viewing_DiscordDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V389.SetViewing.SetViewing
    | Local_SetName Evergreen.V389.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V389.Id.GuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.UserSession.ToBeFilledInByBackend Evergreen.V389.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V389.Id.GuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.Message.Message Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V389.Id.DiscordGuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V389.Id.DiscordGuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.Message.Message Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V389.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V389.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V389.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.QuestionId Evergreen.V389.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V389.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V389.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V389.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V389.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V389.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V389.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V389.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V389.NonemptySet.NonemptySet (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V389.Call.LocalChange
    | Local_Game Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Game.LocalChange
    | Local_Drawing Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Drawing.AnchorType Evergreen.V389.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V389.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V389.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V389.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V389.X25519.PublicKey (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V389.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V389.Id.Viewing_DmId (List ( Evergreen.V389.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V389.FileStatus.FileHash, Evergreen.V389.Encryption.EncryptedData (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V389.Id.Viewing_DmId (Evergreen.V389.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V389.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V389.Id.ThreadRouteWithMessage, Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V389.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V389.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V389.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V389.FileStatus.FileHash) (Evergreen.V389.Encryption.EncryptedData (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))) (Evergreen.V389.Encryption.EncryptedData String) Evergreen.V389.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V389.Id.Viewing_DmId Evergreen.V389.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V389.FileStatus.FileHash) (Evergreen.V389.Encryption.EncryptedData (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.User.FrontendUser Effect.Time.Posix Evergreen.V389.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V389.RichText.RichText (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))) Evergreen.V389.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId) Evergreen.V389.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V389.Id.DiscordGuildOrDmId Evergreen.V389.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V389.RichText.RichText (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))) Evergreen.V389.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId) Evergreen.V389.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.ChannelName.ChannelName Evergreen.V389.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.ChannelName.ChannelName Evergreen.V389.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.User.FrontendUser
    | Server_MemberLeft (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V389.LocalState.JoinGuildError
            { guildId : Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId
            , guild : Evergreen.V389.LocalState.FrontendGuild
            , owner : Evergreen.V389.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V389.RichText.RichText (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V389.RichText.RichText (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V389.Id.Viewing_DiscordDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V389.RichText.RichText (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Maybe Evergreen.V389.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Maybe Evergreen.V389.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V389.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V389.SessionIdHash.SessionIdHash Evergreen.V389.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V389.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V389.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V389.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V389.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V389.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Bool Evergreen.V389.ChannelName.ChannelName (Evergreen.V389.Discord.OptionalData (Maybe String)) (List Evergreen.V389.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
        (Evergreen.V389.NonemptyDict.NonemptyDict
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) Evergreen.V389.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Maybe (Evergreen.V389.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V389.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V389.Log.Log
    | Server_BackupGenerated Evergreen.V389.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V389.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V389.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V389.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V389.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (Evergreen.V389.Discord.OptionalData (Maybe String)) (Evergreen.V389.Discord.OptionalData (Maybe String)) (List Evergreen.V389.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.GuildName.GuildName (Maybe Evergreen.V389.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId) Evergreen.V389.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId) Evergreen.V389.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
        (Evergreen.V389.MembersAndOwner.MembersAndOwner
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.PersonName.PersonName Evergreen.V389.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId) Evergreen.V389.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId) Evergreen.V389.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V389.Call.ServerChange
    | Server_Game (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Game.LocalChange
    | Server_Drawing (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Drawing.AnchorType Evergreen.V389.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V389.Id.Viewing_DmId ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Evergreen.V389.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V389.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V389.Id.Viewing_DmId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | Server_E2eeAccepted Evergreen.V389.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.User.FrontendUser Effect.Time.Posix Evergreen.V389.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V389.FileStatus.FileHash) (Evergreen.V389.Encryption.EncryptedData (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))) Evergreen.V389.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.Viewing_DmId Evergreen.V389.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V389.FileStatus.FileHash) (Evergreen.V389.Encryption.EncryptedData (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V389.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V389.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V389.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V389.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V389.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V389.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V389.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V389.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V389.Id.AnyGuildOrDmId Evergreen.V389.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V389.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels) (Maybe Evergreen.V389.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V389.SheepGame.Input (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels) (Maybe Evergreen.V389.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V389.Id.GuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V389.Id.GuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId) (Evergreen.V389.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V389.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V389.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V389.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , threadRoute : Evergreen.V389.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V389.Encryption.BytesHash
    , id : Evergreen.V389.Id.Viewing_DmId
    , senderId : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , threadRoute : Evergreen.V389.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V389.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V389.Id.Viewing_DmId
    , messages : List Evergreen.V389.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V389.Id.Viewing_DmId
    , messages : List ( Evergreen.V389.Id.ThreadRouteWithMessage, Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V389.Id.Viewing_DmId
    , threadRoute : Evergreen.V389.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute )
    , fileId : Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V389.Id.Id Evergreen.V389.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V389.Id.Id Evergreen.V389.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V389.Id.Id Evergreen.V389.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V389.Id.Id Evergreen.V389.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V389.Id.Id Evergreen.V389.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V389.Local.Local LocalMsg Evergreen.V389.LocalState.LocalState
    , admin : Evergreen.V389.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId, Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V389.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V389.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.Message.RepliedTo Evergreen.V389.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V389.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V389.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V389.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.ThreadRoute ) (Evergreen.V389.NonemptyDict.NonemptyDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V389.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V389.Scroll.ScrollPosition
    , textEditor : Evergreen.V389.TextEditor.Model
    , profilePictureEditor : Evergreen.V389.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId, Evergreen.V389.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V389.Emoji.Model
    , voiceChat : Evergreen.V389.Call.Model
    , games : SeqDict.SeqDict Evergreen.V389.Id.GuildOrDmId Evergreen.V389.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V389.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V389.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V389.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V389.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V389.Range.Range
                , direction : Evergreen.V389.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V389.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V389.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V389.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V389.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V389.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V389.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V389.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V389.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V389.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V389.MyUi.LastCopy
    , drag : Evergreen.V389.Touch.Drag
    , dragPrevious : Evergreen.V389.Touch.Drag
    , aiChatModel : Evergreen.V389.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V389.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V389.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V389.Audio.LoadError Evergreen.V389.Audio.Source
    , startupData : Evergreen.V389.Ports.StartupData
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
    Evergreen.V389.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V389.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V389.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V389.FileStatus.FileHash
    , metadata : Maybe Evergreen.V389.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId, Evergreen.V389.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId, Evergreen.V389.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V389.DmChannelId.DmChannelId, Evergreen.V389.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId, Evergreen.V389.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId, Evergreen.V389.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId, Evergreen.V389.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V389.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V389.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V389.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V389.NonemptyDict.NonemptyDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V389.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V389.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V389.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V389.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V389.DmChannelId.DmChannelId Evergreen.V389.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) Evergreen.V389.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.Slack.Id Evergreen.V389.Slack.ChannelId) Evergreen.V389.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V389.OneToOne.OneToOne String (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    , slackUsers : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.Slack.Id Evergreen.V389.Slack.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    , slackServers : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.Slack.Id Evergreen.V389.Slack.TeamId) (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    , slackToken : Maybe Evergreen.V389.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V389.FileStatus.FileHash Evergreen.V389.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V389.FileStatus.FileHash
    , privateVapidKey : Evergreen.V389.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V389.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V389.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId, Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V389.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V389.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V389.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V389.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.LocalState.LoadingDiscordChannel Evergreen.V389.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V389.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V389.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V389.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId) Evergreen.V389.Sticker.StickerData
    , discordStickers : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.Discord.Id Evergreen.V389.Discord.StickerId) (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId) Evergreen.V389.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V389.OneToOne.OneToOne Evergreen.V389.RichText.DiscordCustomEmojiIdAndName (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V389.Postmark.ApiKey
    , serverSecret : Evergreen.V389.SecretId.SecretId Evergreen.V389.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V389.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.GamePublicId) ( Evergreen.V389.DmChannelId.GuildOrFullDmId, Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V389.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V389.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V389.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.Id.ThreadRoute (Maybe Evergreen.V389.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V389.DmChannelId.DmChannelId Evergreen.V389.Id.ThreadRoute (Maybe Evergreen.V389.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V389.Id.Id Evergreen.V389.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V389.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V389.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V389.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V389.UserAgent.UserAgent
    | AdminToBackend Evergreen.V389.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V389.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V389.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V389.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V389.PersonName.PersonName Evergreen.V389.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V389.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V389.Slack.OAuthCode Evergreen.V389.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V389.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V389.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V389.Id.Id Evergreen.V389.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V389.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V389.EmailAddress.EmailAddress (Result Evergreen.V389.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V389.EmailAddress.EmailAddress (Result Evergreen.V389.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V389.EmailAddress.EmailAddress (Result Evergreen.V389.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V389.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMaybeMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Result Evergreen.V389.Discord.HttpError Evergreen.V389.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V389.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Result Evergreen.V389.Discord.HttpError Evergreen.V389.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) (Result Evergreen.V389.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) (Result Evergreen.V389.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) (Result Evergreen.V389.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) (Result Evergreen.V389.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji (Result Evergreen.V389.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji (Result Evergreen.V389.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji (Result Evergreen.V389.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji (Result Evergreen.V389.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V389.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V389.Discord.HttpError (List ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId, Maybe Evergreen.V389.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Effect.Time.Posix Evergreen.V389.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V389.Slack.CurrentUser
            , team : Evergreen.V389.Slack.Team
            , users : List Evergreen.V389.Slack.User
            , channels : List ( Evergreen.V389.Slack.Channel, List Evergreen.V389.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Result Effect.Http.Error Evergreen.V389.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Discord.UserAuth (Result Evergreen.V389.Discord.HttpError Evergreen.V389.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Result Evergreen.V389.Discord.HttpError Evergreen.V389.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
        (Result
            Evergreen.V389.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId
                    , members : List (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
                    , messages : List Evergreen.V389.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId
                    , { guild : Evergreen.V389.Discord.GatewayGuild
                      , channels : List Evergreen.V389.Discord.Channel
                      , icon : Maybe Evergreen.V389.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (List Evergreen.V389.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V389.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V389.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V389.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V389.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.AttachmentId, Evergreen.V389.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V389.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.AttachmentId, Evergreen.V389.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V389.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V389.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V389.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V389.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (Result Evergreen.V389.Discord.HttpError Evergreen.V389.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Result Evergreen.V389.Discord.HttpError (List Evergreen.V389.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V389.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V389.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V389.DmChannelId.DmChannelId Evergreen.V389.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V389.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V389.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V389.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
        (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V389.Discord.HttpError
            { guild : Evergreen.V389.Discord.GatewayGuild
            , channels : List Evergreen.V389.Discord.Channel
            , icon : Maybe Evergreen.V389.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Maybe Evergreen.V389.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Result Evergreen.V389.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V389.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V389.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (List ( Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId, Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId, Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (List ( Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V389.Discord.HttpError (List Evergreen.V389.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V389.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V389.SecretId.SecretId Evergreen.V389.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V389.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V389.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V389.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V389.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Result Evergreen.V389.Discord.HttpError ( Evergreen.V389.Discord.Guild, List Evergreen.V389.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V389.FileStatus.FileHash Int (Maybe (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Call.CallId
