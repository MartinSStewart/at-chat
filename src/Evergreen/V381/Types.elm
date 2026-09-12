module Evergreen.V381.Types exposing (..)

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
import Evergreen.V381.AiChat
import Evergreen.V381.Audio
import Evergreen.V381.BackendMsgLog
import Evergreen.V381.Call
import Evergreen.V381.ChannelDescription
import Evergreen.V381.ChannelName
import Evergreen.V381.Coord
import Evergreen.V381.CssPixels
import Evergreen.V381.CustomEmoji
import Evergreen.V381.Discord
import Evergreen.V381.DiscordAttachmentId
import Evergreen.V381.DiscordUserData
import Evergreen.V381.DmChannel
import Evergreen.V381.DmChannelId
import Evergreen.V381.Drawing
import Evergreen.V381.Editable
import Evergreen.V381.EmailAddress
import Evergreen.V381.Embed
import Evergreen.V381.Emoji
import Evergreen.V381.Encryption
import Evergreen.V381.FileStatus
import Evergreen.V381.Game
import Evergreen.V381.Go
import Evergreen.V381.GuildName
import Evergreen.V381.Id
import Evergreen.V381.IdArray
import Evergreen.V381.ImageEditor
import Evergreen.V381.ImageViewer
import Evergreen.V381.LinkedAndOtherDiscordUsers
import Evergreen.V381.Local
import Evergreen.V381.LocalState
import Evergreen.V381.Log
import Evergreen.V381.LoginForm
import Evergreen.V381.MembersAndOwner
import Evergreen.V381.Message
import Evergreen.V381.MessageInput
import Evergreen.V381.MessageView
import Evergreen.V381.MuteSettings
import Evergreen.V381.MyUi
import Evergreen.V381.NonemptyDict
import Evergreen.V381.NonemptySet
import Evergreen.V381.OneOrGreater
import Evergreen.V381.OneToOne
import Evergreen.V381.Pages.Admin
import Evergreen.V381.Pagination
import Evergreen.V381.PersonName
import Evergreen.V381.Ports
import Evergreen.V381.Postmark
import Evergreen.V381.Range
import Evergreen.V381.RecoveryLogin
import Evergreen.V381.RichText
import Evergreen.V381.Route
import Evergreen.V381.Scroll
import Evergreen.V381.SecretId
import Evergreen.V381.SessionIdHash
import Evergreen.V381.SheepGame
import Evergreen.V381.Slack
import Evergreen.V381.Sticker
import Evergreen.V381.TextEditor
import Evergreen.V381.ToBackendLog
import Evergreen.V381.Touch
import Evergreen.V381.TwoFactorAuthentication
import Evergreen.V381.Ui.Anim
import Evergreen.V381.User
import Evergreen.V381.UserAgent
import Evergreen.V381.UserColor
import Evergreen.V381.UserSession
import Evergreen.V381.WordSpellingGame
import Evergreen.V381.X25519
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
    | LoginFormMsg Evergreen.V381.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V381.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V381.Pages.Admin.Msg
    | PressedLogOut Evergreen.V381.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V381.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V381.Route.Route
    | SelectedFilesToAttach ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | PressedImportChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V381.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V381.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V381.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V381.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V381.NonemptyDict.NonemptyDict Int Evergreen.V381.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V381.NonemptyDict.NonemptyDict Int Evergreen.V381.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRoute Evergreen.V381.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V381.NonemptySet.NonemptySet (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V381.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V381.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V381.AiChat.Msg
    | GameMsg Evergreen.V381.Game.Msg
    | GoSpectatorMsg Evergreen.V381.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V381.Editable.Msg Evergreen.V381.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V381.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) (Maybe Evergreen.V381.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute )
        { fileId : Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute )
        { fileId : Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage Evergreen.V381.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V381.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V381.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V381.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V381.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V381.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V381.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | PressedDisableE2ee (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | TypedPrivateKey (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V381.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId
        , otherUserId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V381.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRoute Evergreen.V381.MessageInput.Msg
    | MessageInputMsg Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRoute Evergreen.V381.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V381.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V381.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V381.Range.Range, Evergreen.V381.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V381.Range.Range, Evergreen.V381.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V381.Call.FromJs)
    | VoiceChatMsg Evergreen.V381.Call.Msg
    | PressedChannelHeaderTab Evergreen.V381.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V381.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V381.Audio.LoadError Evergreen.V381.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V381.Id.AnyGuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V381.Id.AnyGuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) Evergreen.V381.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V381.Encryption.FromJs (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V381.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V381.UserSession.UserSession
    , currentlyViewing : Evergreen.V381.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) Evergreen.V381.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.LocalState.DiscordFrontendGuild
    , user : Evergreen.V381.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.User.FrontendUser
    , discordUsers : Evergreen.V381.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V381.SessionIdHash.SessionIdHash Evergreen.V381.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V381.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId) Evergreen.V381.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId) Evergreen.V381.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V381.Call.CallId (Evergreen.V381.NonemptyDict.NonemptyDict ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V381.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V381.Go.PublicGoMatchData Evergreen.V381.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V381.Route.Route
    , windowSize : Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V381.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V381.Audio.LoadError Evergreen.V381.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Encryption.EncryptedData (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.NonemptyDict.NonemptyDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) (Evergreen.V381.Encryption.EncryptedData (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V381.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V381.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V381.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileData) (List Evergreen.V381.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V381.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V381.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.ChannelName.ChannelName Evergreen.V381.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.ChannelName.ChannelName Evergreen.V381.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V381.GuildName.GuildName (Evergreen.V381.UserSession.ToBeFilledInByBackend (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V381.Id.Viewing_DiscordDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V381.UserSession.SetViewing
    | Local_SetName Evergreen.V381.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V381.Id.GuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V381.Id.GuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) (Evergreen.V381.Message.Message Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V381.Id.DiscordGuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V381.Id.DiscordGuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) (Evergreen.V381.Message.Message Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V381.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V381.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V381.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.QuestionId Evergreen.V381.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V381.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V381.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V381.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V381.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V381.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V381.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V381.NonemptySet.NonemptySet (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V381.Call.LocalChange
    | Local_Game Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Game.LocalChange
    | Local_Drawing Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Drawing.AnchorType Evergreen.V381.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V381.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V381.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V381.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V381.X25519.PublicKey (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V381.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V381.Id.Viewing_DmId (List ( Evergreen.V381.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V381.FileStatus.FileHash, Evergreen.V381.Encryption.EncryptedData (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V381.Id.Viewing_DmId (Evergreen.V381.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V381.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V381.Id.ThreadRouteWithMessage, Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V381.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V381.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V381.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V381.FileStatus.FileHash) (Evergreen.V381.Encryption.EncryptedData (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))) (Evergreen.V381.Encryption.EncryptedData String) Evergreen.V381.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V381.Id.Viewing_DmId Evergreen.V381.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V381.FileStatus.FileHash) (Evergreen.V381.Encryption.EncryptedData (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.User.FrontendUser Effect.Time.Posix Evergreen.V381.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V381.RichText.RichText (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))) Evergreen.V381.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId) Evergreen.V381.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V381.Id.DiscordGuildOrDmId Evergreen.V381.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V381.RichText.RichText (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))) Evergreen.V381.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId) Evergreen.V381.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.ChannelName.ChannelName Evergreen.V381.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.ChannelName.ChannelName Evergreen.V381.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.User.FrontendUser
    | Server_MemberLeft (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V381.LocalState.JoinGuildError
            { guildId : Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId
            , guild : Evergreen.V381.LocalState.FrontendGuild
            , owner : Evergreen.V381.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V381.RichText.RichText (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))) (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V381.RichText.RichText (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V381.Id.Viewing_DiscordDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V381.RichText.RichText (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Maybe Evergreen.V381.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Maybe Evergreen.V381.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V381.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V381.SessionIdHash.SessionIdHash Evergreen.V381.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V381.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V381.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V381.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V381.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V381.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Bool Evergreen.V381.ChannelName.ChannelName (Evergreen.V381.Discord.OptionalData (Maybe String)) (List Evergreen.V381.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
        (Evergreen.V381.NonemptyDict.NonemptyDict
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) Evergreen.V381.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Maybe (Evergreen.V381.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V381.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V381.Log.Log
    | Server_BackupGenerated Evergreen.V381.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V381.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V381.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V381.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V381.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (Evergreen.V381.Discord.OptionalData (Maybe String)) (Evergreen.V381.Discord.OptionalData (Maybe String)) (List Evergreen.V381.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.GuildName.GuildName (Maybe Evergreen.V381.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId) Evergreen.V381.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId) Evergreen.V381.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
        (Evergreen.V381.MembersAndOwner.MembersAndOwner
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.PersonName.PersonName Evergreen.V381.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId) Evergreen.V381.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId) Evergreen.V381.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V381.Call.ServerChange
    | Server_Game (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Game.LocalChange
    | Server_Drawing (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Drawing.AnchorType Evergreen.V381.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V381.Id.Viewing_DmId ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Evergreen.V381.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V381.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V381.Id.Viewing_DmId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | Server_E2eeAccepted Evergreen.V381.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.User.FrontendUser Effect.Time.Posix Evergreen.V381.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V381.FileStatus.FileHash) (Evergreen.V381.Encryption.EncryptedData (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))) Evergreen.V381.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.Viewing_DmId Evergreen.V381.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V381.FileStatus.FileHash) (Evergreen.V381.Encryption.EncryptedData (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V381.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V381.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V381.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V381.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V381.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V381.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V381.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V381.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V381.Id.AnyGuildOrDmId Evergreen.V381.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V381.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels) (Maybe Evergreen.V381.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V381.SheepGame.Input (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels) (Maybe Evergreen.V381.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V381.Id.GuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId) (Evergreen.V381.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V381.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V381.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V381.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , threadRoute : Evergreen.V381.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V381.Encryption.BytesHash
    , id : Evergreen.V381.Id.Viewing_DmId
    , senderId : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , threadRoute : Evergreen.V381.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V381.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V381.Id.Viewing_DmId
    , messages : List Evergreen.V381.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V381.Id.Viewing_DmId
    , messages : List ( Evergreen.V381.Id.ThreadRouteWithMessage, Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V381.Id.Viewing_DmId
    , threadRoute : Evergreen.V381.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute )
    , fileId : Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V381.Id.Id Evergreen.V381.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V381.Id.Id Evergreen.V381.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V381.Id.Id Evergreen.V381.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V381.Id.Id Evergreen.V381.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V381.Id.Id Evergreen.V381.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V381.Local.Local LocalMsg Evergreen.V381.LocalState.LocalState
    , admin : Evergreen.V381.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId, Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V381.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V381.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V381.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V381.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V381.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.ThreadRoute ) (Evergreen.V381.NonemptyDict.NonemptyDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V381.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V381.Scroll.ScrollPosition
    , textEditor : Evergreen.V381.TextEditor.Model
    , profilePictureEditor : Evergreen.V381.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId, Evergreen.V381.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V381.Emoji.Model
    , voiceChat : Evergreen.V381.Call.Model
    , games : SeqDict.SeqDict Evergreen.V381.Id.GuildOrDmId Evergreen.V381.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V381.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V381.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V381.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V381.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V381.Range.Range
                , direction : Evergreen.V381.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V381.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V381.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V381.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V381.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V381.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V381.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V381.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V381.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V381.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V381.MyUi.LastCopy
    , drag : Evergreen.V381.Touch.Drag
    , dragPrevious : Evergreen.V381.Touch.Drag
    , aiChatModel : Evergreen.V381.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V381.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V381.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V381.Audio.LoadError Evergreen.V381.Audio.Source
    , startupData : Evergreen.V381.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V381.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V381.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V381.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V381.FileStatus.FileHash
    , metadata : Maybe Evergreen.V381.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId, Evergreen.V381.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId, Evergreen.V381.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V381.DmChannelId.DmChannelId, Evergreen.V381.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId, Evergreen.V381.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId, Evergreen.V381.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId, Evergreen.V381.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V381.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V381.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V381.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V381.NonemptyDict.NonemptyDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V381.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V381.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V381.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V381.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V381.DmChannelId.DmChannelId Evergreen.V381.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) Evergreen.V381.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.Slack.Id Evergreen.V381.Slack.ChannelId) Evergreen.V381.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V381.OneToOne.OneToOne String (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    , slackUsers : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.Slack.Id Evergreen.V381.Slack.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    , slackServers : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.Slack.Id Evergreen.V381.Slack.TeamId) (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    , slackToken : Maybe Evergreen.V381.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V381.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V381.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V381.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V381.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId, Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V381.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V381.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V381.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V381.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.LocalState.LoadingDiscordChannel Evergreen.V381.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V381.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V381.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId) Evergreen.V381.Sticker.StickerData
    , discordStickers : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.Discord.Id Evergreen.V381.Discord.StickerId) (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId) Evergreen.V381.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V381.OneToOne.OneToOne Evergreen.V381.RichText.DiscordCustomEmojiIdAndName (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V381.Postmark.ApiKey
    , serverSecret : Evergreen.V381.SecretId.SecretId Evergreen.V381.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V381.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.GamePublicId) ( Evergreen.V381.DmChannelId.GuildOrFullDmId, Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V381.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V381.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V381.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.Id.ThreadRoute (Maybe Evergreen.V381.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V381.DmChannelId.DmChannelId Evergreen.V381.Id.ThreadRoute (Maybe Evergreen.V381.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V381.Id.Id Evergreen.V381.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V381.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V381.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V381.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V381.UserAgent.UserAgent
    | AdminToBackend Evergreen.V381.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V381.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V381.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V381.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V381.PersonName.PersonName Evergreen.V381.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V381.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V381.Slack.OAuthCode Evergreen.V381.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V381.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V381.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V381.Id.Id Evergreen.V381.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V381.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V381.EmailAddress.EmailAddress (Result Evergreen.V381.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V381.EmailAddress.EmailAddress (Result Evergreen.V381.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V381.EmailAddress.EmailAddress (Result Evergreen.V381.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V381.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMaybeMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Result Evergreen.V381.Discord.HttpError Evergreen.V381.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V381.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Result Evergreen.V381.Discord.HttpError Evergreen.V381.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) (Result Evergreen.V381.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) (Result Evergreen.V381.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) (Result Evergreen.V381.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) (Result Evergreen.V381.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji (Result Evergreen.V381.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji (Result Evergreen.V381.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji (Result Evergreen.V381.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji (Result Evergreen.V381.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V381.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V381.Discord.HttpError (List ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId, Maybe Evergreen.V381.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Effect.Time.Posix Evergreen.V381.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V381.Slack.CurrentUser
            , team : Evergreen.V381.Slack.Team
            , users : List Evergreen.V381.Slack.User
            , channels : List ( Evergreen.V381.Slack.Channel, List Evergreen.V381.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Result Effect.Http.Error Evergreen.V381.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Discord.UserAuth (Result Evergreen.V381.Discord.HttpError Evergreen.V381.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Result Evergreen.V381.Discord.HttpError Evergreen.V381.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
        (Result
            Evergreen.V381.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId
                , members : List (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
                }
            , List
                ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId
                , { guild : Evergreen.V381.Discord.GatewayGuild
                  , channels : List Evergreen.V381.Discord.Channel
                  , icon : Maybe Evergreen.V381.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V381.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V381.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.AttachmentId, Evergreen.V381.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V381.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.AttachmentId, Evergreen.V381.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V381.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V381.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V381.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V381.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (Result Evergreen.V381.Discord.HttpError Evergreen.V381.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Result Evergreen.V381.Discord.HttpError (List Evergreen.V381.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V381.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V381.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V381.DmChannelId.DmChannelId Evergreen.V381.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V381.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V381.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V381.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
        (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V381.Discord.HttpError
            { guild : Evergreen.V381.Discord.GatewayGuild
            , channels : List Evergreen.V381.Discord.Channel
            , icon : Maybe Evergreen.V381.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Maybe Evergreen.V381.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Result Evergreen.V381.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V381.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V381.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (List ( Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId, Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId, Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (List ( Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V381.Discord.HttpError (List Evergreen.V381.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V381.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V381.SecretId.SecretId Evergreen.V381.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V381.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Result Evergreen.V381.Discord.HttpError ( Evergreen.V381.Discord.Guild, List Evergreen.V381.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V381.FileStatus.FileHash Int (Maybe (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Call.CallId
