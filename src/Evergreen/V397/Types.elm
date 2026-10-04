module Evergreen.V397.Types exposing (..)

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
import Evergreen.V397.AiChat
import Evergreen.V397.Audio
import Evergreen.V397.BackendMsgLog
import Evergreen.V397.Call
import Evergreen.V397.ChannelDescription
import Evergreen.V397.ChannelName
import Evergreen.V397.Coord
import Evergreen.V397.CssPixels
import Evergreen.V397.CustomEmoji
import Evergreen.V397.Discord
import Evergreen.V397.DiscordAttachmentId
import Evergreen.V397.DiscordUserData
import Evergreen.V397.DmChannel
import Evergreen.V397.DmChannelId
import Evergreen.V397.Drawing
import Evergreen.V397.Editable
import Evergreen.V397.EmailAddress
import Evergreen.V397.Embed
import Evergreen.V397.Emoji
import Evergreen.V397.Encryption
import Evergreen.V397.FileStatus
import Evergreen.V397.Game
import Evergreen.V397.Go
import Evergreen.V397.GuildName
import Evergreen.V397.Id
import Evergreen.V397.IdArray
import Evergreen.V397.ImageEditor
import Evergreen.V397.ImageViewer
import Evergreen.V397.LinkedAndOtherDiscordUsers
import Evergreen.V397.Local
import Evergreen.V397.LocalState
import Evergreen.V397.Log
import Evergreen.V397.LoginForm
import Evergreen.V397.MembersAndOwner
import Evergreen.V397.Message
import Evergreen.V397.MessageInput
import Evergreen.V397.MessageView
import Evergreen.V397.MuteSettings
import Evergreen.V397.MyUi
import Evergreen.V397.NonemptyDict
import Evergreen.V397.NonemptySet
import Evergreen.V397.OneOrGreater
import Evergreen.V397.OneToOne
import Evergreen.V397.Pages.Admin
import Evergreen.V397.Pagination
import Evergreen.V397.PersonName
import Evergreen.V397.Ports
import Evergreen.V397.Postmark
import Evergreen.V397.Range
import Evergreen.V397.RateLimit
import Evergreen.V397.RecoveryLogin
import Evergreen.V397.RichText
import Evergreen.V397.Route
import Evergreen.V397.Scroll
import Evergreen.V397.SecretId
import Evergreen.V397.SessionIdHash
import Evergreen.V397.SetViewing
import Evergreen.V397.SheepGame
import Evergreen.V397.Slack
import Evergreen.V397.Sticker
import Evergreen.V397.TextEditor
import Evergreen.V397.ToBackendLog
import Evergreen.V397.Touch
import Evergreen.V397.TwoFactorAuthentication
import Evergreen.V397.Ui.Anim
import Evergreen.V397.User
import Evergreen.V397.UserAgent
import Evergreen.V397.UserColor
import Evergreen.V397.UserSession
import Evergreen.V397.WordSpellingGame
import Evergreen.V397.X25519
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
    | LoginFormMsg Evergreen.V397.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V397.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V397.Pages.Admin.Msg
    | PressedLogOut Evergreen.V397.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V397.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V397.Route.Route
    | SelectedFilesToAttach ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | PressedImportChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V397.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V397.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V397.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V397.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V397.NonemptyDict.NonemptyDict Int Evergreen.V397.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V397.NonemptyDict.NonemptyDict Int Evergreen.V397.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRoute Evergreen.V397.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V397.NonemptySet.NonemptySet (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V397.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V397.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V397.AiChat.Msg
    | GameMsg Evergreen.V397.Game.Msg
    | GoSpectatorMsg Evergreen.V397.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V397.Editable.Msg Evergreen.V397.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V397.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) (Maybe Evergreen.V397.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute )
        { fileId : Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute )
        { fileId : Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage Evergreen.V397.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V397.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V397.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V397.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V397.User.EmailNotifications
    | SelectedEmbedVisibility Evergreen.V397.User.EmbedVisibility
    | PressedDeleteAccount
    | PressedAccountDeletionBanner
    | PressedCloseAccountDeletionBanner
    | PressedGuildNotificationLevel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V397.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V397.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | PressedDisableE2ee (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | TypedPrivateKey (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V397.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId
        , otherUserId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V397.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRoute Evergreen.V397.MessageInput.Msg
    | MessageInputMsg Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRoute Evergreen.V397.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V397.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V397.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V397.Range.Range, Evergreen.V397.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V397.Range.Range, Evergreen.V397.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V397.Call.FromJs)
    | VoiceChatMsg Evergreen.V397.Call.Msg
    | PressedChannelHeaderTab Evergreen.V397.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V397.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V397.Audio.LoadError Evergreen.V397.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V397.Id.AnyGuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V397.Id.AnyGuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) Evergreen.V397.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V397.Encryption.FromJs (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V397.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V397.UserSession.UserSession
    , currentlyViewing : Evergreen.V397.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) Evergreen.V397.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.LocalState.DiscordFrontendGuild
    , user : Evergreen.V397.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.User.FrontendUser
    , discordUsers : Evergreen.V397.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V397.SessionIdHash.SessionIdHash Evergreen.V397.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V397.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId) Evergreen.V397.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId) Evergreen.V397.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V397.Call.CallId (Evergreen.V397.NonemptyDict.NonemptyDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V397.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V397.Go.PublicGoMatchData Evergreen.V397.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V397.Route.Route
    , windowSize : Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V397.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V397.Audio.LoadError Evergreen.V397.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Encryption.EncryptedData (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.NonemptyDict.NonemptyDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Encryption.EncryptedData (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V397.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V397.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V397.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData) (List Evergreen.V397.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V397.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V397.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.ChannelName.ChannelName Evergreen.V397.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.ChannelName.ChannelName Evergreen.V397.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.UserSession.ToBeFilledInByBackend (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V397.GuildName.GuildName (Evergreen.V397.UserSession.ToBeFilledInByBackend (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V397.Id.Viewing_DiscordDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V397.SetViewing.SetViewing
    | Local_SetName Evergreen.V397.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V397.Id.GuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.UserSession.ToBeFilledInByBackend Evergreen.V397.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V397.Id.GuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V397.Id.DiscordGuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V397.Id.DiscordGuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V397.UserSession.NotificationMode
    | Local_ExpandUserOptionSection
        Evergreen.V397.UserSession.UserOptionSection
        { collapseOthers : Bool
        }
    | Local_CollapseUserOptionSection Evergreen.V397.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.QuestionId Evergreen.V397.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V397.User.EmailNotifications
    | Local_SetEmbedVisibility Evergreen.V397.User.EmbedVisibility
    | Local_ScheduleAccountDeletion Effect.Time.Posix
    | Local_CancelAccountDeletion
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V397.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V397.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V397.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V397.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V397.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V397.NonemptySet.NonemptySet (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V397.Call.LocalChange
    | Local_Game Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Game.LocalChange
    | Local_Drawing Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Drawing.AnchorType Evergreen.V397.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V397.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V397.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V397.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V397.X25519.PublicKey (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V397.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V397.Id.Viewing_DmId (List ( Evergreen.V397.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V397.FileStatus.FileHash, Evergreen.V397.Encryption.EncryptedData (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V397.Id.Viewing_DmId (Evergreen.V397.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V397.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V397.Id.ThreadRouteWithMessage, Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V397.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V397.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V397.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V397.FileStatus.FileHash) (Evergreen.V397.Encryption.EncryptedData (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))) (Evergreen.V397.Encryption.EncryptedData String) Evergreen.V397.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V397.Id.Viewing_DmId Evergreen.V397.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V397.FileStatus.FileHash) (Evergreen.V397.Encryption.EncryptedData (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.User.FrontendUser Effect.Time.Posix Evergreen.V397.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V397.RichText.RichText (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))) Evergreen.V397.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId) Evergreen.V397.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V397.Id.DiscordGuildOrDmId Evergreen.V397.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V397.RichText.RichText (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))) Evergreen.V397.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId) Evergreen.V397.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.ChannelName.ChannelName Evergreen.V397.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.ChannelName.ChannelName Evergreen.V397.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.User.FrontendUser
    | Server_MemberLeft (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V397.LocalState.JoinGuildError
            { guildId : Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId
            , guild : Evergreen.V397.LocalState.FrontendGuild
            , owner : Evergreen.V397.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V397.RichText.RichText (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V397.RichText.RichText (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V397.Id.Viewing_DiscordDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V397.RichText.RichText (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Maybe Evergreen.V397.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Maybe Evergreen.V397.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V397.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V397.SessionIdHash.SessionIdHash Evergreen.V397.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V397.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V397.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V397.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V397.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V397.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Bool Evergreen.V397.ChannelName.ChannelName (Evergreen.V397.Discord.OptionalData (Maybe String)) (List Evergreen.V397.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
        (Evergreen.V397.NonemptyDict.NonemptyDict
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) Evergreen.V397.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Maybe (Evergreen.V397.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V397.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V397.Log.Log
    | Server_BackupGenerated Evergreen.V397.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V397.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V397.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V397.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V397.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (Evergreen.V397.Discord.OptionalData (Maybe String)) (Evergreen.V397.Discord.OptionalData (Maybe String)) (List Evergreen.V397.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.GuildName.GuildName (Maybe Evergreen.V397.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId) Evergreen.V397.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId) Evergreen.V397.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
        (Evergreen.V397.MembersAndOwner.MembersAndOwner
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.PersonName.PersonName Evergreen.V397.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId) Evergreen.V397.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId) Evergreen.V397.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V397.Call.ServerChange
    | Server_Game (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Game.LocalChange
    | Server_Drawing (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Drawing.AnchorType Evergreen.V397.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V397.Id.Viewing_DmId ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V397.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V397.Id.Viewing_DmId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | Server_E2eeAccepted Evergreen.V397.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.User.FrontendUser Effect.Time.Posix Evergreen.V397.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V397.FileStatus.FileHash) (Evergreen.V397.Encryption.EncryptedData (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))) Evergreen.V397.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.Viewing_DmId Evergreen.V397.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V397.FileStatus.FileHash) (Evergreen.V397.Encryption.EncryptedData (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V397.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V397.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V397.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V397.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V397.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V397.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V397.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V397.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V397.Id.AnyGuildOrDmId Evergreen.V397.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V397.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels) (Maybe Evergreen.V397.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V397.SheepGame.Input (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels) (Maybe Evergreen.V397.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V397.Id.GuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V397.Id.GuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V397.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V397.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V397.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , threadRoute : Evergreen.V397.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V397.Encryption.BytesHash
    , id : Evergreen.V397.Id.Viewing_DmId
    , senderId : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , threadRoute : Evergreen.V397.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V397.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V397.Id.Viewing_DmId
    , messages : List Evergreen.V397.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V397.Id.Viewing_DmId
    , messages : List ( Evergreen.V397.Id.ThreadRouteWithMessage, Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V397.Id.Viewing_DmId
    , threadRoute : Evergreen.V397.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute )
    , fileId : Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V397.Id.Id Evergreen.V397.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V397.Id.Id Evergreen.V397.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V397.Id.Id Evergreen.V397.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V397.Id.Id Evergreen.V397.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V397.Id.Id Evergreen.V397.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V397.Local.Local LocalMsg Evergreen.V397.LocalState.LocalState
    , admin : Evergreen.V397.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V397.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V397.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.Message.RepliedTo Evergreen.V397.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V397.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V397.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V397.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.ThreadRoute ) (Evergreen.V397.NonemptyDict.NonemptyDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V397.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V397.Scroll.ScrollPosition
    , textEditor : Evergreen.V397.TextEditor.Model
    , profilePictureEditor : Evergreen.V397.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId, Evergreen.V397.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V397.Emoji.Model
    , voiceChat : Evergreen.V397.Call.Model
    , games : SeqDict.SeqDict Evergreen.V397.Id.GuildOrDmId Evergreen.V397.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V397.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V397.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Bool
    , typedTextCounter : Int
    , accountDeletionBannerClosed : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V397.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V397.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V397.Range.Range
                , direction : Evergreen.V397.Range.SelectionDirection
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
    = LinkDiscordHttpError Evergreen.V397.Discord.HttpError
    | LinkDiscordLimitReached


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V397.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V397.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V397.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V397.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result LinkDiscordFailure ())
    | ProfilePictureEditorToFrontend Evergreen.V397.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V397.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V397.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V397.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V397.MyUi.LastCopy
    , drag : Evergreen.V397.Touch.Drag
    , dragPrevious : Evergreen.V397.Touch.Drag
    , aiChatModel : Evergreen.V397.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V397.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V397.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V397.Audio.LoadError Evergreen.V397.Audio.Source
    , startupData : Evergreen.V397.Ports.StartupData
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
    Evergreen.V397.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V397.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V397.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V397.FileStatus.FileHash
    , metadata : Maybe Evergreen.V397.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId, Evergreen.V397.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId, Evergreen.V397.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V397.DmChannelId.DmChannelId, Evergreen.V397.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId, Evergreen.V397.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId, Evergreen.V397.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId, Evergreen.V397.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V397.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V397.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias DownloadBackupState =
    { contents : Evergreen.V397.LocalState.BackupContents
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
    { users : Evergreen.V397.NonemptyDict.NonemptyDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V397.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V397.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V397.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V397.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V397.DmChannelId.DmChannelId Evergreen.V397.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) Evergreen.V397.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.Slack.Id Evergreen.V397.Slack.ChannelId) Evergreen.V397.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V397.OneToOne.OneToOne String (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    , slackUsers : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.Slack.Id Evergreen.V397.Slack.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    , slackServers : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.Slack.Id Evergreen.V397.Slack.TeamId) (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    , slackToken : Maybe Evergreen.V397.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V397.FileStatus.FileHash Evergreen.V397.FileStatus.BackendFileData
    , orphanedFilesLastHour : SeqSet.SeqSet Evergreen.V397.FileStatus.FileHash
    , privateVapidKey : Evergreen.V397.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V397.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V397.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId, Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V397.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V397.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V397.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V397.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.LocalState.LoadingDiscordChannel Evergreen.V397.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , discordLinkLimit : Maybe Int
    , downloadBackupState : Maybe BackupTransfer
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V397.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V397.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V397.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId) Evergreen.V397.Sticker.StickerData
    , discordStickers : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.Discord.Id Evergreen.V397.Discord.StickerId) (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId) Evergreen.V397.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V397.OneToOne.OneToOne Evergreen.V397.RichText.DiscordCustomEmojiIdAndName (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V397.Postmark.ApiKey
    , serverSecret : Evergreen.V397.SecretId.SecretId Evergreen.V397.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V397.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.GamePublicId) ( Evergreen.V397.DmChannelId.GuildOrFullDmId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V397.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V397.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V397.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.Id.ThreadRoute (Maybe Evergreen.V397.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V397.DmChannelId.DmChannelId Evergreen.V397.Id.ThreadRoute (Maybe Evergreen.V397.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V397.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V397.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V397.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V397.UserAgent.UserAgent
    | AdminToBackend Evergreen.V397.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V397.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V397.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V397.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V397.PersonName.PersonName Evergreen.V397.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V397.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V397.Slack.OAuthCode Evergreen.V397.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V397.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V397.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V397.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V397.EmailAddress.EmailAddress (Result Evergreen.V397.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V397.EmailAddress.EmailAddress (Result Evergreen.V397.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V397.EmailAddress.EmailAddress (Result Evergreen.V397.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V397.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMaybeMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Result Evergreen.V397.Discord.HttpError Evergreen.V397.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V397.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Result Evergreen.V397.Discord.HttpError Evergreen.V397.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) (Result Evergreen.V397.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) (Result Evergreen.V397.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) (Result Evergreen.V397.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) (Result Evergreen.V397.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji (Result Evergreen.V397.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji (Result Evergreen.V397.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji (Result Evergreen.V397.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji (Result Evergreen.V397.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V397.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V397.Discord.HttpError (List ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId, Maybe Evergreen.V397.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Effect.Time.Posix Evergreen.V397.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V397.Slack.CurrentUser
            , team : Evergreen.V397.Slack.Team
            , users : List Evergreen.V397.Slack.User
            , channels : List ( Evergreen.V397.Slack.Channel, List Evergreen.V397.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Result Effect.Http.Error Evergreen.V397.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Discord.UserAuth (Result Evergreen.V397.Discord.HttpError Evergreen.V397.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Result Evergreen.V397.Discord.HttpError Evergreen.V397.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
        (Result
            Evergreen.V397.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId
                    , members : List (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
                    , messages : List Evergreen.V397.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId
                    , { guild : Evergreen.V397.Discord.GatewayGuild
                      , channels : List Evergreen.V397.Discord.Channel
                      , icon : Maybe Evergreen.V397.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (List Evergreen.V397.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V397.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V397.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V397.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V397.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.AttachmentId, Evergreen.V397.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V397.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.AttachmentId, Evergreen.V397.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V397.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V397.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V397.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V397.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (Result Evergreen.V397.Discord.HttpError Evergreen.V397.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Result Evergreen.V397.Discord.HttpError (List Evergreen.V397.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V397.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V397.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V397.DmChannelId.DmChannelId Evergreen.V397.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V397.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V397.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V397.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
        (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V397.Discord.HttpError
            { guild : Evergreen.V397.Discord.GatewayGuild
            , channels : List Evergreen.V397.Discord.Channel
            , icon : Maybe Evergreen.V397.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Maybe Evergreen.V397.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Result Evergreen.V397.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V397.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V397.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (List ( Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId, Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId, Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (List ( Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V397.Discord.HttpError (List Evergreen.V397.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V397.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V397.SecretId.SecretId Evergreen.V397.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V397.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V397.FileStatus.FileHash) (Result Effect.Http.Error ())
    | HourlyDeletedOrphanedFiles Effect.Time.Posix (List Evergreen.V397.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V397.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Result Evergreen.V397.Discord.HttpError ( Evergreen.V397.Discord.Guild, List Evergreen.V397.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V397.FileStatus.FileHash Int (Maybe (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Call.CallId
