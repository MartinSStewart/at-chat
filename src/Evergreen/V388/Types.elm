module Evergreen.V388.Types exposing (..)

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
import Evergreen.V388.AiChat
import Evergreen.V388.Audio
import Evergreen.V388.BackendMsgLog
import Evergreen.V388.Call
import Evergreen.V388.ChannelDescription
import Evergreen.V388.ChannelName
import Evergreen.V388.Coord
import Evergreen.V388.CssPixels
import Evergreen.V388.CustomEmoji
import Evergreen.V388.Discord
import Evergreen.V388.DiscordAttachmentId
import Evergreen.V388.DiscordUserData
import Evergreen.V388.DmChannel
import Evergreen.V388.DmChannelId
import Evergreen.V388.Drawing
import Evergreen.V388.Editable
import Evergreen.V388.EmailAddress
import Evergreen.V388.Embed
import Evergreen.V388.Emoji
import Evergreen.V388.Encryption
import Evergreen.V388.FileStatus
import Evergreen.V388.Game
import Evergreen.V388.Go
import Evergreen.V388.GuildName
import Evergreen.V388.Id
import Evergreen.V388.IdArray
import Evergreen.V388.ImageEditor
import Evergreen.V388.ImageViewer
import Evergreen.V388.LinkedAndOtherDiscordUsers
import Evergreen.V388.Local
import Evergreen.V388.LocalState
import Evergreen.V388.Log
import Evergreen.V388.LoginForm
import Evergreen.V388.MembersAndOwner
import Evergreen.V388.Message
import Evergreen.V388.MessageInput
import Evergreen.V388.MessageView
import Evergreen.V388.MuteSettings
import Evergreen.V388.MyUi
import Evergreen.V388.NonemptyDict
import Evergreen.V388.NonemptySet
import Evergreen.V388.OneOrGreater
import Evergreen.V388.OneToOne
import Evergreen.V388.Pages.Admin
import Evergreen.V388.Pagination
import Evergreen.V388.PersonName
import Evergreen.V388.Ports
import Evergreen.V388.Postmark
import Evergreen.V388.Range
import Evergreen.V388.RateLimit
import Evergreen.V388.RecoveryLogin
import Evergreen.V388.RichText
import Evergreen.V388.Route
import Evergreen.V388.Scroll
import Evergreen.V388.SecretId
import Evergreen.V388.SessionIdHash
import Evergreen.V388.SetViewing
import Evergreen.V388.SheepGame
import Evergreen.V388.Slack
import Evergreen.V388.Sticker
import Evergreen.V388.TextEditor
import Evergreen.V388.ToBackendLog
import Evergreen.V388.Touch
import Evergreen.V388.TwoFactorAuthentication
import Evergreen.V388.Ui.Anim
import Evergreen.V388.User
import Evergreen.V388.UserAgent
import Evergreen.V388.UserColor
import Evergreen.V388.UserSession
import Evergreen.V388.WordSpellingGame
import Evergreen.V388.X25519
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
    | LoginFormMsg Evergreen.V388.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V388.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V388.Pages.Admin.Msg
    | PressedLogOut Evergreen.V388.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V388.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V388.Route.Route
    | SelectedFilesToAttach ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | PressedImportChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V388.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V388.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V388.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V388.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V388.NonemptyDict.NonemptyDict Int Evergreen.V388.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V388.NonemptyDict.NonemptyDict Int Evergreen.V388.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRoute Evergreen.V388.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V388.NonemptySet.NonemptySet (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V388.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V388.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V388.AiChat.Msg
    | GameMsg Evergreen.V388.Game.Msg
    | GoSpectatorMsg Evergreen.V388.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V388.Editable.Msg Evergreen.V388.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V388.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) (Maybe Evergreen.V388.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute )
        { fileId : Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute )
        { fileId : Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage Evergreen.V388.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V388.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V388.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V388.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V388.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V388.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V388.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | PressedDisableE2ee (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | TypedPrivateKey (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V388.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId
        , otherUserId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V388.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRoute Evergreen.V388.MessageInput.Msg
    | MessageInputMsg Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRoute Evergreen.V388.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V388.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V388.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V388.Range.Range, Evergreen.V388.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V388.Range.Range, Evergreen.V388.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V388.Call.FromJs)
    | VoiceChatMsg Evergreen.V388.Call.Msg
    | PressedChannelHeaderTab Evergreen.V388.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V388.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V388.Audio.LoadError Evergreen.V388.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V388.Id.AnyGuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V388.Id.AnyGuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) Evergreen.V388.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V388.Encryption.FromJs (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V388.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V388.UserSession.UserSession
    , currentlyViewing : Evergreen.V388.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) Evergreen.V388.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.LocalState.DiscordFrontendGuild
    , user : Evergreen.V388.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.User.FrontendUser
    , discordUsers : Evergreen.V388.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V388.SessionIdHash.SessionIdHash Evergreen.V388.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V388.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId) Evergreen.V388.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId) Evergreen.V388.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V388.Call.CallId (Evergreen.V388.NonemptyDict.NonemptyDict ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V388.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V388.Go.PublicGoMatchData Evergreen.V388.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V388.Route.Route
    , windowSize : Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V388.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V388.Audio.LoadError Evergreen.V388.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Encryption.EncryptedData (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.NonemptyDict.NonemptyDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.Encryption.EncryptedData (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V388.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V388.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V388.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData) (List Evergreen.V388.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V388.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V388.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.ChannelName.ChannelName Evergreen.V388.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.ChannelName.ChannelName Evergreen.V388.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.UserSession.ToBeFilledInByBackend (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V388.GuildName.GuildName (Evergreen.V388.UserSession.ToBeFilledInByBackend (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V388.Id.Viewing_DiscordDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V388.SetViewing.SetViewing
    | Local_SetName Evergreen.V388.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V388.Id.GuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.UserSession.ToBeFilledInByBackend Evergreen.V388.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V388.Id.GuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.Message.Message Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V388.Id.DiscordGuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V388.Id.DiscordGuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.Message.Message Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V388.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V388.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V388.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.QuestionId Evergreen.V388.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V388.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V388.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V388.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V388.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V388.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V388.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V388.NonemptySet.NonemptySet (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V388.Call.LocalChange
    | Local_Game Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Game.LocalChange
    | Local_Drawing Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Drawing.AnchorType Evergreen.V388.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V388.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V388.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V388.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V388.X25519.PublicKey (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V388.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V388.Id.Viewing_DmId (List ( Evergreen.V388.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V388.FileStatus.FileHash, Evergreen.V388.Encryption.EncryptedData (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V388.Id.Viewing_DmId (Evergreen.V388.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V388.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V388.Id.ThreadRouteWithMessage, Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V388.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V388.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V388.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V388.FileStatus.FileHash) (Evergreen.V388.Encryption.EncryptedData (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))) (Evergreen.V388.Encryption.EncryptedData String) Evergreen.V388.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V388.Id.Viewing_DmId Evergreen.V388.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V388.FileStatus.FileHash) (Evergreen.V388.Encryption.EncryptedData (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.User.FrontendUser Effect.Time.Posix Evergreen.V388.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V388.RichText.RichText (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))) Evergreen.V388.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId) Evergreen.V388.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V388.Id.DiscordGuildOrDmId Evergreen.V388.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V388.RichText.RichText (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))) Evergreen.V388.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId) Evergreen.V388.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.ChannelName.ChannelName Evergreen.V388.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.ChannelName.ChannelName Evergreen.V388.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.User.FrontendUser
    | Server_MemberLeft (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V388.LocalState.JoinGuildError
            { guildId : Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId
            , guild : Evergreen.V388.LocalState.FrontendGuild
            , owner : Evergreen.V388.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V388.RichText.RichText (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V388.RichText.RichText (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V388.Id.Viewing_DiscordDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V388.RichText.RichText (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Maybe Evergreen.V388.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Maybe Evergreen.V388.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V388.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V388.SessionIdHash.SessionIdHash Evergreen.V388.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V388.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V388.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V388.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V388.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V388.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Bool Evergreen.V388.ChannelName.ChannelName (Evergreen.V388.Discord.OptionalData (Maybe String)) (List Evergreen.V388.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
        (Evergreen.V388.NonemptyDict.NonemptyDict
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) Evergreen.V388.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Maybe (Evergreen.V388.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V388.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V388.Log.Log
    | Server_BackupGenerated Evergreen.V388.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V388.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V388.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V388.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V388.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (Evergreen.V388.Discord.OptionalData (Maybe String)) (Evergreen.V388.Discord.OptionalData (Maybe String)) (List Evergreen.V388.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.GuildName.GuildName (Maybe Evergreen.V388.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId) Evergreen.V388.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId) Evergreen.V388.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
        (Evergreen.V388.MembersAndOwner.MembersAndOwner
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.PersonName.PersonName Evergreen.V388.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId) Evergreen.V388.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId) Evergreen.V388.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V388.Call.ServerChange
    | Server_Game (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Game.LocalChange
    | Server_Drawing (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Drawing.AnchorType Evergreen.V388.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V388.Id.Viewing_DmId ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Evergreen.V388.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V388.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V388.Id.Viewing_DmId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | Server_E2eeAccepted Evergreen.V388.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.User.FrontendUser Effect.Time.Posix Evergreen.V388.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V388.FileStatus.FileHash) (Evergreen.V388.Encryption.EncryptedData (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))) Evergreen.V388.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.Viewing_DmId Evergreen.V388.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V388.FileStatus.FileHash) (Evergreen.V388.Encryption.EncryptedData (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V388.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V388.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V388.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V388.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V388.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V388.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V388.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V388.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V388.Id.AnyGuildOrDmId Evergreen.V388.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V388.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels) (Maybe Evergreen.V388.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V388.SheepGame.Input (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels) (Maybe Evergreen.V388.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V388.Id.GuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V388.Id.GuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId) (Evergreen.V388.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V388.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V388.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V388.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , threadRoute : Evergreen.V388.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V388.Encryption.BytesHash
    , id : Evergreen.V388.Id.Viewing_DmId
    , senderId : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , threadRoute : Evergreen.V388.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V388.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V388.Id.Viewing_DmId
    , messages : List Evergreen.V388.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V388.Id.Viewing_DmId
    , messages : List ( Evergreen.V388.Id.ThreadRouteWithMessage, Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V388.Id.Viewing_DmId
    , threadRoute : Evergreen.V388.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute )
    , fileId : Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V388.Id.Id Evergreen.V388.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V388.Id.Id Evergreen.V388.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V388.Id.Id Evergreen.V388.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V388.Id.Id Evergreen.V388.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V388.Id.Id Evergreen.V388.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V388.Local.Local LocalMsg Evergreen.V388.LocalState.LocalState
    , admin : Evergreen.V388.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId, Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V388.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V388.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.Message.RepliedTo Evergreen.V388.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V388.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V388.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V388.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.ThreadRoute ) (Evergreen.V388.NonemptyDict.NonemptyDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V388.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V388.Scroll.ScrollPosition
    , textEditor : Evergreen.V388.TextEditor.Model
    , profilePictureEditor : Evergreen.V388.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId, Evergreen.V388.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V388.Emoji.Model
    , voiceChat : Evergreen.V388.Call.Model
    , games : SeqDict.SeqDict Evergreen.V388.Id.GuildOrDmId Evergreen.V388.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V388.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V388.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V388.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V388.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V388.Range.Range
                , direction : Evergreen.V388.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V388.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V388.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V388.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V388.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V388.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V388.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V388.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V388.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V388.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V388.MyUi.LastCopy
    , drag : Evergreen.V388.Touch.Drag
    , dragPrevious : Evergreen.V388.Touch.Drag
    , aiChatModel : Evergreen.V388.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V388.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V388.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V388.Audio.LoadError Evergreen.V388.Audio.Source
    , startupData : Evergreen.V388.Ports.StartupData
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
    Evergreen.V388.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V388.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V388.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V388.FileStatus.FileHash
    , metadata : Maybe Evergreen.V388.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId, Evergreen.V388.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId, Evergreen.V388.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V388.DmChannelId.DmChannelId, Evergreen.V388.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId, Evergreen.V388.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId, Evergreen.V388.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId, Evergreen.V388.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V388.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V388.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V388.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V388.NonemptyDict.NonemptyDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V388.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V388.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V388.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V388.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V388.DmChannelId.DmChannelId Evergreen.V388.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) Evergreen.V388.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.Slack.Id Evergreen.V388.Slack.ChannelId) Evergreen.V388.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V388.OneToOne.OneToOne String (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    , slackUsers : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.Slack.Id Evergreen.V388.Slack.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    , slackServers : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.Slack.Id Evergreen.V388.Slack.TeamId) (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    , slackToken : Maybe Evergreen.V388.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V388.FileStatus.FileHash Evergreen.V388.FileStatus.BackendFileData
    , privateVapidKey : Evergreen.V388.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V388.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V388.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId, Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V388.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V388.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V388.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V388.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.LocalState.LoadingDiscordChannel Evergreen.V388.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V388.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V388.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V388.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId) Evergreen.V388.Sticker.StickerData
    , discordStickers : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.Discord.Id Evergreen.V388.Discord.StickerId) (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId) Evergreen.V388.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V388.OneToOne.OneToOne Evergreen.V388.RichText.DiscordCustomEmojiIdAndName (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V388.Postmark.ApiKey
    , serverSecret : Evergreen.V388.SecretId.SecretId Evergreen.V388.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V388.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.GamePublicId) ( Evergreen.V388.DmChannelId.GuildOrFullDmId, Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V388.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V388.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V388.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.Id.ThreadRoute (Maybe Evergreen.V388.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V388.DmChannelId.DmChannelId Evergreen.V388.Id.ThreadRoute (Maybe Evergreen.V388.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V388.Id.Id Evergreen.V388.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V388.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V388.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V388.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V388.UserAgent.UserAgent
    | AdminToBackend Evergreen.V388.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V388.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V388.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V388.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V388.PersonName.PersonName Evergreen.V388.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V388.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V388.Slack.OAuthCode Evergreen.V388.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V388.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V388.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V388.Id.Id Evergreen.V388.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V388.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V388.EmailAddress.EmailAddress (Result Evergreen.V388.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V388.EmailAddress.EmailAddress (Result Evergreen.V388.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V388.EmailAddress.EmailAddress (Result Evergreen.V388.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V388.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMaybeMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Result Evergreen.V388.Discord.HttpError Evergreen.V388.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V388.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Result Evergreen.V388.Discord.HttpError Evergreen.V388.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) (Result Evergreen.V388.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) (Result Evergreen.V388.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) (Result Evergreen.V388.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) (Result Evergreen.V388.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji (Result Evergreen.V388.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji (Result Evergreen.V388.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji (Result Evergreen.V388.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji (Result Evergreen.V388.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V388.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V388.Discord.HttpError (List ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId, Maybe Evergreen.V388.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Effect.Time.Posix Evergreen.V388.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V388.Slack.CurrentUser
            , team : Evergreen.V388.Slack.Team
            , users : List Evergreen.V388.Slack.User
            , channels : List ( Evergreen.V388.Slack.Channel, List Evergreen.V388.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Result Effect.Http.Error Evergreen.V388.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Discord.UserAuth (Result Evergreen.V388.Discord.HttpError Evergreen.V388.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Result Evergreen.V388.Discord.HttpError Evergreen.V388.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
        (Result
            Evergreen.V388.Discord.HttpError
            { dmChannels :
                List
                    { dmChannelId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId
                    , members : List (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
                    , messages : List Evergreen.V388.Discord.Message
                    }
            , guilds :
                List
                    ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId
                    , { guild : Evergreen.V388.Discord.GatewayGuild
                      , channels : List Evergreen.V388.Discord.Channel
                      , icon : Maybe Evergreen.V388.FileStatus.UploadResponse
                      }
                    )
            , channelMessages : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (List Evergreen.V388.Discord.Message)
            , attachments : List (Result Effect.Http.Error ( Evergreen.V388.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V388.FileStatus.UploadResponse ))
            }
        )
    | WebsocketCreatedHandleForUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V388.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V388.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.AttachmentId, Evergreen.V388.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V388.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.AttachmentId, Evergreen.V388.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V388.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V388.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V388.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V388.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (Result Evergreen.V388.Discord.HttpError Evergreen.V388.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Result Evergreen.V388.Discord.HttpError (List Evergreen.V388.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V388.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V388.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V388.DmChannelId.DmChannelId Evergreen.V388.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V388.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V388.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V388.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
        (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V388.Discord.HttpError
            { guild : Evergreen.V388.Discord.GatewayGuild
            , channels : List Evergreen.V388.Discord.Channel
            , icon : Maybe Evergreen.V388.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Maybe Evergreen.V388.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Result Evergreen.V388.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V388.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V388.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (List ( Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId, Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId, Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (List ( Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V388.Discord.HttpError (List Evergreen.V388.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V388.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V388.SecretId.SecretId Evergreen.V388.SecretId.ServerSecret))
    | DeletedOrphanedFiles Effect.Time.Posix Evergreen.V388.Local.ChangeId Effect.Lamdera.ClientId (List Evergreen.V388.FileStatus.FileHash) (Result Effect.Http.Error ())
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V388.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Result Evergreen.V388.Discord.HttpError ( Evergreen.V388.Discord.Guild, List Evergreen.V388.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V388.FileStatus.FileHash Int (Maybe (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Call.CallId
