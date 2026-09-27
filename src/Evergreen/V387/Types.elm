module Evergreen.V387.Types exposing (..)

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
import Evergreen.V387.AiChat
import Evergreen.V387.Audio
import Evergreen.V387.BackendMsgLog
import Evergreen.V387.Call
import Evergreen.V387.ChannelDescription
import Evergreen.V387.ChannelName
import Evergreen.V387.Coord
import Evergreen.V387.CssPixels
import Evergreen.V387.CustomEmoji
import Evergreen.V387.Discord
import Evergreen.V387.DiscordAttachmentId
import Evergreen.V387.DiscordUserData
import Evergreen.V387.DmChannel
import Evergreen.V387.DmChannelId
import Evergreen.V387.Drawing
import Evergreen.V387.Editable
import Evergreen.V387.EmailAddress
import Evergreen.V387.Embed
import Evergreen.V387.Emoji
import Evergreen.V387.Encryption
import Evergreen.V387.FileStatus
import Evergreen.V387.Game
import Evergreen.V387.Go
import Evergreen.V387.GuildName
import Evergreen.V387.Id
import Evergreen.V387.IdArray
import Evergreen.V387.ImageEditor
import Evergreen.V387.ImageViewer
import Evergreen.V387.LinkedAndOtherDiscordUsers
import Evergreen.V387.Local
import Evergreen.V387.LocalState
import Evergreen.V387.Log
import Evergreen.V387.LoginForm
import Evergreen.V387.MembersAndOwner
import Evergreen.V387.Message
import Evergreen.V387.MessageInput
import Evergreen.V387.MessageView
import Evergreen.V387.MuteSettings
import Evergreen.V387.MyUi
import Evergreen.V387.NonemptyDict
import Evergreen.V387.NonemptySet
import Evergreen.V387.OneOrGreater
import Evergreen.V387.OneToOne
import Evergreen.V387.Pages.Admin
import Evergreen.V387.Pagination
import Evergreen.V387.PersonName
import Evergreen.V387.Ports
import Evergreen.V387.Postmark
import Evergreen.V387.Range
import Evergreen.V387.RateLimit
import Evergreen.V387.RecoveryLogin
import Evergreen.V387.RichText
import Evergreen.V387.Route
import Evergreen.V387.Scroll
import Evergreen.V387.SecretId
import Evergreen.V387.SessionIdHash
import Evergreen.V387.SetViewing
import Evergreen.V387.SheepGame
import Evergreen.V387.Slack
import Evergreen.V387.Sticker
import Evergreen.V387.TextEditor
import Evergreen.V387.ToBackendLog
import Evergreen.V387.Touch
import Evergreen.V387.TwoFactorAuthentication
import Evergreen.V387.Ui.Anim
import Evergreen.V387.User
import Evergreen.V387.UserAgent
import Evergreen.V387.UserColor
import Evergreen.V387.UserSession
import Evergreen.V387.WordSpellingGame
import Evergreen.V387.X25519
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
    | LoginFormMsg Evergreen.V387.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V387.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V387.Pages.Admin.Msg
    | PressedLogOut Evergreen.V387.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V387.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V387.Route.Route
    | SelectedFilesToAttach ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | PressedImportChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V387.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V387.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V387.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V387.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V387.NonemptyDict.NonemptyDict Int Evergreen.V387.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V387.NonemptyDict.NonemptyDict Int Evergreen.V387.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRoute Evergreen.V387.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V387.NonemptySet.NonemptySet (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V387.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V387.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V387.AiChat.Msg
    | GameMsg Evergreen.V387.Game.Msg
    | GoSpectatorMsg Evergreen.V387.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V387.Editable.Msg Evergreen.V387.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V387.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) (Maybe Evergreen.V387.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute )
        { fileId : Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute )
        { fileId : Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage Evergreen.V387.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V387.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V387.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V387.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V387.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V387.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V387.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | PressedDisableE2ee (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | TypedPrivateKey (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V387.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId
        , otherUserId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V387.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRoute Evergreen.V387.MessageInput.Msg
    | MessageInputMsg Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRoute Evergreen.V387.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V387.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V387.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V387.Range.Range, Evergreen.V387.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V387.Range.Range, Evergreen.V387.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V387.Call.FromJs)
    | VoiceChatMsg Evergreen.V387.Call.Msg
    | PressedChannelHeaderTab Evergreen.V387.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V387.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V387.Audio.LoadError Evergreen.V387.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V387.Id.AnyGuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V387.Id.AnyGuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) Evergreen.V387.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V387.Encryption.FromJs (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V387.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V387.UserSession.UserSession
    , currentlyViewing : Evergreen.V387.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) Evergreen.V387.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.LocalState.DiscordFrontendGuild
    , user : Evergreen.V387.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.User.FrontendUser
    , discordUsers : Evergreen.V387.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V387.SessionIdHash.SessionIdHash Evergreen.V387.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V387.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId) Evergreen.V387.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId) Evergreen.V387.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V387.Call.CallId (Evergreen.V387.NonemptyDict.NonemptyDict ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V387.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V387.Go.PublicGoMatchData Evergreen.V387.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V387.Route.Route
    , windowSize : Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V387.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V387.Audio.LoadError Evergreen.V387.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Encryption.EncryptedData (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.NonemptyDict.NonemptyDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.Encryption.EncryptedData (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V387.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V387.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V387.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileData) (List Evergreen.V387.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V387.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V387.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.ChannelName.ChannelName Evergreen.V387.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.ChannelName.ChannelName Evergreen.V387.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.UserSession.ToBeFilledInByBackend (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V387.GuildName.GuildName (Evergreen.V387.UserSession.ToBeFilledInByBackend (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V387.Id.Viewing_DiscordDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V387.SetViewing.SetViewing
    | Local_SetName Evergreen.V387.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V387.Id.GuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.UserSession.ToBeFilledInByBackend Evergreen.V387.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V387.Id.GuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.Message.Message Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V387.Id.DiscordGuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V387.Id.DiscordGuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.Message.Message Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V387.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V387.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V387.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.QuestionId Evergreen.V387.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V387.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V387.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V387.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V387.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V387.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V387.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V387.NonemptySet.NonemptySet (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V387.Call.LocalChange
    | Local_Game Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Game.LocalChange
    | Local_Drawing Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Drawing.AnchorType Evergreen.V387.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V387.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V387.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V387.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V387.X25519.PublicKey (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V387.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V387.Id.Viewing_DmId (List ( Evergreen.V387.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V387.FileStatus.FileHash, Evergreen.V387.Encryption.EncryptedData (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V387.Id.Viewing_DmId (Evergreen.V387.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V387.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V387.Id.ThreadRouteWithMessage, Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V387.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V387.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V387.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V387.FileStatus.FileHash) (Evergreen.V387.Encryption.EncryptedData (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))) (Evergreen.V387.Encryption.EncryptedData String) Evergreen.V387.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V387.Id.Viewing_DmId Evergreen.V387.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V387.FileStatus.FileHash) (Evergreen.V387.Encryption.EncryptedData (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.User.FrontendUser Effect.Time.Posix Evergreen.V387.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V387.RichText.RichText (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))) Evergreen.V387.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId) Evergreen.V387.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V387.Id.DiscordGuildOrDmId Evergreen.V387.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V387.RichText.RichText (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))) Evergreen.V387.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId) Evergreen.V387.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.ChannelName.ChannelName Evergreen.V387.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.ChannelName.ChannelName Evergreen.V387.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.User.FrontendUser
    | Server_MemberLeft (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V387.LocalState.JoinGuildError
            { guildId : Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId
            , guild : Evergreen.V387.LocalState.FrontendGuild
            , owner : Evergreen.V387.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V387.RichText.RichText (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V387.RichText.RichText (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V387.Id.Viewing_DiscordDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V387.RichText.RichText (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Maybe Evergreen.V387.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Maybe Evergreen.V387.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V387.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V387.SessionIdHash.SessionIdHash Evergreen.V387.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V387.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V387.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V387.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V387.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V387.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Bool Evergreen.V387.ChannelName.ChannelName (Evergreen.V387.Discord.OptionalData (Maybe String)) (List Evergreen.V387.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
        (Evergreen.V387.NonemptyDict.NonemptyDict
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) Evergreen.V387.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Maybe (Evergreen.V387.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V387.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V387.Log.Log
    | Server_BackupGenerated Evergreen.V387.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V387.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V387.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V387.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V387.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (Evergreen.V387.Discord.OptionalData (Maybe String)) (Evergreen.V387.Discord.OptionalData (Maybe String)) (List Evergreen.V387.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.GuildName.GuildName (Maybe Evergreen.V387.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId) Evergreen.V387.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId) Evergreen.V387.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
        (Evergreen.V387.MembersAndOwner.MembersAndOwner
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.PersonName.PersonName Evergreen.V387.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId) Evergreen.V387.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId) Evergreen.V387.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V387.Call.ServerChange
    | Server_Game (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Game.LocalChange
    | Server_Drawing (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Drawing.AnchorType Evergreen.V387.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V387.Id.Viewing_DmId ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Evergreen.V387.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V387.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V387.Id.Viewing_DmId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | Server_E2eeAccepted Evergreen.V387.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.User.FrontendUser Effect.Time.Posix Evergreen.V387.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V387.FileStatus.FileHash) (Evergreen.V387.Encryption.EncryptedData (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))) Evergreen.V387.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.Viewing_DmId Evergreen.V387.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V387.FileStatus.FileHash) (Evergreen.V387.Encryption.EncryptedData (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V387.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V387.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V387.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V387.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V387.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V387.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V387.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V387.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V387.Id.AnyGuildOrDmId Evergreen.V387.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V387.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels) (Maybe Evergreen.V387.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V387.SheepGame.Input (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels) (Maybe Evergreen.V387.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V387.Id.GuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V387.Id.GuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId) (Evergreen.V387.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V387.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V387.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V387.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , threadRoute : Evergreen.V387.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V387.Encryption.BytesHash
    , id : Evergreen.V387.Id.Viewing_DmId
    , senderId : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , threadRoute : Evergreen.V387.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V387.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V387.Id.Viewing_DmId
    , messages : List Evergreen.V387.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V387.Id.Viewing_DmId
    , messages : List ( Evergreen.V387.Id.ThreadRouteWithMessage, Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V387.Id.Viewing_DmId
    , threadRoute : Evergreen.V387.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute )
    , fileId : Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V387.Id.Id Evergreen.V387.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V387.Id.Id Evergreen.V387.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V387.Id.Id Evergreen.V387.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V387.Id.Id Evergreen.V387.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V387.Id.Id Evergreen.V387.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V387.Local.Local LocalMsg Evergreen.V387.LocalState.LocalState
    , admin : Evergreen.V387.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId, Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V387.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V387.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.Message.RepliedTo Evergreen.V387.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V387.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V387.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V387.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.ThreadRoute ) (Evergreen.V387.NonemptyDict.NonemptyDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V387.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V387.Scroll.ScrollPosition
    , textEditor : Evergreen.V387.TextEditor.Model
    , profilePictureEditor : Evergreen.V387.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId, Evergreen.V387.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V387.Emoji.Model
    , voiceChat : Evergreen.V387.Call.Model
    , games : SeqDict.SeqDict Evergreen.V387.Id.GuildOrDmId Evergreen.V387.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V387.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V387.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V387.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V387.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V387.Range.Range
                , direction : Evergreen.V387.Range.SelectionDirection
                }
        }


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup
    | RecoveryPasswordInvalid


type ToFrontend
    = CheckLoginResponse LoginType (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V387.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V387.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V387.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V387.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V387.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V387.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V387.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V387.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V387.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V387.MyUi.LastCopy
    , drag : Evergreen.V387.Touch.Drag
    , dragPrevious : Evergreen.V387.Touch.Drag
    , aiChatModel : Evergreen.V387.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V387.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V387.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V387.Audio.LoadError Evergreen.V387.Audio.Source
    , startupData : Evergreen.V387.Ports.StartupData
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
    Evergreen.V387.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V387.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V387.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V387.FileStatus.FileHash
    , metadata : Maybe Evergreen.V387.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId, Evergreen.V387.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId, Evergreen.V387.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V387.DmChannelId.DmChannelId, Evergreen.V387.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId, Evergreen.V387.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId, Evergreen.V387.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId, Evergreen.V387.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V387.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V387.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V387.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V387.NonemptyDict.NonemptyDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V387.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V387.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V387.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V387.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V387.DmChannelId.DmChannelId Evergreen.V387.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) Evergreen.V387.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.Slack.Id Evergreen.V387.Slack.ChannelId) Evergreen.V387.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V387.OneToOne.OneToOne String (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    , slackUsers : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.Slack.Id Evergreen.V387.Slack.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    , slackServers : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.Slack.Id Evergreen.V387.Slack.TeamId) (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    , slackToken : Maybe Evergreen.V387.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V387.FileStatus.FileHash Evergreen.V387.FileStatus.BackendFileData
    , privateVapidKey : Evergreen.V387.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V387.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V387.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId, Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V387.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V387.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V387.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V387.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.LocalState.LoadingDiscordChannel Evergreen.V387.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V387.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V387.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V387.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId) Evergreen.V387.Sticker.StickerData
    , discordStickers : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.Discord.Id Evergreen.V387.Discord.StickerId) (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId) Evergreen.V387.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V387.OneToOne.OneToOne Evergreen.V387.RichText.DiscordCustomEmojiIdAndName (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V387.Postmark.ApiKey
    , serverSecret : Evergreen.V387.SecretId.SecretId Evergreen.V387.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V387.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.GamePublicId) ( Evergreen.V387.DmChannelId.GuildOrFullDmId, Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V387.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V387.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V387.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.Id.ThreadRoute (Maybe Evergreen.V387.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V387.DmChannelId.DmChannelId Evergreen.V387.Id.ThreadRoute (Maybe Evergreen.V387.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V387.Id.Id Evergreen.V387.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V387.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V387.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V387.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V387.UserAgent.UserAgent
    | AdminToBackend Evergreen.V387.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V387.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V387.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V387.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V387.PersonName.PersonName Evergreen.V387.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V387.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V387.Slack.OAuthCode Evergreen.V387.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V387.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V387.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V387.Id.Id Evergreen.V387.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V387.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V387.EmailAddress.EmailAddress (Result Evergreen.V387.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V387.EmailAddress.EmailAddress (Result Evergreen.V387.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V387.EmailAddress.EmailAddress (Result Evergreen.V387.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V387.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMaybeMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Result Evergreen.V387.Discord.HttpError Evergreen.V387.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V387.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Result Evergreen.V387.Discord.HttpError Evergreen.V387.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) (Result Evergreen.V387.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) (Result Evergreen.V387.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) (Result Evergreen.V387.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) (Result Evergreen.V387.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji (Result Evergreen.V387.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji (Result Evergreen.V387.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji (Result Evergreen.V387.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji (Result Evergreen.V387.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V387.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V387.Discord.HttpError (List ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId, Maybe Evergreen.V387.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Effect.Time.Posix Evergreen.V387.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V387.Slack.CurrentUser
            , team : Evergreen.V387.Slack.Team
            , users : List Evergreen.V387.Slack.User
            , channels : List ( Evergreen.V387.Slack.Channel, List Evergreen.V387.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Result Effect.Http.Error Evergreen.V387.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Discord.UserAuth (Result Evergreen.V387.Discord.HttpError Evergreen.V387.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Result Evergreen.V387.Discord.HttpError Evergreen.V387.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
        (Result
            Evergreen.V387.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId
                , members : List (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
                }
            , List
                ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId
                , { guild : Evergreen.V387.Discord.GatewayGuild
                  , channels : List Evergreen.V387.Discord.Channel
                  , icon : Maybe Evergreen.V387.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V387.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V387.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.AttachmentId, Evergreen.V387.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V387.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.AttachmentId, Evergreen.V387.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V387.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V387.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V387.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V387.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (Result Evergreen.V387.Discord.HttpError Evergreen.V387.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Result Evergreen.V387.Discord.HttpError (List Evergreen.V387.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V387.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V387.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V387.DmChannelId.DmChannelId Evergreen.V387.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V387.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V387.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V387.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
        (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V387.Discord.HttpError
            { guild : Evergreen.V387.Discord.GatewayGuild
            , channels : List Evergreen.V387.Discord.Channel
            , icon : Maybe Evergreen.V387.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Maybe Evergreen.V387.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Result Evergreen.V387.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V387.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V387.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (List ( Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId, Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId, Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (List ( Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V387.Discord.HttpError (List Evergreen.V387.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V387.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V387.SecretId.SecretId Evergreen.V387.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V387.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V387.FileStatus.FileHash) (Result Effect.Http.Error ())
    | GotBucketFileCount Evergreen.V387.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V387.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Result Evergreen.V387.Discord.HttpError ( Evergreen.V387.Discord.Guild, List Evergreen.V387.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V387.FileStatus.FileHash Int (Maybe (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Call.CallId
