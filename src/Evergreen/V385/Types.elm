module Evergreen.V385.Types exposing (..)

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
import Evergreen.V385.AiChat
import Evergreen.V385.Audio
import Evergreen.V385.BackendMsgLog
import Evergreen.V385.Call
import Evergreen.V385.ChannelDescription
import Evergreen.V385.ChannelName
import Evergreen.V385.Coord
import Evergreen.V385.CssPixels
import Evergreen.V385.CustomEmoji
import Evergreen.V385.Discord
import Evergreen.V385.DiscordAttachmentId
import Evergreen.V385.DiscordUserData
import Evergreen.V385.DmChannel
import Evergreen.V385.DmChannelId
import Evergreen.V385.Drawing
import Evergreen.V385.Editable
import Evergreen.V385.EmailAddress
import Evergreen.V385.Embed
import Evergreen.V385.Emoji
import Evergreen.V385.Encryption
import Evergreen.V385.FileStatus
import Evergreen.V385.Game
import Evergreen.V385.Go
import Evergreen.V385.GuildName
import Evergreen.V385.Id
import Evergreen.V385.IdArray
import Evergreen.V385.ImageEditor
import Evergreen.V385.ImageViewer
import Evergreen.V385.LinkedAndOtherDiscordUsers
import Evergreen.V385.Local
import Evergreen.V385.LocalState
import Evergreen.V385.Log
import Evergreen.V385.LoginForm
import Evergreen.V385.MembersAndOwner
import Evergreen.V385.Message
import Evergreen.V385.MessageInput
import Evergreen.V385.MessageView
import Evergreen.V385.MuteSettings
import Evergreen.V385.MyUi
import Evergreen.V385.NonemptyDict
import Evergreen.V385.NonemptySet
import Evergreen.V385.OneOrGreater
import Evergreen.V385.OneToOne
import Evergreen.V385.Pages.Admin
import Evergreen.V385.Pagination
import Evergreen.V385.PersonName
import Evergreen.V385.Ports
import Evergreen.V385.Postmark
import Evergreen.V385.Range
import Evergreen.V385.RateLimit
import Evergreen.V385.RecoveryLogin
import Evergreen.V385.RichText
import Evergreen.V385.Route
import Evergreen.V385.Scroll
import Evergreen.V385.SecretId
import Evergreen.V385.SessionIdHash
import Evergreen.V385.SetViewing
import Evergreen.V385.SheepGame
import Evergreen.V385.Slack
import Evergreen.V385.Sticker
import Evergreen.V385.TextEditor
import Evergreen.V385.ToBackendLog
import Evergreen.V385.Touch
import Evergreen.V385.TwoFactorAuthentication
import Evergreen.V385.Ui.Anim
import Evergreen.V385.User
import Evergreen.V385.UserAgent
import Evergreen.V385.UserColor
import Evergreen.V385.UserSession
import Evergreen.V385.WordSpellingGame
import Evergreen.V385.X25519
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
    | LoginFormMsg Evergreen.V385.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V385.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V385.Pages.Admin.Msg
    | PressedLogOut Evergreen.V385.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V385.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V385.Route.Route
    | SelectedFilesToAttach ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | PressedImportChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V385.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V385.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V385.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V385.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V385.NonemptyDict.NonemptyDict Int Evergreen.V385.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V385.NonemptyDict.NonemptyDict Int Evergreen.V385.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRoute Evergreen.V385.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V385.NonemptySet.NonemptySet (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V385.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V385.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V385.AiChat.Msg
    | GameMsg Evergreen.V385.Game.Msg
    | GoSpectatorMsg Evergreen.V385.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V385.Editable.Msg Evergreen.V385.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V385.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) (Maybe Evergreen.V385.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute )
        { fileId : Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute )
        { fileId : Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage Evergreen.V385.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V385.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V385.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V385.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V385.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V385.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V385.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | PressedDisableE2ee (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | TypedPrivateKey (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V385.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId
        , otherUserId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V385.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRoute Evergreen.V385.MessageInput.Msg
    | MessageInputMsg Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRoute Evergreen.V385.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V385.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V385.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V385.Range.Range, Evergreen.V385.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V385.Range.Range, Evergreen.V385.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V385.Call.FromJs)
    | VoiceChatMsg Evergreen.V385.Call.Msg
    | PressedChannelHeaderTab Evergreen.V385.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V385.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V385.Audio.LoadError Evergreen.V385.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V385.Id.AnyGuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V385.Id.AnyGuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) Evergreen.V385.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V385.Encryption.FromJs (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V385.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V385.UserSession.UserSession
    , currentlyViewing : Evergreen.V385.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) Evergreen.V385.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.LocalState.DiscordFrontendGuild
    , user : Evergreen.V385.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.User.FrontendUser
    , discordUsers : Evergreen.V385.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V385.SessionIdHash.SessionIdHash Evergreen.V385.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V385.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId) Evergreen.V385.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId) Evergreen.V385.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V385.Call.CallId (Evergreen.V385.NonemptyDict.NonemptyDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V385.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V385.Go.PublicGoMatchData Evergreen.V385.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V385.Route.Route
    , windowSize : Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V385.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V385.Audio.LoadError Evergreen.V385.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Encryption.EncryptedData (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.NonemptyDict.NonemptyDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Encryption.EncryptedData (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V385.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V385.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V385.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData) (List Evergreen.V385.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V385.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V385.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.ChannelName.ChannelName Evergreen.V385.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.ChannelName.ChannelName Evergreen.V385.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.UserSession.ToBeFilledInByBackend (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V385.GuildName.GuildName (Evergreen.V385.UserSession.ToBeFilledInByBackend (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V385.Id.Viewing_DiscordDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V385.SetViewing.SetViewing
    | Local_SetName Evergreen.V385.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V385.Id.GuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.UserSession.ToBeFilledInByBackend Evergreen.V385.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V385.Id.GuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V385.Id.DiscordGuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V385.Id.DiscordGuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V385.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V385.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V385.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.QuestionId Evergreen.V385.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V385.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V385.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V385.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V385.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V385.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V385.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V385.NonemptySet.NonemptySet (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V385.Call.LocalChange
    | Local_Game Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Game.LocalChange
    | Local_Drawing Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Drawing.AnchorType Evergreen.V385.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V385.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V385.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V385.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V385.X25519.PublicKey (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V385.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V385.Id.Viewing_DmId (List ( Evergreen.V385.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V385.FileStatus.FileHash, Evergreen.V385.Encryption.EncryptedData (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V385.Id.Viewing_DmId (Evergreen.V385.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V385.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V385.Id.ThreadRouteWithMessage, Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V385.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V385.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V385.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V385.FileStatus.FileHash) (Evergreen.V385.Encryption.EncryptedData (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))) (Evergreen.V385.Encryption.EncryptedData String) Evergreen.V385.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V385.Id.Viewing_DmId Evergreen.V385.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V385.FileStatus.FileHash) (Evergreen.V385.Encryption.EncryptedData (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.User.FrontendUser Effect.Time.Posix Evergreen.V385.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V385.RichText.RichText (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))) Evergreen.V385.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId) Evergreen.V385.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V385.Id.DiscordGuildOrDmId Evergreen.V385.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V385.RichText.RichText (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))) Evergreen.V385.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId) Evergreen.V385.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.ChannelName.ChannelName Evergreen.V385.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.ChannelName.ChannelName Evergreen.V385.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.User.FrontendUser
    | Server_MemberLeft (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V385.LocalState.JoinGuildError
            { guildId : Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId
            , guild : Evergreen.V385.LocalState.FrontendGuild
            , owner : Evergreen.V385.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V385.RichText.RichText (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V385.RichText.RichText (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V385.Id.Viewing_DiscordDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V385.RichText.RichText (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Maybe Evergreen.V385.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Maybe Evergreen.V385.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V385.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V385.SessionIdHash.SessionIdHash Evergreen.V385.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V385.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V385.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V385.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V385.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V385.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Bool Evergreen.V385.ChannelName.ChannelName (Evergreen.V385.Discord.OptionalData (Maybe String)) (List Evergreen.V385.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
        (Evergreen.V385.NonemptyDict.NonemptyDict
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) Evergreen.V385.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Maybe (Evergreen.V385.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V385.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V385.Log.Log
    | Server_BackupGenerated Evergreen.V385.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V385.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V385.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V385.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V385.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (Evergreen.V385.Discord.OptionalData (Maybe String)) (Evergreen.V385.Discord.OptionalData (Maybe String)) (List Evergreen.V385.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.GuildName.GuildName (Maybe Evergreen.V385.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId) Evergreen.V385.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId) Evergreen.V385.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
        (Evergreen.V385.MembersAndOwner.MembersAndOwner
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.PersonName.PersonName Evergreen.V385.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId) Evergreen.V385.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId) Evergreen.V385.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V385.Call.ServerChange
    | Server_Game (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Game.LocalChange
    | Server_Drawing (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Drawing.AnchorType Evergreen.V385.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V385.Id.Viewing_DmId ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V385.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V385.Id.Viewing_DmId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | Server_E2eeAccepted Evergreen.V385.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.User.FrontendUser Effect.Time.Posix Evergreen.V385.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V385.FileStatus.FileHash) (Evergreen.V385.Encryption.EncryptedData (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))) Evergreen.V385.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.Viewing_DmId Evergreen.V385.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V385.FileStatus.FileHash) (Evergreen.V385.Encryption.EncryptedData (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V385.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V385.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V385.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V385.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V385.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V385.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V385.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V385.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V385.Id.AnyGuildOrDmId Evergreen.V385.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V385.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels) (Maybe Evergreen.V385.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V385.SheepGame.Input (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels) (Maybe Evergreen.V385.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V385.Id.GuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V385.Id.GuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V385.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V385.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V385.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , threadRoute : Evergreen.V385.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V385.Encryption.BytesHash
    , id : Evergreen.V385.Id.Viewing_DmId
    , senderId : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , threadRoute : Evergreen.V385.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V385.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V385.Id.Viewing_DmId
    , messages : List Evergreen.V385.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V385.Id.Viewing_DmId
    , messages : List ( Evergreen.V385.Id.ThreadRouteWithMessage, Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V385.Id.Viewing_DmId
    , threadRoute : Evergreen.V385.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute )
    , fileId : Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V385.Id.Id Evergreen.V385.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V385.Id.Id Evergreen.V385.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V385.Id.Id Evergreen.V385.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V385.Id.Id Evergreen.V385.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V385.Id.Id Evergreen.V385.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V385.Local.Local LocalMsg Evergreen.V385.LocalState.LocalState
    , admin : Evergreen.V385.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V385.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V385.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.Message.RepliedTo Evergreen.V385.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V385.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V385.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V385.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.ThreadRoute ) (Evergreen.V385.NonemptyDict.NonemptyDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V385.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V385.Scroll.ScrollPosition
    , textEditor : Evergreen.V385.TextEditor.Model
    , profilePictureEditor : Evergreen.V385.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId, Evergreen.V385.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V385.Emoji.Model
    , voiceChat : Evergreen.V385.Call.Model
    , games : SeqDict.SeqDict Evergreen.V385.Id.GuildOrDmId Evergreen.V385.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V385.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V385.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V385.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V385.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V385.Range.Range
                , direction : Evergreen.V385.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V385.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V385.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V385.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V385.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V385.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V385.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V385.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V385.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V385.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V385.MyUi.LastCopy
    , drag : Evergreen.V385.Touch.Drag
    , dragPrevious : Evergreen.V385.Touch.Drag
    , aiChatModel : Evergreen.V385.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V385.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V385.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V385.Audio.LoadError Evergreen.V385.Audio.Source
    , startupData : Evergreen.V385.Ports.StartupData
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
    Evergreen.V385.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V385.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V385.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V385.FileStatus.FileHash
    , metadata : Maybe Evergreen.V385.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId, Evergreen.V385.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId, Evergreen.V385.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V385.DmChannelId.DmChannelId, Evergreen.V385.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId, Evergreen.V385.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId, Evergreen.V385.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId, Evergreen.V385.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V385.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V385.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V385.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V385.NonemptyDict.NonemptyDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V385.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V385.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V385.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V385.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V385.DmChannelId.DmChannelId Evergreen.V385.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) Evergreen.V385.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.Slack.Id Evergreen.V385.Slack.ChannelId) Evergreen.V385.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V385.OneToOne.OneToOne String (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    , slackUsers : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.Slack.Id Evergreen.V385.Slack.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    , slackServers : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.Slack.Id Evergreen.V385.Slack.TeamId) (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    , slackToken : Maybe Evergreen.V385.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V385.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V385.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V385.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V385.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId, Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V385.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V385.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V385.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V385.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.LocalState.LoadingDiscordChannel Evergreen.V385.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V385.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V385.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V385.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId) Evergreen.V385.Sticker.StickerData
    , discordStickers : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.Discord.Id Evergreen.V385.Discord.StickerId) (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId) Evergreen.V385.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V385.OneToOne.OneToOne Evergreen.V385.RichText.DiscordCustomEmojiIdAndName (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V385.Postmark.ApiKey
    , serverSecret : Evergreen.V385.SecretId.SecretId Evergreen.V385.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V385.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.GamePublicId) ( Evergreen.V385.DmChannelId.GuildOrFullDmId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V385.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V385.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V385.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.Id.ThreadRoute (Maybe Evergreen.V385.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V385.DmChannelId.DmChannelId Evergreen.V385.Id.ThreadRoute (Maybe Evergreen.V385.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V385.Id.Id Evergreen.V385.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V385.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V385.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V385.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V385.UserAgent.UserAgent
    | AdminToBackend Evergreen.V385.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V385.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V385.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V385.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V385.PersonName.PersonName Evergreen.V385.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V385.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V385.Slack.OAuthCode Evergreen.V385.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V385.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V385.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V385.Id.Id Evergreen.V385.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V385.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V385.EmailAddress.EmailAddress (Result Evergreen.V385.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V385.EmailAddress.EmailAddress (Result Evergreen.V385.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V385.EmailAddress.EmailAddress (Result Evergreen.V385.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V385.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMaybeMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Result Evergreen.V385.Discord.HttpError Evergreen.V385.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V385.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Result Evergreen.V385.Discord.HttpError Evergreen.V385.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) (Result Evergreen.V385.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) (Result Evergreen.V385.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) (Result Evergreen.V385.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) (Result Evergreen.V385.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji (Result Evergreen.V385.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji (Result Evergreen.V385.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji (Result Evergreen.V385.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji (Result Evergreen.V385.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V385.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V385.Discord.HttpError (List ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId, Maybe Evergreen.V385.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Effect.Time.Posix Evergreen.V385.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V385.Slack.CurrentUser
            , team : Evergreen.V385.Slack.Team
            , users : List Evergreen.V385.Slack.User
            , channels : List ( Evergreen.V385.Slack.Channel, List Evergreen.V385.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Result Effect.Http.Error Evergreen.V385.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Discord.UserAuth (Result Evergreen.V385.Discord.HttpError Evergreen.V385.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Result Evergreen.V385.Discord.HttpError Evergreen.V385.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
        (Result
            Evergreen.V385.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId
                , members : List (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
                }
            , List
                ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId
                , { guild : Evergreen.V385.Discord.GatewayGuild
                  , channels : List Evergreen.V385.Discord.Channel
                  , icon : Maybe Evergreen.V385.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V385.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V385.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.AttachmentId, Evergreen.V385.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V385.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.AttachmentId, Evergreen.V385.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V385.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V385.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V385.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V385.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (Result Evergreen.V385.Discord.HttpError Evergreen.V385.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Result Evergreen.V385.Discord.HttpError (List Evergreen.V385.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V385.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V385.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V385.DmChannelId.DmChannelId Evergreen.V385.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V385.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V385.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V385.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
        (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V385.Discord.HttpError
            { guild : Evergreen.V385.Discord.GatewayGuild
            , channels : List Evergreen.V385.Discord.Channel
            , icon : Maybe Evergreen.V385.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Maybe Evergreen.V385.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Result Evergreen.V385.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V385.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V385.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (List ( Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId, Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId, Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (List ( Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V385.Discord.HttpError (List Evergreen.V385.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V385.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V385.SecretId.SecretId Evergreen.V385.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V385.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Result Evergreen.V385.Discord.HttpError ( Evergreen.V385.Discord.Guild, List Evergreen.V385.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V385.FileStatus.FileHash Int (Maybe (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Call.CallId
