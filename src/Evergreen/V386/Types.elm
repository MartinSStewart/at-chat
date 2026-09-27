module Evergreen.V386.Types exposing (..)

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
import Evergreen.V386.AiChat
import Evergreen.V386.Audio
import Evergreen.V386.BackendMsgLog
import Evergreen.V386.Call
import Evergreen.V386.ChannelDescription
import Evergreen.V386.ChannelName
import Evergreen.V386.Coord
import Evergreen.V386.CssPixels
import Evergreen.V386.CustomEmoji
import Evergreen.V386.Discord
import Evergreen.V386.DiscordAttachmentId
import Evergreen.V386.DiscordUserData
import Evergreen.V386.DmChannel
import Evergreen.V386.DmChannelId
import Evergreen.V386.Drawing
import Evergreen.V386.Editable
import Evergreen.V386.EmailAddress
import Evergreen.V386.Embed
import Evergreen.V386.Emoji
import Evergreen.V386.Encryption
import Evergreen.V386.FileStatus
import Evergreen.V386.Game
import Evergreen.V386.Go
import Evergreen.V386.GuildName
import Evergreen.V386.Id
import Evergreen.V386.IdArray
import Evergreen.V386.ImageEditor
import Evergreen.V386.ImageViewer
import Evergreen.V386.LinkedAndOtherDiscordUsers
import Evergreen.V386.Local
import Evergreen.V386.LocalState
import Evergreen.V386.Log
import Evergreen.V386.LoginForm
import Evergreen.V386.MembersAndOwner
import Evergreen.V386.Message
import Evergreen.V386.MessageInput
import Evergreen.V386.MessageView
import Evergreen.V386.MuteSettings
import Evergreen.V386.MyUi
import Evergreen.V386.NonemptyDict
import Evergreen.V386.NonemptySet
import Evergreen.V386.OneOrGreater
import Evergreen.V386.OneToOne
import Evergreen.V386.Pages.Admin
import Evergreen.V386.Pagination
import Evergreen.V386.PersonName
import Evergreen.V386.Ports
import Evergreen.V386.Postmark
import Evergreen.V386.Range
import Evergreen.V386.RateLimit
import Evergreen.V386.RecoveryLogin
import Evergreen.V386.RichText
import Evergreen.V386.Route
import Evergreen.V386.Scroll
import Evergreen.V386.SecretId
import Evergreen.V386.SessionIdHash
import Evergreen.V386.SetViewing
import Evergreen.V386.SheepGame
import Evergreen.V386.Slack
import Evergreen.V386.Sticker
import Evergreen.V386.TextEditor
import Evergreen.V386.ToBackendLog
import Evergreen.V386.Touch
import Evergreen.V386.TwoFactorAuthentication
import Evergreen.V386.Ui.Anim
import Evergreen.V386.User
import Evergreen.V386.UserAgent
import Evergreen.V386.UserColor
import Evergreen.V386.UserSession
import Evergreen.V386.WordSpellingGame
import Evergreen.V386.X25519
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
    | LoginFormMsg Evergreen.V386.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V386.RecoveryLogin.Msg
    | PressedShowLogin
    | PressedHomePagePreview Int
    | AdminPageMsg Evergreen.V386.Pages.Admin.Msg
    | PressedLogOut Evergreen.V386.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V386.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V386.Route.Route
    | SelectedFilesToAttach ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | PressedImportChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | SelectedImportChannelFile (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Effect.File.File
    | GotImportChannelFile
        (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
        { fileName : String
        , json : String
        }
    | PressedLeaveGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
    | PressedBanMember (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | PressedToggleInviteLinkQrCode (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V386.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V386.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V386.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute )
    | CheckedNotificationPermission Evergreen.V386.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V386.NonemptyDict.NonemptyDict Int Evergreen.V386.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V386.NonemptyDict.NonemptyDict Int Evergreen.V386.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRoute Evergreen.V386.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V386.NonemptySet.NonemptySet (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V386.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V386.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V386.AiChat.Msg
    | GameMsg Evergreen.V386.Game.Msg
    | GoSpectatorMsg Evergreen.V386.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V386.Editable.Msg Evergreen.V386.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V386.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) (Maybe Evergreen.V386.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute )
        { fileId : Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute )
        { fileId : Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage Evergreen.V386.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V386.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V386.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V386.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V386.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V386.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V386.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | PressedDisableE2ee (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | TypedPrivateKey (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | SafeAreaInsetsChanged
        { top : Int
        , bottom : Int
        }
    | TextEditorMsg Evergreen.V386.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId
        , otherUserId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V386.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRoute Evergreen.V386.MessageInput.Msg
    | MessageInputMsg Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRoute Evergreen.V386.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V386.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V386.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V386.Range.Range, Evergreen.V386.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V386.Range.Range, Evergreen.V386.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V386.Call.FromJs)
    | VoiceChatMsg Evergreen.V386.Call.Msg
    | PressedChannelHeaderTab Evergreen.V386.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V386.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V386.Audio.LoadError Evergreen.V386.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V386.Id.AnyGuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V386.Id.AnyGuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) Evergreen.V386.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V386.Encryption.FromJs (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V386.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V386.UserSession.UserSession
    , currentlyViewing : Evergreen.V386.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) Evergreen.V386.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.LocalState.DiscordFrontendGuild
    , user : Evergreen.V386.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.User.FrontendUser
    , discordUsers : Evergreen.V386.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V386.SessionIdHash.SessionIdHash Evergreen.V386.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V386.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId) Evergreen.V386.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId) Evergreen.V386.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V386.Call.CallId (Evergreen.V386.NonemptyDict.NonemptyDict ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V386.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V386.Go.PublicGoMatchData Evergreen.V386.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V386.Route.Route
    , windowSize : Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V386.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V386.Audio.LoadError Evergreen.V386.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Encryption.EncryptedData (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)))
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.NonemptyDict.NonemptyDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.Encryption.EncryptedData (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V386.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V386.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V386.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData) (List Evergreen.V386.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V386.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V386.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.ChannelName.ChannelName Evergreen.V386.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.ChannelName.ChannelName Evergreen.V386.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.UserSession.ToBeFilledInByBackend (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
    | Local_BanMember (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V386.GuildName.GuildName (Evergreen.V386.UserSession.ToBeFilledInByBackend (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V386.Id.Viewing_DiscordDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V386.SetViewing.SetViewing
    | Local_SetName Evergreen.V386.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V386.Id.GuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.UserSession.ToBeFilledInByBackend Evergreen.V386.DmChannel.LoadedMessages)
    | Local_LoadThreadMessages Evergreen.V386.Id.GuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.Message.Message Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))))
    | Local_Discord_LoadChannelMessages Evergreen.V386.Id.DiscordGuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))))
    | Local_Discord_LoadThreadMessages Evergreen.V386.Id.DiscordGuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.Message.Message Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))))
    | Local_SetGuildNotificationLevel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V386.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V386.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V386.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.QuestionId Evergreen.V386.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V386.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V386.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V386.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V386.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V386.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V386.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V386.NonemptySet.NonemptySet (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V386.Call.LocalChange
    | Local_Game Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Game.LocalChange
    | Local_Drawing Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Drawing.AnchorType Evergreen.V386.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V386.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V386.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V386.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V386.X25519.PublicKey (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V386.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V386.Id.Viewing_DmId (List ( Evergreen.V386.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V386.FileStatus.FileHash, Evergreen.V386.Encryption.EncryptedData (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)) ))
    | Local_DisableE2ee Evergreen.V386.Id.Viewing_DmId (Evergreen.V386.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V386.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V386.Id.ThreadRouteWithMessage, Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V386.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V386.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V386.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V386.FileStatus.FileHash) (Evergreen.V386.Encryption.EncryptedData (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))) (Evergreen.V386.Encryption.EncryptedData String) Evergreen.V386.Message.ThreadRouteWithRepliedTo
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V386.Id.Viewing_DmId Evergreen.V386.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V386.FileStatus.FileHash) (Evergreen.V386.Encryption.EncryptedData (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)))


type ServerChange
    = Server_SendMessage (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.User.FrontendUser Effect.Time.Posix Evergreen.V386.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V386.RichText.RichText (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))) Evergreen.V386.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId) Evergreen.V386.Sticker.StickerData) (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Game.LoadedMatch)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V386.Id.DiscordGuildOrDmId Evergreen.V386.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V386.RichText.RichText (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))) Evergreen.V386.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId) Evergreen.V386.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.ChannelName.ChannelName Evergreen.V386.ChannelDescription.ChannelDescription
    | Server_ImportedChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.LocalState.FrontendChannel
    | Server_EditChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.ChannelName.ChannelName Evergreen.V386.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.User.FrontendUser
    | Server_MemberLeft (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V386.LocalState.JoinGuildError
            { guildId : Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId
            , guild : Evergreen.V386.LocalState.FrontendGuild
            , owner : Evergreen.V386.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V386.RichText.RichText (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))) (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V386.RichText.RichText (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V386.Id.Viewing_DiscordDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V386.RichText.RichText (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Maybe Evergreen.V386.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Maybe Evergreen.V386.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V386.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V386.SessionIdHash.SessionIdHash Evergreen.V386.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V386.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V386.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V386.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V386.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V386.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Bool Evergreen.V386.ChannelName.ChannelName (Evergreen.V386.Discord.OptionalData (Maybe String)) (List Evergreen.V386.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
        (Evergreen.V386.NonemptyDict.NonemptyDict
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) Evergreen.V386.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Maybe (Evergreen.V386.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V386.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V386.Log.Log
    | Server_BackupGenerated Evergreen.V386.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V386.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V386.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V386.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V386.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.LocalState.DiscordFrontendGuild
    | Server_DiscordGuildLeftOrDeleted (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    | Server_DiscordUpdateChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (Evergreen.V386.Discord.OptionalData (Maybe String)) (Evergreen.V386.Discord.OptionalData (Maybe String)) (List Evergreen.V386.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.GuildName.GuildName (Maybe Evergreen.V386.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId) Evergreen.V386.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId) Evergreen.V386.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
        (Evergreen.V386.MembersAndOwner.MembersAndOwner
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.PersonName.PersonName Evergreen.V386.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId) Evergreen.V386.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId) Evergreen.V386.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V386.Call.ServerChange
    | Server_Game (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Game.LocalChange
    | Server_Drawing (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Drawing.AnchorType Evergreen.V386.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V386.Id.Viewing_DmId ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Evergreen.V386.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V386.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V386.Id.Viewing_DmId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | Server_E2eeAccepted Evergreen.V386.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.User.FrontendUser Effect.Time.Posix Evergreen.V386.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V386.FileStatus.FileHash) (Evergreen.V386.Encryption.EncryptedData (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))) Evergreen.V386.Message.ThreadRouteWithRepliedTo (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Game.LoadedMatch)
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.Viewing_DmId Evergreen.V386.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V386.FileStatus.FileHash) (Evergreen.V386.Encryption.EncryptedData (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V386.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V386.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V386.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V386.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V386.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V386.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V386.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V386.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V386.Id.AnyGuildOrDmId Evergreen.V386.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V386.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels) (Maybe Evergreen.V386.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V386.SheepGame.Input (Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels) (Maybe Evergreen.V386.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V386.Id.GuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.SheepGame.ReactionTarget
    | EmojiSelectorForWordSpellingGameReaction Evergreen.V386.Id.GuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.WordSpellingGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId) (Evergreen.V386.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V386.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V386.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V386.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , threadRoute : Evergreen.V386.Message.ThreadRouteWithRepliedTo
    , contentAndEmbeds : Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V386.Encryption.BytesHash
    , id : Evergreen.V386.Id.Viewing_DmId
    , senderId : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , threadRoute : Evergreen.V386.Message.ThreadRouteWithRepliedTo
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V386.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V386.Id.Viewing_DmId
    , messages : List Evergreen.V386.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V386.Id.Viewing_DmId
    , messages : List ( Evergreen.V386.Id.ThreadRouteWithMessage, Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V386.Id.Viewing_DmId
    , threadRoute : Evergreen.V386.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute )
    , fileId : Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V386.Id.Id Evergreen.V386.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V386.Id.Id Evergreen.V386.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V386.Id.Id Evergreen.V386.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V386.Id.Id Evergreen.V386.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V386.Id.Id Evergreen.V386.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V386.Local.Local LocalMsg Evergreen.V386.LocalState.LocalState
    , admin : Evergreen.V386.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId, Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V386.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V386.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.Message.RepliedTo Evergreen.V386.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V386.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V386.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V386.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.ThreadRoute ) (Evergreen.V386.NonemptyDict.NonemptyDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V386.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V386.Scroll.ScrollPosition
    , textEditor : Evergreen.V386.TextEditor.Model
    , profilePictureEditor : Evergreen.V386.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId, Evergreen.V386.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V386.Emoji.Model
    , voiceChat : Evergreen.V386.Call.Model
    , games : SeqDict.SeqDict Evergreen.V386.Id.GuildOrDmId Evergreen.V386.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V386.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V386.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V386.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V386.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V386.Range.Range
                , direction : Evergreen.V386.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V386.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V386.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V386.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V386.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V386.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V386.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V386.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }
    | ImportChannelResponse
        (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
        (Result
            ImportChannelError
            { encryptedMessages : Int
            }
        )


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V386.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels
    , visualViewportHeight : Int
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V386.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V386.MyUi.LastCopy
    , drag : Evergreen.V386.Touch.Drag
    , dragPrevious : Evergreen.V386.Touch.Drag
    , aiChatModel : Evergreen.V386.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V386.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V386.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V386.Audio.LoadError Evergreen.V386.Audio.Source
    , startupData : Evergreen.V386.Ports.StartupData
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
    Evergreen.V386.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V386.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V386.EmailAddress.EmailAddress
        }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V386.FileStatus.FileHash
    , metadata : Maybe Evergreen.V386.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId, Evergreen.V386.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId, Evergreen.V386.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V386.DmChannelId.DmChannelId, Evergreen.V386.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId, Evergreen.V386.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId, Evergreen.V386.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId, Evergreen.V386.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V386.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V386.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V386.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V386.NonemptyDict.NonemptyDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V386.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V386.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V386.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V386.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V386.DmChannelId.DmChannelId Evergreen.V386.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) Evergreen.V386.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.Slack.Id Evergreen.V386.Slack.ChannelId) Evergreen.V386.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V386.OneToOne.OneToOne String (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    , slackUsers : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.Slack.Id Evergreen.V386.Slack.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    , slackServers : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.Slack.Id Evergreen.V386.Slack.TeamId) (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    , slackToken : Maybe Evergreen.V386.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V386.FileStatus.FileHash Evergreen.V386.FileStatus.BackendFileData
    , privateVapidKey : Evergreen.V386.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V386.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V386.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId, Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V386.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V386.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V386.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V386.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.LocalState.LoadingDiscordChannel Evergreen.V386.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Array.Array Effect.Time.Posix)
    , sessionRateLimits : Evergreen.V386.RateLimit.SessionRateLimits
    , toBackendLogs : Array.Array Evergreen.V386.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V386.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId) Evergreen.V386.Sticker.StickerData
    , discordStickers : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.Discord.Id Evergreen.V386.Discord.StickerId) (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId) Evergreen.V386.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V386.OneToOne.OneToOne Evergreen.V386.RichText.DiscordCustomEmojiIdAndName (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V386.Postmark.ApiKey
    , serverSecret : Evergreen.V386.SecretId.SecretId Evergreen.V386.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V386.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.GamePublicId) ( Evergreen.V386.DmChannelId.GuildOrFullDmId, Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V386.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V386.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V386.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.Id.ThreadRoute (Maybe Evergreen.V386.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V386.DmChannelId.DmChannelId Evergreen.V386.Id.ThreadRoute (Maybe Evergreen.V386.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V386.Id.Id Evergreen.V386.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V386.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V386.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V386.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V386.UserAgent.UserAgent
    | AdminToBackend Evergreen.V386.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V386.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V386.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V386.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V386.PersonName.PersonName Evergreen.V386.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V386.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V386.Slack.OAuthCode Evergreen.V386.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V386.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V386.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V386.Id.Id Evergreen.V386.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V386.Id.ExportChannelId
    | ImportChannelRequest
        (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
        { fileName : String
        , json : String
        }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V386.EmailAddress.EmailAddress (Result Evergreen.V386.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V386.EmailAddress.EmailAddress (Result Evergreen.V386.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V386.EmailAddress.EmailAddress (Result Evergreen.V386.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V386.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMaybeMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Result Evergreen.V386.Discord.HttpError Evergreen.V386.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V386.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Result Evergreen.V386.Discord.HttpError Evergreen.V386.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) (Result Evergreen.V386.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) (Result Evergreen.V386.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) (Result Evergreen.V386.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) (Result Evergreen.V386.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji (Result Evergreen.V386.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji (Result Evergreen.V386.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji (Result Evergreen.V386.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji (Result Evergreen.V386.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V386.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V386.Discord.HttpError (List ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId, Maybe Evergreen.V386.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Effect.Time.Posix Evergreen.V386.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V386.Slack.CurrentUser
            , team : Evergreen.V386.Slack.Team
            , users : List Evergreen.V386.Slack.User
            , channels : List ( Evergreen.V386.Slack.Channel, List Evergreen.V386.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Result Effect.Http.Error Evergreen.V386.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Discord.UserAuth (Result Evergreen.V386.Discord.HttpError Evergreen.V386.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Result Evergreen.V386.Discord.HttpError Evergreen.V386.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
        (Result
            Evergreen.V386.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId
                , members : List (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
                }
            , List
                ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId
                , { guild : Evergreen.V386.Discord.GatewayGuild
                  , channels : List Evergreen.V386.Discord.Channel
                  , icon : Maybe Evergreen.V386.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V386.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V386.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.AttachmentId, Evergreen.V386.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V386.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.AttachmentId, Evergreen.V386.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V386.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V386.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V386.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V386.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (Result Evergreen.V386.Discord.HttpError Evergreen.V386.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Result Evergreen.V386.Discord.HttpError (List Evergreen.V386.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V386.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V386.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V386.DmChannelId.DmChannelId Evergreen.V386.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V386.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V386.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V386.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
        (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V386.Discord.HttpError
            { guild : Evergreen.V386.Discord.GatewayGuild
            , channels : List Evergreen.V386.Discord.Channel
            , icon : Maybe Evergreen.V386.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Maybe Evergreen.V386.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Result Evergreen.V386.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V386.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V386.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (List ( Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId, Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId, Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (List ( Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V386.Discord.HttpError (List Evergreen.V386.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix Int (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V386.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V386.SecretId.SecretId Evergreen.V386.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V386.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Result Evergreen.V386.Discord.HttpError ( Evergreen.V386.Discord.Guild, List Evergreen.V386.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V386.FileStatus.FileHash Int (Maybe (Evergreen.V386.Coord.Coord Evergreen.V386.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Call.CallId
