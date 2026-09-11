module Evergreen.V378.Types exposing (..)

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
import Evergreen.V378.AiChat
import Evergreen.V378.Audio
import Evergreen.V378.BackendMsgLog
import Evergreen.V378.Call
import Evergreen.V378.ChannelDescription
import Evergreen.V378.ChannelName
import Evergreen.V378.Coord
import Evergreen.V378.CssPixels
import Evergreen.V378.CustomEmoji
import Evergreen.V378.Discord
import Evergreen.V378.DiscordAttachmentId
import Evergreen.V378.DiscordUserData
import Evergreen.V378.DmChannel
import Evergreen.V378.DmChannelId
import Evergreen.V378.Drawing
import Evergreen.V378.Editable
import Evergreen.V378.EmailAddress
import Evergreen.V378.Embed
import Evergreen.V378.Emoji
import Evergreen.V378.Encryption
import Evergreen.V378.FileStatus
import Evergreen.V378.Game
import Evergreen.V378.Go
import Evergreen.V378.GuildName
import Evergreen.V378.Id
import Evergreen.V378.IdArray
import Evergreen.V378.ImageEditor
import Evergreen.V378.ImageViewer
import Evergreen.V378.LinkedAndOtherDiscordUsers
import Evergreen.V378.Local
import Evergreen.V378.LocalState
import Evergreen.V378.Log
import Evergreen.V378.LoginForm
import Evergreen.V378.MembersAndOwner
import Evergreen.V378.Message
import Evergreen.V378.MessageInput
import Evergreen.V378.MessageView
import Evergreen.V378.MuteSettings
import Evergreen.V378.MyUi
import Evergreen.V378.NonemptyDict
import Evergreen.V378.NonemptySet
import Evergreen.V378.OneOrGreater
import Evergreen.V378.OneToOne
import Evergreen.V378.Pages.Admin
import Evergreen.V378.Pagination
import Evergreen.V378.PersonName
import Evergreen.V378.Ports
import Evergreen.V378.Postmark
import Evergreen.V378.Range
import Evergreen.V378.RecoveryLogin
import Evergreen.V378.RichText
import Evergreen.V378.Route
import Evergreen.V378.Scroll
import Evergreen.V378.SecretId
import Evergreen.V378.SessionIdHash
import Evergreen.V378.SheepGame
import Evergreen.V378.Slack
import Evergreen.V378.Sticker
import Evergreen.V378.TextEditor
import Evergreen.V378.ToBackendLog
import Evergreen.V378.Touch
import Evergreen.V378.TwoFactorAuthentication
import Evergreen.V378.Ui.Anim
import Evergreen.V378.Untrusted
import Evergreen.V378.User
import Evergreen.V378.UserAgent
import Evergreen.V378.UserColor
import Evergreen.V378.UserSession
import Evergreen.V378.WordSpellingGame
import Evergreen.V378.X25519
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


type alias EditGuildForm =
    { name : String
    , deleteConfirmation : String
    , showDeleteConfirmation : Bool
    , showLeaveConfirmation : Bool
    , pressedSubmit : Bool
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
    | LoginFormMsg Evergreen.V378.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V378.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V378.Pages.Admin.Msg
    | PressedLogOut Evergreen.V378.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V378.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V378.Route.Route
    | SelectedFilesToAttach ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V378.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V378.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V378.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V378.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V378.NonemptyDict.NonemptyDict Int Evergreen.V378.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V378.NonemptyDict.NonemptyDict Int Evergreen.V378.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRoute Evergreen.V378.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V378.NonemptySet.NonemptySet (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V378.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V378.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V378.AiChat.Msg
    | GameMsg Evergreen.V378.Game.Msg
    | GoSpectatorMsg Evergreen.V378.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V378.Editable.Msg Evergreen.V378.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V378.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) (Maybe Evergreen.V378.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute )
        { fileId : Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute )
        { fileId : Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage Evergreen.V378.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V378.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V378.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V378.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V378.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V378.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V378.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | PressedDisableE2ee (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | TypedPrivateKey (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V378.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId
        , otherUserId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V378.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRoute Evergreen.V378.MessageInput.Msg
    | MessageInputMsg Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRoute Evergreen.V378.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V378.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V378.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V378.Range.Range, Evergreen.V378.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V378.Range.Range, Evergreen.V378.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V378.Call.FromJs)
    | VoiceChatMsg Evergreen.V378.Call.Msg
    | PressedChannelHeaderTab Evergreen.V378.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V378.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V378.Audio.LoadError Evergreen.V378.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V378.Id.AnyGuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V378.Id.AnyGuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) Evergreen.V378.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V378.Encryption.FromJs (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V378.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V378.UserSession.UserSession
    , currentlyViewing : Evergreen.V378.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) Evergreen.V378.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.LocalState.DiscordFrontendGuild
    , user : Evergreen.V378.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.User.FrontendUser
    , discordUsers : Evergreen.V378.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V378.SessionIdHash.SessionIdHash Evergreen.V378.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V378.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId) Evergreen.V378.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId) Evergreen.V378.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V378.Call.CallId (Evergreen.V378.NonemptyDict.NonemptyDict ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V378.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V378.Go.PublicGoMatchData Evergreen.V378.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V378.Route.Route
    , windowSize : Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V378.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V378.Audio.LoadError Evergreen.V378.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Encryption.EncryptedData (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.NonemptyDict.NonemptyDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) (Evergreen.V378.Encryption.EncryptedData (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V378.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V378.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V378.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileData) (List Evergreen.V378.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V378.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V378.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.ChannelName.ChannelName Evergreen.V378.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.ChannelName.ChannelName Evergreen.V378.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V378.GuildName.GuildName (Evergreen.V378.UserSession.ToBeFilledInByBackend (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V378.Id.Viewing_DiscordDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V378.UserSession.SetViewing
    | Local_SetName Evergreen.V378.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V378.Id.GuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V378.Id.GuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) (Evergreen.V378.Message.Message Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V378.Id.DiscordGuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V378.Id.DiscordGuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) (Evergreen.V378.Message.Message Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V378.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V378.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V378.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.QuestionId Evergreen.V378.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V378.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V378.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V378.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V378.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V378.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V378.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V378.NonemptySet.NonemptySet (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V378.Call.LocalChange
    | Local_Game Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Game.LocalChange
    | Local_Drawing Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Drawing.AnchorType Evergreen.V378.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V378.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V378.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V378.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V378.X25519.PublicKey (Evergreen.V378.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V378.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V378.Id.Viewing_DmId (List ( Evergreen.V378.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V378.FileStatus.FileHash, Evergreen.V378.Encryption.EncryptedData (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V378.Id.Viewing_DmId (Evergreen.V378.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V378.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V378.Id.ThreadRouteWithMessage, Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V378.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V378.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V378.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V378.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V378.FileStatus.FileHash) (Evergreen.V378.Encryption.EncryptedData (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))) (Evergreen.V378.Encryption.EncryptedData String) Evergreen.V378.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V378.Id.Viewing_DmId Evergreen.V378.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V378.FileStatus.FileHash) (Evergreen.V378.Encryption.EncryptedData (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.User.FrontendUser Effect.Time.Posix Evergreen.V378.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V378.RichText.RichText (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))) Evergreen.V378.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId) Evergreen.V378.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V378.Id.DiscordGuildOrDmId Evergreen.V378.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V378.RichText.RichText (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))) Evergreen.V378.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId) Evergreen.V378.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.ChannelName.ChannelName Evergreen.V378.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.ChannelName.ChannelName Evergreen.V378.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.User.FrontendUser
    | Server_MemberLeft (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V378.LocalState.JoinGuildError
            { guildId : Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId
            , guild : Evergreen.V378.LocalState.FrontendGuild
            , owner : Evergreen.V378.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V378.RichText.RichText (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))) (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V378.RichText.RichText (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V378.Id.Viewing_DiscordDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V378.RichText.RichText (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Maybe Evergreen.V378.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Maybe Evergreen.V378.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V378.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V378.SessionIdHash.SessionIdHash Evergreen.V378.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V378.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V378.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V378.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V378.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V378.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Bool Evergreen.V378.ChannelName.ChannelName (Evergreen.V378.Discord.OptionalData (Maybe String)) (List Evergreen.V378.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
        (Evergreen.V378.NonemptyDict.NonemptyDict
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) Evergreen.V378.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Maybe (Evergreen.V378.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V378.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V378.Log.Log
    | Server_BackupGenerated Evergreen.V378.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V378.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V378.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V378.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V378.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (Evergreen.V378.Discord.OptionalData (Maybe String)) (Evergreen.V378.Discord.OptionalData (Maybe String)) (List Evergreen.V378.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.GuildName.GuildName (Maybe Evergreen.V378.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId) Evergreen.V378.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId) Evergreen.V378.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
        (Evergreen.V378.MembersAndOwner.MembersAndOwner
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.PersonName.PersonName Evergreen.V378.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId) Evergreen.V378.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId) Evergreen.V378.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V378.Call.ServerChange
    | Server_Game (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Game.LocalChange
    | Server_Drawing (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Drawing.AnchorType Evergreen.V378.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V378.Id.Viewing_DmId ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Evergreen.V378.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V378.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V378.Id.Viewing_DmId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | Server_E2eeAccepted Evergreen.V378.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.User.FrontendUser Effect.Time.Posix Evergreen.V378.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V378.FileStatus.FileHash) (Evergreen.V378.Encryption.EncryptedData (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))) Evergreen.V378.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.Viewing_DmId Evergreen.V378.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V378.FileStatus.FileHash) (Evergreen.V378.Encryption.EncryptedData (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V378.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V378.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V378.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V378.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V378.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V378.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V378.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V378.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V378.Id.AnyGuildOrDmId Evergreen.V378.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V378.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels) (Maybe Evergreen.V378.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V378.SheepGame.Input (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels) (Maybe Evergreen.V378.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V378.Id.GuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId) (Evergreen.V378.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V378.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V378.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V378.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , threadRoute : Evergreen.V378.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V378.Encryption.BytesHash
    , id : Evergreen.V378.Id.Viewing_DmId
    , senderId : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , threadRoute : Evergreen.V378.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V378.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V378.Id.Viewing_DmId
    , messages : List Evergreen.V378.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V378.Id.Viewing_DmId
    , messages : List ( Evergreen.V378.Id.ThreadRouteWithMessage, Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V378.Id.Viewing_DmId
    , threadRoute : Evergreen.V378.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute )
    , fileId : Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V378.Id.Id Evergreen.V378.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V378.Id.Id Evergreen.V378.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V378.Id.Id Evergreen.V378.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V378.Id.Id Evergreen.V378.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V378.Id.Id Evergreen.V378.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V378.Local.Local LocalMsg Evergreen.V378.LocalState.LocalState
    , admin : Evergreen.V378.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId, Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V378.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V378.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V378.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V378.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V378.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.ThreadRoute ) (Evergreen.V378.NonemptyDict.NonemptyDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V378.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V378.Scroll.ScrollPosition
    , textEditor : Evergreen.V378.TextEditor.Model
    , profilePictureEditor : Evergreen.V378.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId, Evergreen.V378.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V378.Emoji.Model
    , voiceChat : Evergreen.V378.Call.Model
    , games : SeqDict.SeqDict Evergreen.V378.Id.GuildOrDmId Evergreen.V378.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V378.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V378.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V378.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V378.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V378.Range.Range
                , direction : Evergreen.V378.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V378.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V378.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V378.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V378.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V378.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V378.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V378.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V378.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V378.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V378.MyUi.LastCopy
    , drag : Evergreen.V378.Touch.Drag
    , dragPrevious : Evergreen.V378.Touch.Drag
    , aiChatModel : Evergreen.V378.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V378.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V378.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V378.Audio.LoadError Evergreen.V378.Audio.Source
    , startupData : Evergreen.V378.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V378.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V378.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V378.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V378.FileStatus.FileHash
    , metadata : Maybe Evergreen.V378.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId, Evergreen.V378.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId, Evergreen.V378.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V378.DmChannelId.DmChannelId, Evergreen.V378.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId, Evergreen.V378.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId, Evergreen.V378.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId, Evergreen.V378.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V378.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V378.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V378.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V378.NonemptyDict.NonemptyDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V378.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V378.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V378.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V378.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V378.DmChannelId.DmChannelId Evergreen.V378.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) Evergreen.V378.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.Slack.Id Evergreen.V378.Slack.ChannelId) Evergreen.V378.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V378.OneToOne.OneToOne String (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    , slackUsers : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.Slack.Id Evergreen.V378.Slack.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    , slackServers : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.Slack.Id Evergreen.V378.Slack.TeamId) (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    , slackToken : Maybe Evergreen.V378.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V378.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V378.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V378.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V378.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId, Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V378.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V378.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V378.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V378.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.LocalState.LoadingDiscordChannel Evergreen.V378.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V378.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V378.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId) Evergreen.V378.Sticker.StickerData
    , discordStickers : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.Discord.Id Evergreen.V378.Discord.StickerId) (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId) Evergreen.V378.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V378.OneToOne.OneToOne Evergreen.V378.RichText.DiscordCustomEmojiIdAndName (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V378.Postmark.ApiKey
    , serverSecret : Evergreen.V378.SecretId.SecretId Evergreen.V378.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V378.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.GamePublicId) ( Evergreen.V378.DmChannelId.GuildOrFullDmId, Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V378.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V378.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V378.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.Id.ThreadRoute (Maybe Evergreen.V378.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V378.DmChannelId.DmChannelId Evergreen.V378.Id.ThreadRoute (Maybe Evergreen.V378.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V378.Id.Id Evergreen.V378.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V378.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V378.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V378.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V378.Untrusted.Untrusted Evergreen.V378.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V378.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V378.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V378.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V378.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V378.PersonName.PersonName Evergreen.V378.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V378.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V378.Slack.OAuthCode Evergreen.V378.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V378.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V378.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V378.Id.Id Evergreen.V378.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V378.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V378.EmailAddress.EmailAddress (Result Evergreen.V378.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V378.EmailAddress.EmailAddress (Result Evergreen.V378.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V378.EmailAddress.EmailAddress (Result Evergreen.V378.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V378.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMaybeMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Result Evergreen.V378.Discord.HttpError Evergreen.V378.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V378.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Result Evergreen.V378.Discord.HttpError Evergreen.V378.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) (Result Evergreen.V378.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) (Result Evergreen.V378.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) (Result Evergreen.V378.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) (Result Evergreen.V378.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji (Result Evergreen.V378.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji (Result Evergreen.V378.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji (Result Evergreen.V378.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji (Result Evergreen.V378.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V378.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V378.Discord.HttpError (List ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId, Maybe Evergreen.V378.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Effect.Time.Posix Evergreen.V378.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V378.Slack.CurrentUser
            , team : Evergreen.V378.Slack.Team
            , users : List Evergreen.V378.Slack.User
            , channels : List ( Evergreen.V378.Slack.Channel, List Evergreen.V378.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Result Effect.Http.Error Evergreen.V378.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Discord.UserAuth (Result Evergreen.V378.Discord.HttpError Evergreen.V378.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Result Evergreen.V378.Discord.HttpError Evergreen.V378.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
        (Result
            Evergreen.V378.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId
                , members : List (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
                }
            , List
                ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId
                , { guild : Evergreen.V378.Discord.GatewayGuild
                  , channels : List Evergreen.V378.Discord.Channel
                  , icon : Maybe Evergreen.V378.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V378.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V378.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.AttachmentId, Evergreen.V378.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V378.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.AttachmentId, Evergreen.V378.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V378.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V378.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V378.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V378.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (Result Evergreen.V378.Discord.HttpError Evergreen.V378.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Result Evergreen.V378.Discord.HttpError (List Evergreen.V378.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V378.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V378.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V378.DmChannelId.DmChannelId Evergreen.V378.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V378.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V378.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V378.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
        (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V378.Discord.HttpError
            { guild : Evergreen.V378.Discord.GatewayGuild
            , channels : List Evergreen.V378.Discord.Channel
            , icon : Maybe Evergreen.V378.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Maybe Evergreen.V378.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Result Evergreen.V378.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V378.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V378.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (List ( Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId, Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId, Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (List ( Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V378.Discord.HttpError (List Evergreen.V378.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V378.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V378.SecretId.SecretId Evergreen.V378.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V378.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Result Evergreen.V378.Discord.HttpError ( Evergreen.V378.Discord.Guild, List Evergreen.V378.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V378.FileStatus.FileHash Int (Maybe (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Call.CallId
