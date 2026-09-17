module Evergreen.V383.Types exposing (..)

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
import Evergreen.V383.AiChat
import Evergreen.V383.Audio
import Evergreen.V383.BackendMsgLog
import Evergreen.V383.Call
import Evergreen.V383.ChannelDescription
import Evergreen.V383.ChannelName
import Evergreen.V383.Coord
import Evergreen.V383.CssPixels
import Evergreen.V383.CustomEmoji
import Evergreen.V383.Discord
import Evergreen.V383.DiscordAttachmentId
import Evergreen.V383.DiscordUserData
import Evergreen.V383.DmChannel
import Evergreen.V383.DmChannelId
import Evergreen.V383.Drawing
import Evergreen.V383.Editable
import Evergreen.V383.EmailAddress
import Evergreen.V383.Embed
import Evergreen.V383.Emoji
import Evergreen.V383.Encryption
import Evergreen.V383.FileStatus
import Evergreen.V383.Game
import Evergreen.V383.Go
import Evergreen.V383.GuildName
import Evergreen.V383.Id
import Evergreen.V383.IdArray
import Evergreen.V383.ImageEditor
import Evergreen.V383.ImageViewer
import Evergreen.V383.LinkedAndOtherDiscordUsers
import Evergreen.V383.Local
import Evergreen.V383.LocalState
import Evergreen.V383.Log
import Evergreen.V383.LoginForm
import Evergreen.V383.MembersAndOwner
import Evergreen.V383.Message
import Evergreen.V383.MessageInput
import Evergreen.V383.MessageView
import Evergreen.V383.MuteSettings
import Evergreen.V383.MyUi
import Evergreen.V383.NonemptyDict
import Evergreen.V383.NonemptySet
import Evergreen.V383.OneOrGreater
import Evergreen.V383.OneToOne
import Evergreen.V383.Pages.Admin
import Evergreen.V383.Pagination
import Evergreen.V383.PersonName
import Evergreen.V383.Ports
import Evergreen.V383.Postmark
import Evergreen.V383.Range
import Evergreen.V383.RecoveryLogin
import Evergreen.V383.RichText
import Evergreen.V383.Route
import Evergreen.V383.Scroll
import Evergreen.V383.SecretId
import Evergreen.V383.SessionIdHash
import Evergreen.V383.SheepGame
import Evergreen.V383.Slack
import Evergreen.V383.Sticker
import Evergreen.V383.TextEditor
import Evergreen.V383.ToBackendLog
import Evergreen.V383.Touch
import Evergreen.V383.TwoFactorAuthentication
import Evergreen.V383.Ui.Anim
import Evergreen.V383.User
import Evergreen.V383.UserAgent
import Evergreen.V383.UserColor
import Evergreen.V383.UserSession
import Evergreen.V383.WordSpellingGame
import Evergreen.V383.X25519
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
    | LoginFormMsg Evergreen.V383.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V383.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V383.Pages.Admin.Msg
    | PressedLogOut Evergreen.V383.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V383.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V383.Route.Route
    | SelectedFilesToAttach ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | PressedImportChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V383.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V383.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V383.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V383.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V383.NonemptyDict.NonemptyDict Int Evergreen.V383.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V383.NonemptyDict.NonemptyDict Int Evergreen.V383.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRoute Evergreen.V383.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V383.NonemptySet.NonemptySet (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V383.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V383.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V383.AiChat.Msg
    | GameMsg Evergreen.V383.Game.Msg
    | GoSpectatorMsg Evergreen.V383.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V383.Editable.Msg Evergreen.V383.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V383.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) (Maybe Evergreen.V383.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute )
        { fileId : Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute )
        { fileId : Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage Evergreen.V383.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V383.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V383.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V383.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V383.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V383.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V383.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | PressedDisableE2ee (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | TypedPrivateKey (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V383.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId
        , otherUserId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V383.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRoute Evergreen.V383.MessageInput.Msg
    | MessageInputMsg Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRoute Evergreen.V383.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V383.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V383.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V383.Range.Range, Evergreen.V383.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V383.Range.Range, Evergreen.V383.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V383.Call.FromJs)
    | VoiceChatMsg Evergreen.V383.Call.Msg
    | PressedChannelHeaderTab Evergreen.V383.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V383.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V383.Audio.LoadError Evergreen.V383.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V383.Id.AnyGuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V383.Id.AnyGuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) Evergreen.V383.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V383.Encryption.FromJs (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V383.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V383.UserSession.UserSession
    , currentlyViewing : Evergreen.V383.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) Evergreen.V383.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.LocalState.DiscordFrontendGuild
    , user : Evergreen.V383.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.User.FrontendUser
    , discordUsers : Evergreen.V383.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V383.SessionIdHash.SessionIdHash Evergreen.V383.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V383.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId) Evergreen.V383.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId) Evergreen.V383.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V383.Call.CallId (Evergreen.V383.NonemptyDict.NonemptyDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V383.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V383.Go.PublicGoMatchData Evergreen.V383.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V383.Route.Route
    , windowSize : Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V383.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V383.Audio.LoadError Evergreen.V383.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Encryption.EncryptedData (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.NonemptyDict.NonemptyDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Encryption.EncryptedData (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V383.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V383.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V383.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileData) (List Evergreen.V383.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V383.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V383.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.ChannelName.ChannelName Evergreen.V383.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.ChannelName.ChannelName Evergreen.V383.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V383.GuildName.GuildName (Evergreen.V383.UserSession.ToBeFilledInByBackend (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V383.Id.Viewing_DiscordDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V383.UserSession.SetViewing
    | Local_SetName Evergreen.V383.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V383.Id.GuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V383.Id.GuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V383.Id.DiscordGuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V383.Id.DiscordGuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V383.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V383.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V383.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.QuestionId Evergreen.V383.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V383.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V383.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V383.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V383.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V383.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V383.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V383.NonemptySet.NonemptySet (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V383.Call.LocalChange
    | Local_Game Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Game.LocalChange
    | Local_Drawing Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Drawing.AnchorType Evergreen.V383.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V383.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V383.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V383.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V383.X25519.PublicKey (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V383.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V383.Id.Viewing_DmId (List ( Evergreen.V383.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V383.FileStatus.FileHash, Evergreen.V383.Encryption.EncryptedData (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V383.Id.Viewing_DmId (Evergreen.V383.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V383.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V383.Id.ThreadRouteWithMessage, Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V383.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V383.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V383.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V383.FileStatus.FileHash) (Evergreen.V383.Encryption.EncryptedData (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))) (Evergreen.V383.Encryption.EncryptedData String) Evergreen.V383.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V383.Id.Viewing_DmId Evergreen.V383.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V383.FileStatus.FileHash) (Evergreen.V383.Encryption.EncryptedData (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.User.FrontendUser Effect.Time.Posix Evergreen.V383.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V383.RichText.RichText (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))) Evergreen.V383.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId) Evergreen.V383.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V383.Id.DiscordGuildOrDmId Evergreen.V383.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V383.RichText.RichText (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))) Evergreen.V383.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId) Evergreen.V383.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.ChannelName.ChannelName Evergreen.V383.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.ChannelName.ChannelName Evergreen.V383.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.User.FrontendUser
    | Server_MemberLeft (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V383.LocalState.JoinGuildError
            { guildId : Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId
            , guild : Evergreen.V383.LocalState.FrontendGuild
            , owner : Evergreen.V383.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V383.RichText.RichText (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V383.RichText.RichText (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V383.Id.Viewing_DiscordDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V383.RichText.RichText (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Maybe Evergreen.V383.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Maybe Evergreen.V383.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V383.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V383.SessionIdHash.SessionIdHash Evergreen.V383.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V383.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V383.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V383.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V383.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V383.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Bool Evergreen.V383.ChannelName.ChannelName (Evergreen.V383.Discord.OptionalData (Maybe String)) (List Evergreen.V383.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
        (Evergreen.V383.NonemptyDict.NonemptyDict
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) Evergreen.V383.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Maybe (Evergreen.V383.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V383.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V383.Log.Log
    | Server_BackupGenerated Evergreen.V383.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V383.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V383.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V383.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V383.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (Evergreen.V383.Discord.OptionalData (Maybe String)) (Evergreen.V383.Discord.OptionalData (Maybe String)) (List Evergreen.V383.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.GuildName.GuildName (Maybe Evergreen.V383.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId) Evergreen.V383.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId) Evergreen.V383.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
        (Evergreen.V383.MembersAndOwner.MembersAndOwner
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.PersonName.PersonName Evergreen.V383.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId) Evergreen.V383.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId) Evergreen.V383.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V383.Call.ServerChange
    | Server_Game (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Game.LocalChange
    | Server_Drawing (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Drawing.AnchorType Evergreen.V383.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V383.Id.Viewing_DmId ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V383.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V383.Id.Viewing_DmId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | Server_E2eeAccepted Evergreen.V383.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.User.FrontendUser Effect.Time.Posix Evergreen.V383.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V383.FileStatus.FileHash) (Evergreen.V383.Encryption.EncryptedData (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))) Evergreen.V383.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.Viewing_DmId Evergreen.V383.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V383.FileStatus.FileHash) (Evergreen.V383.Encryption.EncryptedData (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V383.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V383.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V383.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V383.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V383.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V383.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V383.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V383.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V383.Id.AnyGuildOrDmId Evergreen.V383.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V383.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels) (Maybe Evergreen.V383.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V383.SheepGame.Input (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels) (Maybe Evergreen.V383.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V383.Id.GuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V383.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V383.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V383.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , threadRoute : Evergreen.V383.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V383.Encryption.BytesHash
    , id : Evergreen.V383.Id.Viewing_DmId
    , senderId : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , threadRoute : Evergreen.V383.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V383.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V383.Id.Viewing_DmId
    , messages : List Evergreen.V383.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V383.Id.Viewing_DmId
    , messages : List ( Evergreen.V383.Id.ThreadRouteWithMessage, Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V383.Id.Viewing_DmId
    , threadRoute : Evergreen.V383.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute )
    , fileId : Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V383.Id.Id Evergreen.V383.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V383.Id.Id Evergreen.V383.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V383.Id.Id Evergreen.V383.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V383.Id.Id Evergreen.V383.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V383.Id.Id Evergreen.V383.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V383.Local.Local LocalMsg Evergreen.V383.LocalState.LocalState
    , admin : Evergreen.V383.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V383.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V383.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V383.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V383.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V383.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.ThreadRoute ) (Evergreen.V383.NonemptyDict.NonemptyDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V383.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V383.Scroll.ScrollPosition
    , textEditor : Evergreen.V383.TextEditor.Model
    , profilePictureEditor : Evergreen.V383.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId, Evergreen.V383.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V383.Emoji.Model
    , voiceChat : Evergreen.V383.Call.Model
    , games : SeqDict.SeqDict Evergreen.V383.Id.GuildOrDmId Evergreen.V383.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V383.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V383.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V383.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V383.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V383.Range.Range
                , direction : Evergreen.V383.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V383.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V383.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V383.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V383.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V383.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V383.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V383.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V383.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V383.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V383.MyUi.LastCopy
    , drag : Evergreen.V383.Touch.Drag
    , dragPrevious : Evergreen.V383.Touch.Drag
    , aiChatModel : Evergreen.V383.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V383.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V383.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V383.Audio.LoadError Evergreen.V383.Audio.Source
    , startupData : Evergreen.V383.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V383.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V383.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V383.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V383.FileStatus.FileHash
    , metadata : Maybe Evergreen.V383.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId, Evergreen.V383.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId, Evergreen.V383.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V383.DmChannelId.DmChannelId, Evergreen.V383.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId, Evergreen.V383.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId, Evergreen.V383.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId, Evergreen.V383.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V383.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V383.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V383.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V383.NonemptyDict.NonemptyDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V383.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V383.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V383.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V383.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V383.DmChannelId.DmChannelId Evergreen.V383.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) Evergreen.V383.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.Slack.Id Evergreen.V383.Slack.ChannelId) Evergreen.V383.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V383.OneToOne.OneToOne String (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    , slackUsers : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.Slack.Id Evergreen.V383.Slack.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    , slackServers : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.Slack.Id Evergreen.V383.Slack.TeamId) (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    , slackToken : Maybe Evergreen.V383.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V383.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V383.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V383.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V383.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId, Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V383.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V383.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V383.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V383.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.LocalState.LoadingDiscordChannel Evergreen.V383.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V383.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V383.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId) Evergreen.V383.Sticker.StickerData
    , discordStickers : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.Discord.Id Evergreen.V383.Discord.StickerId) (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId) Evergreen.V383.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V383.OneToOne.OneToOne Evergreen.V383.RichText.DiscordCustomEmojiIdAndName (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V383.Postmark.ApiKey
    , serverSecret : Evergreen.V383.SecretId.SecretId Evergreen.V383.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V383.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.GamePublicId) ( Evergreen.V383.DmChannelId.GuildOrFullDmId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V383.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V383.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V383.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.Id.ThreadRoute (Maybe Evergreen.V383.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V383.DmChannelId.DmChannelId Evergreen.V383.Id.ThreadRoute (Maybe Evergreen.V383.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V383.Id.Id Evergreen.V383.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V383.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V383.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V383.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V383.UserAgent.UserAgent
    | AdminToBackend Evergreen.V383.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V383.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V383.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V383.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V383.PersonName.PersonName Evergreen.V383.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V383.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V383.Slack.OAuthCode Evergreen.V383.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V383.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V383.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V383.Id.Id Evergreen.V383.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V383.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V383.EmailAddress.EmailAddress (Result Evergreen.V383.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V383.EmailAddress.EmailAddress (Result Evergreen.V383.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V383.EmailAddress.EmailAddress (Result Evergreen.V383.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V383.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMaybeMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Result Evergreen.V383.Discord.HttpError Evergreen.V383.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V383.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Result Evergreen.V383.Discord.HttpError Evergreen.V383.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) (Result Evergreen.V383.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) (Result Evergreen.V383.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) (Result Evergreen.V383.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) (Result Evergreen.V383.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji (Result Evergreen.V383.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji (Result Evergreen.V383.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji (Result Evergreen.V383.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji (Result Evergreen.V383.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V383.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V383.Discord.HttpError (List ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId, Maybe Evergreen.V383.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Effect.Time.Posix Evergreen.V383.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V383.Slack.CurrentUser
            , team : Evergreen.V383.Slack.Team
            , users : List Evergreen.V383.Slack.User
            , channels : List ( Evergreen.V383.Slack.Channel, List Evergreen.V383.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Result Effect.Http.Error Evergreen.V383.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Discord.UserAuth (Result Evergreen.V383.Discord.HttpError Evergreen.V383.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Result Evergreen.V383.Discord.HttpError Evergreen.V383.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
        (Result
            Evergreen.V383.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId
                , members : List (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
                }
            , List
                ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId
                , { guild : Evergreen.V383.Discord.GatewayGuild
                  , channels : List Evergreen.V383.Discord.Channel
                  , icon : Maybe Evergreen.V383.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V383.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V383.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.AttachmentId, Evergreen.V383.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V383.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.AttachmentId, Evergreen.V383.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V383.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V383.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V383.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V383.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (Result Evergreen.V383.Discord.HttpError Evergreen.V383.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Result Evergreen.V383.Discord.HttpError (List Evergreen.V383.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V383.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V383.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V383.DmChannelId.DmChannelId Evergreen.V383.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V383.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V383.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V383.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
        (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V383.Discord.HttpError
            { guild : Evergreen.V383.Discord.GatewayGuild
            , channels : List Evergreen.V383.Discord.Channel
            , icon : Maybe Evergreen.V383.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Maybe Evergreen.V383.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Result Evergreen.V383.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V383.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V383.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (List ( Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId, Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId, Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (List ( Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V383.Discord.HttpError (List Evergreen.V383.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V383.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V383.SecretId.SecretId Evergreen.V383.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V383.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Result Evergreen.V383.Discord.HttpError ( Evergreen.V383.Discord.Guild, List Evergreen.V383.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V383.FileStatus.FileHash Int (Maybe (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Call.CallId
