module Evergreen.V379.Types exposing (..)

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
import Evergreen.V379.AiChat
import Evergreen.V379.Audio
import Evergreen.V379.BackendMsgLog
import Evergreen.V379.Call
import Evergreen.V379.ChannelDescription
import Evergreen.V379.ChannelName
import Evergreen.V379.Coord
import Evergreen.V379.CssPixels
import Evergreen.V379.CustomEmoji
import Evergreen.V379.Discord
import Evergreen.V379.DiscordAttachmentId
import Evergreen.V379.DiscordUserData
import Evergreen.V379.DmChannel
import Evergreen.V379.DmChannelId
import Evergreen.V379.Drawing
import Evergreen.V379.Editable
import Evergreen.V379.EmailAddress
import Evergreen.V379.Embed
import Evergreen.V379.Emoji
import Evergreen.V379.Encryption
import Evergreen.V379.FileStatus
import Evergreen.V379.Game
import Evergreen.V379.Go
import Evergreen.V379.GuildName
import Evergreen.V379.Id
import Evergreen.V379.IdArray
import Evergreen.V379.ImageEditor
import Evergreen.V379.ImageViewer
import Evergreen.V379.LinkedAndOtherDiscordUsers
import Evergreen.V379.Local
import Evergreen.V379.LocalState
import Evergreen.V379.Log
import Evergreen.V379.LoginForm
import Evergreen.V379.MembersAndOwner
import Evergreen.V379.Message
import Evergreen.V379.MessageInput
import Evergreen.V379.MessageView
import Evergreen.V379.MuteSettings
import Evergreen.V379.MyUi
import Evergreen.V379.NonemptyDict
import Evergreen.V379.NonemptySet
import Evergreen.V379.OneOrGreater
import Evergreen.V379.OneToOne
import Evergreen.V379.Pages.Admin
import Evergreen.V379.Pagination
import Evergreen.V379.PersonName
import Evergreen.V379.Ports
import Evergreen.V379.Postmark
import Evergreen.V379.Range
import Evergreen.V379.RecoveryLogin
import Evergreen.V379.RichText
import Evergreen.V379.Route
import Evergreen.V379.Scroll
import Evergreen.V379.SecretId
import Evergreen.V379.SessionIdHash
import Evergreen.V379.SheepGame
import Evergreen.V379.Slack
import Evergreen.V379.Sticker
import Evergreen.V379.TextEditor
import Evergreen.V379.ToBackendLog
import Evergreen.V379.Touch
import Evergreen.V379.TwoFactorAuthentication
import Evergreen.V379.Ui.Anim
import Evergreen.V379.User
import Evergreen.V379.UserAgent
import Evergreen.V379.UserColor
import Evergreen.V379.UserSession
import Evergreen.V379.WordSpellingGame
import Evergreen.V379.X25519
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
    | LoginFormMsg Evergreen.V379.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V379.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V379.Pages.Admin.Msg
    | PressedLogOut Evergreen.V379.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V379.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V379.Route.Route
    | SelectedFilesToAttach ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V379.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V379.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V379.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V379.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V379.NonemptyDict.NonemptyDict Int Evergreen.V379.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V379.NonemptyDict.NonemptyDict Int Evergreen.V379.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRoute Evergreen.V379.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V379.NonemptySet.NonemptySet (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V379.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V379.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V379.AiChat.Msg
    | GameMsg Evergreen.V379.Game.Msg
    | GoSpectatorMsg Evergreen.V379.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V379.Editable.Msg Evergreen.V379.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V379.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) (Maybe Evergreen.V379.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute )
        { fileId : Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute )
        { fileId : Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage Evergreen.V379.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V379.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V379.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V379.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V379.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V379.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V379.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | PressedDisableE2ee (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | TypedPrivateKey (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V379.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId
        , otherUserId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V379.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRoute Evergreen.V379.MessageInput.Msg
    | MessageInputMsg Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRoute Evergreen.V379.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V379.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V379.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V379.Range.Range, Evergreen.V379.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V379.Range.Range, Evergreen.V379.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V379.Call.FromJs)
    | VoiceChatMsg Evergreen.V379.Call.Msg
    | PressedChannelHeaderTab Evergreen.V379.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V379.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V379.Audio.LoadError Evergreen.V379.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V379.Id.AnyGuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V379.Id.AnyGuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) Evergreen.V379.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V379.Encryption.FromJs (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V379.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V379.UserSession.UserSession
    , currentlyViewing : Evergreen.V379.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) Evergreen.V379.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.LocalState.DiscordFrontendGuild
    , user : Evergreen.V379.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.User.FrontendUser
    , discordUsers : Evergreen.V379.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V379.SessionIdHash.SessionIdHash Evergreen.V379.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V379.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId) Evergreen.V379.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId) Evergreen.V379.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V379.Call.CallId (Evergreen.V379.NonemptyDict.NonemptyDict ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V379.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V379.Go.PublicGoMatchData Evergreen.V379.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V379.Route.Route
    , windowSize : Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V379.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V379.Audio.LoadError Evergreen.V379.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Encryption.EncryptedData (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.NonemptyDict.NonemptyDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) (Evergreen.V379.Encryption.EncryptedData (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V379.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V379.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V379.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData) (List Evergreen.V379.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V379.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V379.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.ChannelName.ChannelName Evergreen.V379.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.ChannelName.ChannelName Evergreen.V379.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V379.GuildName.GuildName (Evergreen.V379.UserSession.ToBeFilledInByBackend (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V379.Id.Viewing_DiscordDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V379.UserSession.SetViewing
    | Local_SetName Evergreen.V379.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V379.Id.GuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V379.Id.GuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) (Evergreen.V379.Message.Message Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V379.Id.DiscordGuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V379.Id.DiscordGuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) (Evergreen.V379.Message.Message Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V379.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V379.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V379.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.QuestionId Evergreen.V379.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V379.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V379.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V379.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V379.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V379.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V379.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V379.NonemptySet.NonemptySet (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V379.Call.LocalChange
    | Local_Game Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Game.LocalChange
    | Local_Drawing Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Drawing.AnchorType Evergreen.V379.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V379.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V379.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V379.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V379.X25519.PublicKey (Evergreen.V379.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V379.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V379.Id.Viewing_DmId (List ( Evergreen.V379.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V379.FileStatus.FileHash, Evergreen.V379.Encryption.EncryptedData (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V379.Id.Viewing_DmId (Evergreen.V379.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V379.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V379.Id.ThreadRouteWithMessage, Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V379.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V379.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V379.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V379.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V379.FileStatus.FileHash) (Evergreen.V379.Encryption.EncryptedData (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))) (Evergreen.V379.Encryption.EncryptedData String) Evergreen.V379.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V379.Id.Viewing_DmId Evergreen.V379.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V379.FileStatus.FileHash) (Evergreen.V379.Encryption.EncryptedData (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.User.FrontendUser Effect.Time.Posix Evergreen.V379.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V379.RichText.RichText (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))) Evergreen.V379.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId) Evergreen.V379.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V379.Id.DiscordGuildOrDmId Evergreen.V379.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V379.RichText.RichText (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))) Evergreen.V379.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId) Evergreen.V379.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.ChannelName.ChannelName Evergreen.V379.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.ChannelName.ChannelName Evergreen.V379.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.User.FrontendUser
    | Server_MemberLeft (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V379.LocalState.JoinGuildError
            { guildId : Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId
            , guild : Evergreen.V379.LocalState.FrontendGuild
            , owner : Evergreen.V379.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V379.RichText.RichText (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))) (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V379.RichText.RichText (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V379.Id.Viewing_DiscordDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V379.RichText.RichText (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Maybe Evergreen.V379.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Maybe Evergreen.V379.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V379.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V379.SessionIdHash.SessionIdHash Evergreen.V379.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V379.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V379.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V379.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V379.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V379.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Bool Evergreen.V379.ChannelName.ChannelName (Evergreen.V379.Discord.OptionalData (Maybe String)) (List Evergreen.V379.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
        (Evergreen.V379.NonemptyDict.NonemptyDict
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) Evergreen.V379.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Maybe (Evergreen.V379.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V379.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V379.Log.Log
    | Server_BackupGenerated Evergreen.V379.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V379.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V379.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V379.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V379.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (Evergreen.V379.Discord.OptionalData (Maybe String)) (Evergreen.V379.Discord.OptionalData (Maybe String)) (List Evergreen.V379.Discord.Overwrite)
    | Server_DiscordUpdateGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.GuildName.GuildName (Maybe Evergreen.V379.FileStatus.FileHash) (SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId) Evergreen.V379.LocalState.DiscordRole)
    | Server_DiscordUpdateRole (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId) Evergreen.V379.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
        (Evergreen.V379.MembersAndOwner.MembersAndOwner
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.PersonName.PersonName Evergreen.V379.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId) Evergreen.V379.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId) Evergreen.V379.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V379.Call.ServerChange
    | Server_Game (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Game.LocalChange
    | Server_Drawing (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Drawing.AnchorType Evergreen.V379.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V379.Id.Viewing_DmId ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Evergreen.V379.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V379.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V379.Id.Viewing_DmId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | Server_E2eeAccepted Evergreen.V379.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.User.FrontendUser Effect.Time.Posix Evergreen.V379.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V379.FileStatus.FileHash) (Evergreen.V379.Encryption.EncryptedData (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))) Evergreen.V379.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.Viewing_DmId Evergreen.V379.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V379.FileStatus.FileHash) (Evergreen.V379.Encryption.EncryptedData (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V379.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V379.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V379.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V379.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V379.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V379.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V379.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V379.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V379.Id.AnyGuildOrDmId Evergreen.V379.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V379.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels) (Maybe Evergreen.V379.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V379.SheepGame.Input (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels) (Maybe Evergreen.V379.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V379.Id.GuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId) (Evergreen.V379.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V379.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V379.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V379.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , threadRoute : Evergreen.V379.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V379.Encryption.BytesHash
    , id : Evergreen.V379.Id.Viewing_DmId
    , senderId : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , threadRoute : Evergreen.V379.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V379.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V379.Id.Viewing_DmId
    , messages : List Evergreen.V379.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V379.Id.Viewing_DmId
    , messages : List ( Evergreen.V379.Id.ThreadRouteWithMessage, Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V379.Id.Viewing_DmId
    , threadRoute : Evergreen.V379.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute )
    , fileId : Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V379.Id.Id Evergreen.V379.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V379.Id.Id Evergreen.V379.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V379.Id.Id Evergreen.V379.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V379.Id.Id Evergreen.V379.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V379.Id.Id Evergreen.V379.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V379.Local.Local LocalMsg Evergreen.V379.LocalState.LocalState
    , admin : Evergreen.V379.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId, Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V379.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V379.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V379.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V379.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V379.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.ThreadRoute ) (Evergreen.V379.NonemptyDict.NonemptyDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V379.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V379.Scroll.ScrollPosition
    , textEditor : Evergreen.V379.TextEditor.Model
    , profilePictureEditor : Evergreen.V379.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId, Evergreen.V379.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V379.Emoji.Model
    , voiceChat : Evergreen.V379.Call.Model
    , games : SeqDict.SeqDict Evergreen.V379.Id.GuildOrDmId Evergreen.V379.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V379.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V379.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V379.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V379.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V379.Range.Range
                , direction : Evergreen.V379.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V379.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V379.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V379.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V379.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V379.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V379.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V379.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V379.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V379.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V379.MyUi.LastCopy
    , drag : Evergreen.V379.Touch.Drag
    , dragPrevious : Evergreen.V379.Touch.Drag
    , aiChatModel : Evergreen.V379.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V379.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V379.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V379.Audio.LoadError Evergreen.V379.Audio.Source
    , startupData : Evergreen.V379.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V379.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V379.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V379.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V379.FileStatus.FileHash
    , metadata : Maybe Evergreen.V379.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId, Evergreen.V379.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId, Evergreen.V379.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V379.DmChannelId.DmChannelId, Evergreen.V379.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId, Evergreen.V379.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId, Evergreen.V379.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId, Evergreen.V379.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V379.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V379.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V379.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V379.NonemptyDict.NonemptyDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V379.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V379.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V379.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V379.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V379.DmChannelId.DmChannelId Evergreen.V379.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) Evergreen.V379.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.Slack.Id Evergreen.V379.Slack.ChannelId) Evergreen.V379.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V379.OneToOne.OneToOne String (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    , slackUsers : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.Slack.Id Evergreen.V379.Slack.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    , slackServers : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.Slack.Id Evergreen.V379.Slack.TeamId) (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    , slackToken : Maybe Evergreen.V379.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V379.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V379.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V379.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V379.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId, Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V379.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V379.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V379.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V379.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.LocalState.LoadingDiscordChannel Evergreen.V379.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V379.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V379.BackendMsgLog.BackendMsgLogData
    , stickers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId) Evergreen.V379.Sticker.StickerData
    , discordStickers : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.Discord.Id Evergreen.V379.Discord.StickerId) (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId) Evergreen.V379.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V379.OneToOne.OneToOne Evergreen.V379.RichText.DiscordCustomEmojiIdAndName (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V379.Postmark.ApiKey
    , serverSecret : Evergreen.V379.SecretId.SecretId Evergreen.V379.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V379.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.GamePublicId) ( Evergreen.V379.DmChannelId.GuildOrFullDmId, Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V379.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V379.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V379.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.Id.ThreadRoute (Maybe Evergreen.V379.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V379.DmChannelId.DmChannelId Evergreen.V379.Id.ThreadRoute (Maybe Evergreen.V379.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V379.Id.Id Evergreen.V379.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V379.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V379.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V379.EmailAddress.EmailAddress
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V379.UserAgent.UserAgent
    | AdminToBackend Evergreen.V379.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V379.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V379.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V379.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V379.PersonName.PersonName Evergreen.V379.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V379.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V379.Slack.OAuthCode Evergreen.V379.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V379.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V379.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V379.Id.Id Evergreen.V379.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V379.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V379.EmailAddress.EmailAddress (Result Evergreen.V379.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V379.EmailAddress.EmailAddress (Result Evergreen.V379.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V379.EmailAddress.EmailAddress (Result Evergreen.V379.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V379.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMaybeMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Result Evergreen.V379.Discord.HttpError Evergreen.V379.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V379.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Result Evergreen.V379.Discord.HttpError Evergreen.V379.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) (Result Evergreen.V379.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) (Result Evergreen.V379.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) (Result Evergreen.V379.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) (Result Evergreen.V379.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji (Result Evergreen.V379.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji (Result Evergreen.V379.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji (Result Evergreen.V379.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji (Result Evergreen.V379.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V379.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V379.Discord.HttpError (List ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId, Maybe Evergreen.V379.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Effect.Time.Posix Evergreen.V379.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V379.Slack.CurrentUser
            , team : Evergreen.V379.Slack.Team
            , users : List Evergreen.V379.Slack.User
            , channels : List ( Evergreen.V379.Slack.Channel, List Evergreen.V379.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Result Effect.Http.Error Evergreen.V379.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Discord.UserAuth (Result Evergreen.V379.Discord.HttpError Evergreen.V379.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Result Evergreen.V379.Discord.HttpError Evergreen.V379.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
        (Result
            Evergreen.V379.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId
                , members : List (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
                }
            , List
                ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId
                , { guild : Evergreen.V379.Discord.GatewayGuild
                  , channels : List Evergreen.V379.Discord.Channel
                  , icon : Maybe Evergreen.V379.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V379.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V379.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.AttachmentId, Evergreen.V379.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V379.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.AttachmentId, Evergreen.V379.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V379.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V379.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V379.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V379.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (Result Evergreen.V379.Discord.HttpError Evergreen.V379.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Result Evergreen.V379.Discord.HttpError (List Evergreen.V379.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V379.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V379.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V379.DmChannelId.DmChannelId Evergreen.V379.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V379.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V379.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V379.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
        (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V379.Discord.HttpError
            { guild : Evergreen.V379.Discord.GatewayGuild
            , channels : List Evergreen.V379.Discord.Channel
            , icon : Maybe Evergreen.V379.FileStatus.UploadResponse
            }
        )
    | DiscordGotGuildIcon (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Maybe Evergreen.V379.FileStatus.UploadResponse)
    | JoinedDiscordThread (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Result Evergreen.V379.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V379.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotTimeForBackendMsg Effect.Time.Posix BackendMsg
    | BackendMsgCompleted
        Evergreen.V379.BackendMsgLog.BackendMsgLog
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (List ( Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId, Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId, Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (List ( Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V379.Discord.HttpError (List Evergreen.V379.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V379.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V379.SecretId.SecretId Evergreen.V379.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V379.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Result Evergreen.V379.Discord.HttpError ( Evergreen.V379.Discord.Guild, List Evergreen.V379.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V379.FileStatus.FileHash Int (Maybe (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Call.CallId
