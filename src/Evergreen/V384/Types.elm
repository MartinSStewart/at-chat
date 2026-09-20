module Evergreen.V384.Types exposing (..)

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
import Evergreen.V384.AiChat
import Evergreen.V384.Audio
import Evergreen.V384.BackendMsgLog
import Evergreen.V384.Call
import Evergreen.V384.ChannelDescription
import Evergreen.V384.ChannelName
import Evergreen.V384.Coord
import Evergreen.V384.CssPixels
import Evergreen.V384.CustomEmoji
import Evergreen.V384.Discord
import Evergreen.V384.DiscordAttachmentId
import Evergreen.V384.DiscordUserData
import Evergreen.V384.DmChannel
import Evergreen.V384.DmChannelId
import Evergreen.V384.Drawing
import Evergreen.V384.Editable
import Evergreen.V384.EmailAddress
import Evergreen.V384.Embed
import Evergreen.V384.Emoji
import Evergreen.V384.Encryption
import Evergreen.V384.FileStatus
import Evergreen.V384.Game
import Evergreen.V384.Go
import Evergreen.V384.GuildName
import Evergreen.V384.Id
import Evergreen.V384.IdArray
import Evergreen.V384.ImageEditor
import Evergreen.V384.ImageViewer
import Evergreen.V384.LinkedAndOtherDiscordUsers
import Evergreen.V384.Local
import Evergreen.V384.LocalState
import Evergreen.V384.Log
import Evergreen.V384.LoginForm
import Evergreen.V384.MembersAndOwner
import Evergreen.V384.Message
import Evergreen.V384.MessageInput
import Evergreen.V384.MessageView
import Evergreen.V384.MuteSettings
import Evergreen.V384.MyUi
import Evergreen.V384.NonemptyDict
import Evergreen.V384.NonemptySet
import Evergreen.V384.OneOrGreater
import Evergreen.V384.OneToOne
import Evergreen.V384.Pages.Admin
import Evergreen.V384.Pagination
import Evergreen.V384.PersonName
import Evergreen.V384.Ports
import Evergreen.V384.Postmark
import Evergreen.V384.Range
import Evergreen.V384.RecoveryLogin
import Evergreen.V384.RichText
import Evergreen.V384.Route
import Evergreen.V384.Scroll
import Evergreen.V384.SecretId
import Evergreen.V384.SessionIdHash
import Evergreen.V384.SheepGame
import Evergreen.V384.Slack
import Evergreen.V384.Sticker
import Evergreen.V384.TextEditor
import Evergreen.V384.ToBackendLog
import Evergreen.V384.Touch
import Evergreen.V384.TwoFactorAuthentication
import Evergreen.V384.Ui.Anim
import Evergreen.V384.User
import Evergreen.V384.UserAgent
import Evergreen.V384.UserColor
import Evergreen.V384.UserSession
import Evergreen.V384.WordSpellingGame
import Evergreen.V384.X25519
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
    | LoginFormMsg Evergreen.V384.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V384.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V384.Pages.Admin.Msg
    | PressedLogOut Evergreen.V384.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V384.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V384.Route.Route
    | SelectedFilesToAttach ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | PressedImportChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V384.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V384.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V384.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V384.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V384.NonemptyDict.NonemptyDict Int Evergreen.V384.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V384.NonemptyDict.NonemptyDict Int Evergreen.V384.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRoute Evergreen.V384.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V384.NonemptySet.NonemptySet (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V384.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V384.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V384.AiChat.Msg
    | GameMsg Evergreen.V384.Game.Msg
    | GoSpectatorMsg Evergreen.V384.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V384.Editable.Msg Evergreen.V384.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V384.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) (Maybe Evergreen.V384.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute )
        { fileId : Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute )
        { fileId : Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage Evergreen.V384.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V384.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V384.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V384.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V384.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V384.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V384.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | PressedDisableE2ee (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | TypedPrivateKey (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V384.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId
        , otherUserId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V384.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRoute Evergreen.V384.MessageInput.Msg
    | MessageInputMsg Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRoute Evergreen.V384.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V384.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V384.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V384.Range.Range, Evergreen.V384.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V384.Range.Range, Evergreen.V384.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V384.Call.FromJs)
    | VoiceChatMsg Evergreen.V384.Call.Msg
    | PressedChannelHeaderTab Evergreen.V384.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V384.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V384.Audio.LoadError Evergreen.V384.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V384.Id.AnyGuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V384.Id.AnyGuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) Evergreen.V384.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V384.Encryption.FromJs (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V384.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V384.UserSession.UserSession
    , currentlyViewing : Evergreen.V384.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) Evergreen.V384.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.LocalState.DiscordFrontendGuild
    , user : Evergreen.V384.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.User.FrontendUser
    , discordUsers : Evergreen.V384.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V384.SessionIdHash.SessionIdHash Evergreen.V384.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V384.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId) Evergreen.V384.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId) Evergreen.V384.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V384.Call.CallId (Evergreen.V384.NonemptyDict.NonemptyDict ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V384.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V384.Go.PublicGoMatchData Evergreen.V384.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V384.Route.Route
    , windowSize : Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V384.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V384.Audio.LoadError Evergreen.V384.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Encryption.EncryptedData (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.NonemptyDict.NonemptyDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) (Evergreen.V384.Encryption.EncryptedData (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V384.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V384.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V384.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileData) (List Evergreen.V384.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V384.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V384.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.ChannelName.ChannelName Evergreen.V384.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.ChannelName.ChannelName Evergreen.V384.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V384.GuildName.GuildName (Evergreen.V384.UserSession.ToBeFilledInByBackend (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V384.Id.Viewing_DiscordDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V384.UserSession.SetViewing
    | Local_SetName Evergreen.V384.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V384.Id.GuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V384.Id.GuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) (Evergreen.V384.Message.Message Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V384.Id.DiscordGuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V384.Id.DiscordGuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) (Evergreen.V384.Message.Message Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V384.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V384.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V384.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.QuestionId Evergreen.V384.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V384.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V384.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V384.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V384.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V384.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V384.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V384.NonemptySet.NonemptySet (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V384.Call.LocalChange
    | Local_Game Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Game.LocalChange
    | Local_Drawing Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Drawing.AnchorType Evergreen.V384.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V384.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V384.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V384.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V384.X25519.PublicKey (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V384.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V384.Id.Viewing_DmId (List ( Evergreen.V384.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V384.FileStatus.FileHash, Evergreen.V384.Encryption.EncryptedData (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V384.Id.Viewing_DmId (Evergreen.V384.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V384.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V384.Id.ThreadRouteWithMessage, Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V384.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V384.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V384.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V384.FileStatus.FileHash) (Evergreen.V384.Encryption.EncryptedData (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))) (Evergreen.V384.Encryption.EncryptedData String) Evergreen.V384.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V384.Id.Viewing_DmId Evergreen.V384.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V384.FileStatus.FileHash) (Evergreen.V384.Encryption.EncryptedData (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.User.FrontendUser Effect.Time.Posix Evergreen.V384.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V384.RichText.RichText (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))) Evergreen.V384.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId) Evergreen.V384.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V384.Id.DiscordGuildOrDmId Evergreen.V384.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V384.RichText.RichText (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))) Evergreen.V384.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId) Evergreen.V384.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.ChannelName.ChannelName Evergreen.V384.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.ChannelName.ChannelName Evergreen.V384.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.User.FrontendUser
    | Server_MemberLeft (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V384.LocalState.JoinGuildError
            { guildId : Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId
            , guild : Evergreen.V384.LocalState.FrontendGuild
            , owner : Evergreen.V384.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V384.RichText.RichText (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))) (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V384.RichText.RichText (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V384.Id.Viewing_DiscordDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V384.RichText.RichText (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Maybe Evergreen.V384.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Maybe Evergreen.V384.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V384.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V384.SessionIdHash.SessionIdHash Evergreen.V384.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V384.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V384.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V384.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V384.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V384.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Bool Evergreen.V384.ChannelName.ChannelName (Evergreen.V384.Discord.OptionalData (Maybe String)) (List Evergreen.V384.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
        (Evergreen.V384.NonemptyDict.NonemptyDict
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) Evergreen.V384.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Maybe (Evergreen.V384.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V384.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V384.Log.Log
    | Server_BackupGenerated Evergreen.V384.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V384.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V384.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V384.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V384.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (Evergreen.V384.Discord.OptionalData (Maybe String)) (Evergreen.V384.Discord.OptionalData (Maybe String)) (List Evergreen.V384.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.GuildName.GuildName (Maybe Evergreen.V384.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId) Evergreen.V384.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId) Evergreen.V384.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
        (Evergreen.V384.MembersAndOwner.MembersAndOwner
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.PersonName.PersonName Evergreen.V384.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId) Evergreen.V384.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId) Evergreen.V384.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V384.Call.ServerChange
    | Server_Game (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Game.LocalChange
    | Server_Drawing (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Drawing.AnchorType Evergreen.V384.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V384.Id.Viewing_DmId ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Evergreen.V384.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V384.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V384.Id.Viewing_DmId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | Server_E2eeAccepted Evergreen.V384.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.User.FrontendUser Effect.Time.Posix Evergreen.V384.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V384.FileStatus.FileHash) (Evergreen.V384.Encryption.EncryptedData (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))) Evergreen.V384.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.Viewing_DmId Evergreen.V384.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V384.FileStatus.FileHash) (Evergreen.V384.Encryption.EncryptedData (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V384.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V384.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V384.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V384.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V384.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V384.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V384.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V384.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V384.Id.AnyGuildOrDmId Evergreen.V384.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V384.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels) (Maybe Evergreen.V384.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V384.SheepGame.Input (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels) (Maybe Evergreen.V384.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V384.Id.GuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId) (Evergreen.V384.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V384.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V384.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V384.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , threadRoute : Evergreen.V384.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V384.Encryption.BytesHash
    , id : Evergreen.V384.Id.Viewing_DmId
    , senderId : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , threadRoute : Evergreen.V384.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V384.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V384.Id.Viewing_DmId
    , messages : List Evergreen.V384.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V384.Id.Viewing_DmId
    , messages : List ( Evergreen.V384.Id.ThreadRouteWithMessage, Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V384.Id.Viewing_DmId
    , threadRoute : Evergreen.V384.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute )
    , fileId : Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V384.Id.Id Evergreen.V384.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V384.Id.Id Evergreen.V384.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V384.Id.Id Evergreen.V384.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V384.Id.Id Evergreen.V384.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V384.Id.Id Evergreen.V384.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V384.Local.Local LocalMsg Evergreen.V384.LocalState.LocalState
    , admin : Evergreen.V384.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId, Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V384.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V384.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V384.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V384.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V384.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.ThreadRoute ) (Evergreen.V384.NonemptyDict.NonemptyDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V384.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V384.Scroll.ScrollPosition
    , textEditor : Evergreen.V384.TextEditor.Model
    , profilePictureEditor : Evergreen.V384.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId, Evergreen.V384.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V384.Emoji.Model
    , voiceChat : Evergreen.V384.Call.Model
    , games : SeqDict.SeqDict Evergreen.V384.Id.GuildOrDmId Evergreen.V384.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V384.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V384.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V384.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V384.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V384.Range.Range
                , direction : Evergreen.V384.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V384.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V384.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V384.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V384.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V384.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V384.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V384.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V384.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V384.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V384.MyUi.LastCopy
    , drag : Evergreen.V384.Touch.Drag
    , dragPrevious : Evergreen.V384.Touch.Drag
    , aiChatModel : Evergreen.V384.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V384.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V384.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V384.Audio.LoadError Evergreen.V384.Audio.Source
    , startupData : Evergreen.V384.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V384.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V384.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V384.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V384.FileStatus.FileHash
    , metadata : Maybe Evergreen.V384.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId, Evergreen.V384.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId, Evergreen.V384.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V384.DmChannelId.DmChannelId, Evergreen.V384.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId, Evergreen.V384.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId, Evergreen.V384.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId, Evergreen.V384.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V384.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V384.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V384.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V384.NonemptyDict.NonemptyDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V384.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V384.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V384.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V384.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V384.DmChannelId.DmChannelId Evergreen.V384.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) Evergreen.V384.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.Slack.Id Evergreen.V384.Slack.ChannelId) Evergreen.V384.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V384.OneToOne.OneToOne String (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    , slackUsers : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.Slack.Id Evergreen.V384.Slack.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    , slackServers : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.Slack.Id Evergreen.V384.Slack.TeamId) (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    , slackToken : Maybe Evergreen.V384.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V384.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V384.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V384.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V384.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId, Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V384.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V384.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V384.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V384.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.LocalState.LoadingDiscordChannel Evergreen.V384.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V384.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V384.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId) Evergreen.V384.Sticker.StickerData
    , discordStickers : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.Discord.Id Evergreen.V384.Discord.StickerId) (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId) Evergreen.V384.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V384.OneToOne.OneToOne Evergreen.V384.RichText.DiscordCustomEmojiIdAndName (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V384.Postmark.ApiKey
    , serverSecret : Evergreen.V384.SecretId.SecretId Evergreen.V384.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V384.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.GamePublicId) ( Evergreen.V384.DmChannelId.GuildOrFullDmId, Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V384.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V384.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V384.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.Id.ThreadRoute (Maybe Evergreen.V384.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V384.DmChannelId.DmChannelId Evergreen.V384.Id.ThreadRoute (Maybe Evergreen.V384.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V384.Id.Id Evergreen.V384.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V384.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V384.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V384.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V384.UserAgent.UserAgent
    | AdminToBackend Evergreen.V384.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V384.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V384.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V384.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V384.PersonName.PersonName Evergreen.V384.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V384.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V384.Slack.OAuthCode Evergreen.V384.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V384.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V384.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V384.Id.Id Evergreen.V384.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V384.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V384.EmailAddress.EmailAddress (Result Evergreen.V384.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V384.EmailAddress.EmailAddress (Result Evergreen.V384.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V384.EmailAddress.EmailAddress (Result Evergreen.V384.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V384.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMaybeMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Result Evergreen.V384.Discord.HttpError Evergreen.V384.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V384.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Result Evergreen.V384.Discord.HttpError Evergreen.V384.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) (Result Evergreen.V384.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) (Result Evergreen.V384.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) (Result Evergreen.V384.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) (Result Evergreen.V384.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji (Result Evergreen.V384.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji (Result Evergreen.V384.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji (Result Evergreen.V384.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji (Result Evergreen.V384.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V384.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V384.Discord.HttpError (List ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId, Maybe Evergreen.V384.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Effect.Time.Posix Evergreen.V384.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V384.Slack.CurrentUser
            , team : Evergreen.V384.Slack.Team
            , users : List Evergreen.V384.Slack.User
            , channels : List ( Evergreen.V384.Slack.Channel, List Evergreen.V384.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Result Effect.Http.Error Evergreen.V384.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Discord.UserAuth (Result Evergreen.V384.Discord.HttpError Evergreen.V384.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Result Evergreen.V384.Discord.HttpError Evergreen.V384.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
        (Result
            Evergreen.V384.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId
                , members : List (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
                }
            , List
                ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId
                , { guild : Evergreen.V384.Discord.GatewayGuild
                  , channels : List Evergreen.V384.Discord.Channel
                  , icon : Maybe Evergreen.V384.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V384.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V384.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.AttachmentId, Evergreen.V384.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V384.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.AttachmentId, Evergreen.V384.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V384.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V384.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V384.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V384.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (Result Evergreen.V384.Discord.HttpError Evergreen.V384.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Result Evergreen.V384.Discord.HttpError (List Evergreen.V384.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V384.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V384.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V384.DmChannelId.DmChannelId Evergreen.V384.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V384.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V384.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V384.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
        (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V384.Discord.HttpError
            { guild : Evergreen.V384.Discord.GatewayGuild
            , channels : List Evergreen.V384.Discord.Channel
            , icon : Maybe Evergreen.V384.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Maybe Evergreen.V384.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Result Evergreen.V384.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V384.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V384.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (List ( Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId, Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId, Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (List ( Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V384.Discord.HttpError (List Evergreen.V384.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V384.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V384.SecretId.SecretId Evergreen.V384.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V384.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Result Evergreen.V384.Discord.HttpError ( Evergreen.V384.Discord.Guild, List Evergreen.V384.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V384.FileStatus.FileHash Int (Maybe (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Call.CallId
