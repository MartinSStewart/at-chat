module Evergreen.V382.Types exposing (..)

import Array
import Browser
import Bytes
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V382.AiChat
import Evergreen.V382.Audio
import Evergreen.V382.BackendMsgLog
import Evergreen.V382.Call
import Evergreen.V382.ChannelDescription
import Evergreen.V382.ChannelName
import Evergreen.V382.Coord
import Evergreen.V382.CssPixels
import Evergreen.V382.CustomEmoji
import Evergreen.V382.Discord
import Evergreen.V382.DiscordAttachmentId
import Evergreen.V382.DiscordUserData
import Evergreen.V382.DmChannel
import Evergreen.V382.DmChannelId
import Evergreen.V382.Drawing
import Evergreen.V382.Editable
import Evergreen.V382.EmailAddress
import Evergreen.V382.Embed
import Evergreen.V382.Emoji
import Evergreen.V382.Encryption
import Evergreen.V382.FileStatus
import Evergreen.V382.Game
import Evergreen.V382.Go
import Evergreen.V382.GuildName
import Evergreen.V382.Id
import Evergreen.V382.IdArray
import Evergreen.V382.ImageEditor
import Evergreen.V382.ImageViewer
import Evergreen.V382.LinkedAndOtherDiscordUsers
import Evergreen.V382.Local
import Evergreen.V382.LocalState
import Evergreen.V382.Log
import Evergreen.V382.LoginForm
import Evergreen.V382.MembersAndOwner
import Evergreen.V382.Message
import Evergreen.V382.MessageInput
import Evergreen.V382.MessageView
import Evergreen.V382.MuteSettings
import Evergreen.V382.MyUi
import Evergreen.V382.NonemptyDict
import Evergreen.V382.NonemptySet
import Evergreen.V382.OneOrGreater
import Evergreen.V382.OneToOne
import Evergreen.V382.Pages.Admin
import Evergreen.V382.Pagination
import Evergreen.V382.PersonName
import Evergreen.V382.Ports
import Evergreen.V382.Postmark
import Evergreen.V382.Range
import Evergreen.V382.RecoveryLogin
import Evergreen.V382.RichText
import Evergreen.V382.Route
import Evergreen.V382.Scroll
import Evergreen.V382.SecretId
import Evergreen.V382.SessionIdHash
import Evergreen.V382.SheepGame
import Evergreen.V382.Slack
import Evergreen.V382.Sticker
import Evergreen.V382.TextEditor
import Evergreen.V382.ToBackendLog
import Evergreen.V382.Touch
import Evergreen.V382.TwoFactorAuthentication
import Evergreen.V382.Ui.Anim
import Evergreen.V382.User
import Evergreen.V382.UserAgent
import Evergreen.V382.UserColor
import Evergreen.V382.UserSession
import Evergreen.V382.WordSpellingGame
import Evergreen.V382.X25519
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
    | LoginFormMsg Evergreen.V382.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V382.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V382.Pages.Admin.Msg
    | PressedLogOut Evergreen.V382.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V382.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V382.Route.Route
    | SelectedFilesToAttach ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | PressedImportChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V382.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V382.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V382.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V382.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V382.NonemptyDict.NonemptyDict Int Evergreen.V382.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V382.NonemptyDict.NonemptyDict Int Evergreen.V382.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRoute Evergreen.V382.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V382.NonemptySet.NonemptySet (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V382.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V382.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V382.AiChat.Msg
    | GameMsg Evergreen.V382.Game.Msg
    | GoSpectatorMsg Evergreen.V382.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V382.Editable.Msg Evergreen.V382.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V382.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) (Maybe Evergreen.V382.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute )
        { fileId : Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute )
        { fileId : Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage Evergreen.V382.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V382.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V382.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V382.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V382.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V382.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V382.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | PressedDisableE2ee (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | TypedPrivateKey (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V382.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId
        , otherUserId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V382.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRoute Evergreen.V382.MessageInput.Msg
    | MessageInputMsg Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRoute Evergreen.V382.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V382.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V382.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V382.Range.Range, Evergreen.V382.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V382.Range.Range, Evergreen.V382.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V382.Call.FromJs)
    | VoiceChatMsg Evergreen.V382.Call.Msg
    | PressedChannelHeaderTab Evergreen.V382.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V382.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V382.Audio.LoadError Evergreen.V382.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V382.Id.AnyGuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V382.Id.AnyGuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) Evergreen.V382.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V382.Encryption.FromJs (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V382.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V382.UserSession.UserSession
    , currentlyViewing : Evergreen.V382.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) Evergreen.V382.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.LocalState.DiscordFrontendGuild
    , user : Evergreen.V382.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.User.FrontendUser
    , discordUsers : Evergreen.V382.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V382.SessionIdHash.SessionIdHash Evergreen.V382.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V382.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId) Evergreen.V382.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId) Evergreen.V382.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V382.Call.CallId (Evergreen.V382.NonemptyDict.NonemptyDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V382.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V382.Go.PublicGoMatchData Evergreen.V382.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V382.Route.Route
    , windowSize : Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V382.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V382.Audio.LoadError Evergreen.V382.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Encryption.EncryptedData (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.NonemptyDict.NonemptyDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Encryption.EncryptedData (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V382.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V382.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V382.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData) (List Evergreen.V382.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V382.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V382.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.ChannelName.ChannelName Evergreen.V382.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.ChannelName.ChannelName Evergreen.V382.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V382.GuildName.GuildName (Evergreen.V382.UserSession.ToBeFilledInByBackend (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V382.Id.Viewing_DiscordDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V382.UserSession.SetViewing
    | Local_SetName Evergreen.V382.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V382.Id.GuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V382.Id.GuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V382.Id.DiscordGuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V382.Id.DiscordGuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V382.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V382.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V382.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.QuestionId Evergreen.V382.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V382.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V382.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V382.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V382.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V382.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V382.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V382.NonemptySet.NonemptySet (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V382.Call.LocalChange
    | Local_Game Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Game.LocalChange
    | Local_Drawing Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Drawing.AnchorType Evergreen.V382.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V382.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V382.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V382.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V382.X25519.PublicKey (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V382.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V382.Id.Viewing_DmId (List ( Evergreen.V382.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V382.FileStatus.FileHash, Evergreen.V382.Encryption.EncryptedData (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V382.Id.Viewing_DmId (Evergreen.V382.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V382.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V382.Id.ThreadRouteWithMessage, Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V382.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V382.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V382.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V382.FileStatus.FileHash) (Evergreen.V382.Encryption.EncryptedData (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))) (Evergreen.V382.Encryption.EncryptedData String) Evergreen.V382.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V382.Id.Viewing_DmId Evergreen.V382.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V382.FileStatus.FileHash) (Evergreen.V382.Encryption.EncryptedData (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.User.FrontendUser Effect.Time.Posix Evergreen.V382.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V382.RichText.RichText (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))) Evergreen.V382.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId) Evergreen.V382.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V382.Id.DiscordGuildOrDmId Evergreen.V382.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V382.RichText.RichText (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))) Evergreen.V382.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId) Evergreen.V382.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.ChannelName.ChannelName Evergreen.V382.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.ChannelName.ChannelName Evergreen.V382.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.User.FrontendUser
    | Server_MemberLeft (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V382.LocalState.JoinGuildError
            { guildId : Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId
            , guild : Evergreen.V382.LocalState.FrontendGuild
            , owner : Evergreen.V382.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V382.RichText.RichText (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V382.RichText.RichText (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V382.Id.Viewing_DiscordDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V382.RichText.RichText (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Maybe Evergreen.V382.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Maybe Evergreen.V382.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V382.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V382.SessionIdHash.SessionIdHash Evergreen.V382.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V382.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V382.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V382.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V382.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V382.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Bool Evergreen.V382.ChannelName.ChannelName (Evergreen.V382.Discord.OptionalData (Maybe String)) (List Evergreen.V382.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
        (Evergreen.V382.NonemptyDict.NonemptyDict
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) Evergreen.V382.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Maybe (Evergreen.V382.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V382.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V382.Log.Log
    | Server_BackupGenerated Evergreen.V382.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V382.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V382.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V382.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V382.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (Evergreen.V382.Discord.OptionalData (Maybe String)) (Evergreen.V382.Discord.OptionalData (Maybe String)) (List Evergreen.V382.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.GuildName.GuildName (Maybe Evergreen.V382.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId) Evergreen.V382.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId) Evergreen.V382.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
        (Evergreen.V382.MembersAndOwner.MembersAndOwner
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.PersonName.PersonName Evergreen.V382.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId) Evergreen.V382.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId) Evergreen.V382.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V382.Call.ServerChange
    | Server_Game (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Game.LocalChange
    | Server_Drawing (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Drawing.AnchorType Evergreen.V382.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V382.Id.Viewing_DmId ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V382.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V382.Id.Viewing_DmId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | Server_E2eeAccepted Evergreen.V382.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.User.FrontendUser Effect.Time.Posix Evergreen.V382.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V382.FileStatus.FileHash) (Evergreen.V382.Encryption.EncryptedData (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))) Evergreen.V382.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.Viewing_DmId Evergreen.V382.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V382.FileStatus.FileHash) (Evergreen.V382.Encryption.EncryptedData (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V382.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V382.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V382.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V382.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V382.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V382.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V382.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V382.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V382.Id.AnyGuildOrDmId Evergreen.V382.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V382.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels) (Maybe Evergreen.V382.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V382.SheepGame.Input (Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels) (Maybe Evergreen.V382.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V382.Id.GuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V382.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V382.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V382.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , threadRoute : Evergreen.V382.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V382.Encryption.BytesHash
    , id : Evergreen.V382.Id.Viewing_DmId
    , senderId : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , threadRoute : Evergreen.V382.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V382.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V382.Id.Viewing_DmId
    , messages : List Evergreen.V382.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V382.Id.Viewing_DmId
    , messages : List ( Evergreen.V382.Id.ThreadRouteWithMessage, Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V382.Id.Viewing_DmId
    , threadRoute : Evergreen.V382.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute )
    , fileId : Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V382.Id.Id Evergreen.V382.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V382.Id.Id Evergreen.V382.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V382.Id.Id Evergreen.V382.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V382.Id.Id Evergreen.V382.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V382.Id.Id Evergreen.V382.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V382.Local.Local LocalMsg Evergreen.V382.LocalState.LocalState
    , admin : Evergreen.V382.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V382.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V382.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V382.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V382.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V382.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.ThreadRoute ) (Evergreen.V382.NonemptyDict.NonemptyDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V382.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V382.Scroll.ScrollPosition
    , textEditor : Evergreen.V382.TextEditor.Model
    , profilePictureEditor : Evergreen.V382.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId, Evergreen.V382.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V382.Emoji.Model
    , voiceChat : Evergreen.V382.Call.Model
    , games : SeqDict.SeqDict Evergreen.V382.Id.GuildOrDmId Evergreen.V382.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V382.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V382.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V382.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V382.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V382.Range.Range
                , direction : Evergreen.V382.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V382.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V382.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V382.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V382.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V382.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V382.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V382.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V382.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V382.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V382.MyUi.LastCopy
    , drag : Evergreen.V382.Touch.Drag
    , dragPrevious : Evergreen.V382.Touch.Drag
    , aiChatModel : Evergreen.V382.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V382.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V382.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V382.Audio.LoadError Evergreen.V382.Audio.Source
    , startupData : Evergreen.V382.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V382.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V382.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V382.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V382.FileStatus.FileHash
    , metadata : Maybe Evergreen.V382.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId, Evergreen.V382.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId, Evergreen.V382.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V382.DmChannelId.DmChannelId, Evergreen.V382.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId, Evergreen.V382.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId, Evergreen.V382.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId, Evergreen.V382.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V382.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V382.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V382.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V382.NonemptyDict.NonemptyDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V382.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V382.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V382.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V382.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V382.DmChannelId.DmChannelId Evergreen.V382.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) Evergreen.V382.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.Slack.Id Evergreen.V382.Slack.ChannelId) Evergreen.V382.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V382.OneToOne.OneToOne String (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    , slackUsers : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.Slack.Id Evergreen.V382.Slack.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    , slackServers : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.Slack.Id Evergreen.V382.Slack.TeamId) (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    , slackToken : Maybe Evergreen.V382.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V382.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V382.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V382.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V382.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId, Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V382.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V382.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V382.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V382.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.LocalState.LoadingDiscordChannel Evergreen.V382.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V382.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V382.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId) Evergreen.V382.Sticker.StickerData
    , discordStickers : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.Discord.Id Evergreen.V382.Discord.StickerId) (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId) Evergreen.V382.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V382.OneToOne.OneToOne Evergreen.V382.RichText.DiscordCustomEmojiIdAndName (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V382.Postmark.ApiKey
    , serverSecret : Evergreen.V382.SecretId.SecretId Evergreen.V382.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V382.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.GamePublicId) ( Evergreen.V382.DmChannelId.GuildOrFullDmId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V382.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V382.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V382.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.Id.ThreadRoute (Maybe Evergreen.V382.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V382.DmChannelId.DmChannelId Evergreen.V382.Id.ThreadRoute (Maybe Evergreen.V382.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V382.Id.Id Evergreen.V382.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V382.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V382.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V382.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V382.UserAgent.UserAgent
    | AdminToBackend Evergreen.V382.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V382.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V382.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V382.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V382.PersonName.PersonName Evergreen.V382.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V382.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V382.Slack.OAuthCode Evergreen.V382.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V382.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V382.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V382.Id.Id Evergreen.V382.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V382.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V382.EmailAddress.EmailAddress (Result Evergreen.V382.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V382.EmailAddress.EmailAddress (Result Evergreen.V382.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V382.EmailAddress.EmailAddress (Result Evergreen.V382.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V382.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMaybeMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Result Evergreen.V382.Discord.HttpError Evergreen.V382.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V382.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Result Evergreen.V382.Discord.HttpError Evergreen.V382.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) (Result Evergreen.V382.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) (Result Evergreen.V382.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) (Result Evergreen.V382.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) (Result Evergreen.V382.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji (Result Evergreen.V382.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji (Result Evergreen.V382.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji (Result Evergreen.V382.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji (Result Evergreen.V382.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V382.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V382.Discord.HttpError (List ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId, Maybe Evergreen.V382.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Effect.Time.Posix Evergreen.V382.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V382.Slack.CurrentUser
            , team : Evergreen.V382.Slack.Team
            , users : List Evergreen.V382.Slack.User
            , channels : List ( Evergreen.V382.Slack.Channel, List Evergreen.V382.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Result Effect.Http.Error Evergreen.V382.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Discord.UserAuth (Result Evergreen.V382.Discord.HttpError Evergreen.V382.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Result Evergreen.V382.Discord.HttpError Evergreen.V382.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
        (Result
            Evergreen.V382.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId
                , members : List (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
                }
            , List
                ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId
                , { guild : Evergreen.V382.Discord.GatewayGuild
                  , channels : List Evergreen.V382.Discord.Channel
                  , icon : Maybe Evergreen.V382.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V382.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V382.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.AttachmentId, Evergreen.V382.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V382.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.AttachmentId, Evergreen.V382.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V382.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V382.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V382.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V382.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (Result Evergreen.V382.Discord.HttpError Evergreen.V382.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Result Evergreen.V382.Discord.HttpError (List Evergreen.V382.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V382.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V382.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V382.DmChannelId.DmChannelId Evergreen.V382.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V382.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V382.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V382.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
        (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V382.Discord.HttpError
            { guild : Evergreen.V382.Discord.GatewayGuild
            , channels : List Evergreen.V382.Discord.Channel
            , icon : Maybe Evergreen.V382.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Maybe Evergreen.V382.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Result Evergreen.V382.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V382.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V382.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (List ( Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId, Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId, Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (List ( Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V382.Discord.HttpError (List Evergreen.V382.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V382.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V382.SecretId.SecretId Evergreen.V382.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V382.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Result Evergreen.V382.Discord.HttpError ( Evergreen.V382.Discord.Guild, List Evergreen.V382.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V382.FileStatus.FileHash Int (Maybe (Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Call.CallId
