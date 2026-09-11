module Evergreen.V377.Types exposing (..)

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
import Evergreen.V377.AiChat
import Evergreen.V377.Audio
import Evergreen.V377.Call
import Evergreen.V377.ChannelDescription
import Evergreen.V377.ChannelName
import Evergreen.V377.Coord
import Evergreen.V377.CssPixels
import Evergreen.V377.CustomEmoji
import Evergreen.V377.Discord
import Evergreen.V377.DiscordAttachmentId
import Evergreen.V377.DiscordUserData
import Evergreen.V377.DmChannel
import Evergreen.V377.DmChannelId
import Evergreen.V377.Drawing
import Evergreen.V377.Editable
import Evergreen.V377.EmailAddress
import Evergreen.V377.Embed
import Evergreen.V377.Emoji
import Evergreen.V377.Encryption
import Evergreen.V377.FileStatus
import Evergreen.V377.Game
import Evergreen.V377.Go
import Evergreen.V377.GuildName
import Evergreen.V377.Id
import Evergreen.V377.IdArray
import Evergreen.V377.ImageEditor
import Evergreen.V377.ImageViewer
import Evergreen.V377.LinkedAndOtherDiscordUsers
import Evergreen.V377.Local
import Evergreen.V377.LocalState
import Evergreen.V377.Log
import Evergreen.V377.LoginForm
import Evergreen.V377.MembersAndOwner
import Evergreen.V377.Message
import Evergreen.V377.MessageInput
import Evergreen.V377.MessageView
import Evergreen.V377.MuteSettings
import Evergreen.V377.MyUi
import Evergreen.V377.NonemptyDict
import Evergreen.V377.NonemptySet
import Evergreen.V377.OneOrGreater
import Evergreen.V377.OneToOne
import Evergreen.V377.Pages.Admin
import Evergreen.V377.Pagination
import Evergreen.V377.PersonName
import Evergreen.V377.Ports
import Evergreen.V377.Postmark
import Evergreen.V377.Range
import Evergreen.V377.RecoveryLogin
import Evergreen.V377.RichText
import Evergreen.V377.Route
import Evergreen.V377.Scroll
import Evergreen.V377.SecretId
import Evergreen.V377.SessionIdHash
import Evergreen.V377.SheepGame
import Evergreen.V377.Slack
import Evergreen.V377.Sticker
import Evergreen.V377.TextEditor
import Evergreen.V377.ToBackendLog
import Evergreen.V377.Touch
import Evergreen.V377.TwoFactorAuthentication
import Evergreen.V377.Ui.Anim
import Evergreen.V377.Untrusted
import Evergreen.V377.User
import Evergreen.V377.UserAgent
import Evergreen.V377.UserColor
import Evergreen.V377.UserSession
import Evergreen.V377.WordSpellingGame
import Evergreen.V377.X25519
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
    | LoginFormMsg Evergreen.V377.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V377.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V377.Pages.Admin.Msg
    | PressedLogOut Evergreen.V377.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V377.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V377.Route.Route
    | SelectedFilesToAttach ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V377.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V377.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V377.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V377.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V377.NonemptyDict.NonemptyDict Int Evergreen.V377.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V377.NonemptyDict.NonemptyDict Int Evergreen.V377.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRoute Evergreen.V377.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V377.NonemptySet.NonemptySet (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V377.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V377.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V377.AiChat.Msg
    | GameMsg Evergreen.V377.Game.Msg
    | GoSpectatorMsg Evergreen.V377.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V377.Editable.Msg Evergreen.V377.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V377.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) (Maybe Evergreen.V377.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute )
        { fileId : Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute )
        { fileId : Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage Evergreen.V377.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V377.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V377.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V377.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V377.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V377.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V377.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | PressedDisableE2ee (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | TypedPrivateKey (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V377.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId
        , otherUserId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V377.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRoute Evergreen.V377.MessageInput.Msg
    | MessageInputMsg Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRoute Evergreen.V377.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V377.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V377.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V377.Range.Range, Evergreen.V377.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V377.Range.Range, Evergreen.V377.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V377.Call.FromJs)
    | VoiceChatMsg Evergreen.V377.Call.Msg
    | PressedChannelHeaderTab Evergreen.V377.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V377.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V377.Audio.LoadError Evergreen.V377.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V377.Id.AnyGuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V377.Id.AnyGuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) Evergreen.V377.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V377.Encryption.FromJs (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V377.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V377.UserSession.UserSession
    , currentlyViewing : Evergreen.V377.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) Evergreen.V377.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.LocalState.DiscordFrontendGuild
    , user : Evergreen.V377.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.User.FrontendUser
    , discordUsers : Evergreen.V377.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V377.SessionIdHash.SessionIdHash Evergreen.V377.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V377.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId) Evergreen.V377.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId) Evergreen.V377.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V377.Call.CallId (Evergreen.V377.NonemptyDict.NonemptyDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V377.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V377.Go.PublicGoMatchData Evergreen.V377.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V377.Route.Route
    , windowSize : Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V377.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V377.Audio.LoadError Evergreen.V377.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Encryption.EncryptedData (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.NonemptyDict.NonemptyDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Encryption.EncryptedData (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V377.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V377.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V377.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileData) (List Evergreen.V377.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V377.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V377.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.ChannelName.ChannelName Evergreen.V377.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.ChannelName.ChannelName Evergreen.V377.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V377.GuildName.GuildName (Evergreen.V377.UserSession.ToBeFilledInByBackend (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V377.Id.Viewing_DiscordDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V377.UserSession.SetViewing
    | Local_SetName Evergreen.V377.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V377.Id.GuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V377.Id.GuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V377.Id.DiscordGuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V377.Id.DiscordGuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V377.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V377.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V377.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.QuestionId Evergreen.V377.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V377.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V377.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V377.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V377.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V377.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V377.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V377.NonemptySet.NonemptySet (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V377.Call.LocalChange
    | Local_Game Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Game.LocalChange
    | Local_Drawing Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Drawing.AnchorType Evergreen.V377.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V377.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V377.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V377.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V377.X25519.PublicKey (Evergreen.V377.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V377.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V377.Id.Viewing_DmId (List ( Evergreen.V377.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V377.FileStatus.FileHash, Evergreen.V377.Encryption.EncryptedData (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V377.Id.Viewing_DmId (Evergreen.V377.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V377.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V377.Id.ThreadRouteWithMessage, Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V377.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V377.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V377.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V377.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V377.FileStatus.FileHash) (Evergreen.V377.Encryption.EncryptedData (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))) (Evergreen.V377.Encryption.EncryptedData String) Evergreen.V377.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V377.Id.Viewing_DmId Evergreen.V377.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V377.FileStatus.FileHash) (Evergreen.V377.Encryption.EncryptedData (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.User.FrontendUser Effect.Time.Posix Evergreen.V377.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V377.RichText.RichText (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))) Evergreen.V377.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId) Evergreen.V377.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V377.Id.DiscordGuildOrDmId Evergreen.V377.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V377.RichText.RichText (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))) Evergreen.V377.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId) Evergreen.V377.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.ChannelName.ChannelName Evergreen.V377.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.ChannelName.ChannelName Evergreen.V377.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.User.FrontendUser
    | Server_MemberLeft (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V377.LocalState.JoinGuildError
            { guildId : Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId
            , guild : Evergreen.V377.LocalState.FrontendGuild
            , owner : Evergreen.V377.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V377.RichText.RichText (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V377.RichText.RichText (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V377.Id.Viewing_DiscordDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V377.RichText.RichText (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Maybe Evergreen.V377.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Maybe Evergreen.V377.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V377.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V377.SessionIdHash.SessionIdHash Evergreen.V377.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V377.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V377.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V377.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V377.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V377.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Bool Evergreen.V377.ChannelName.ChannelName (Evergreen.V377.Discord.OptionalData (Maybe String)) (List Evergreen.V377.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
        (Evergreen.V377.NonemptyDict.NonemptyDict
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) Evergreen.V377.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Maybe (Evergreen.V377.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V377.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V377.Log.Log
    | Server_BackupGenerated Evergreen.V377.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V377.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V377.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V377.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V377.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (Evergreen.V377.Discord.OptionalData (Maybe String)) (Evergreen.V377.Discord.OptionalData (Maybe String)) (List Evergreen.V377.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId) Evergreen.V377.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
        (Evergreen.V377.MembersAndOwner.MembersAndOwner
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.PersonName.PersonName Evergreen.V377.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId) Evergreen.V377.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId) Evergreen.V377.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V377.Call.ServerChange
    | Server_Game (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Game.LocalChange
    | Server_Drawing (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Drawing.AnchorType Evergreen.V377.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V377.Id.Viewing_DmId ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V377.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V377.Id.Viewing_DmId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | Server_E2eeAccepted Evergreen.V377.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.User.FrontendUser Effect.Time.Posix Evergreen.V377.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V377.FileStatus.FileHash) (Evergreen.V377.Encryption.EncryptedData (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))) Evergreen.V377.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.Viewing_DmId Evergreen.V377.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V377.FileStatus.FileHash) (Evergreen.V377.Encryption.EncryptedData (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V377.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V377.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V377.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V377.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V377.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V377.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V377.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V377.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V377.Id.AnyGuildOrDmId Evergreen.V377.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V377.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels) (Maybe Evergreen.V377.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V377.SheepGame.Input (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels) (Maybe Evergreen.V377.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V377.Id.GuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V377.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V377.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V377.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , threadRoute : Evergreen.V377.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V377.Encryption.BytesHash
    , id : Evergreen.V377.Id.Viewing_DmId
    , senderId : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , threadRoute : Evergreen.V377.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V377.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V377.Id.Viewing_DmId
    , messages : List Evergreen.V377.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V377.Id.Viewing_DmId
    , messages : List ( Evergreen.V377.Id.ThreadRouteWithMessage, Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V377.Id.Viewing_DmId
    , threadRoute : Evergreen.V377.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute )
    , fileId : Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V377.Id.Id Evergreen.V377.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V377.Id.Id Evergreen.V377.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V377.Id.Id Evergreen.V377.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V377.Id.Id Evergreen.V377.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V377.Id.Id Evergreen.V377.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V377.Local.Local LocalMsg Evergreen.V377.LocalState.LocalState
    , admin : Evergreen.V377.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V377.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V377.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V377.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V377.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V377.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.ThreadRoute ) (Evergreen.V377.NonemptyDict.NonemptyDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V377.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V377.Scroll.ScrollPosition
    , textEditor : Evergreen.V377.TextEditor.Model
    , profilePictureEditor : Evergreen.V377.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId, Evergreen.V377.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V377.Emoji.Model
    , voiceChat : Evergreen.V377.Call.Model
    , games : SeqDict.SeqDict Evergreen.V377.Id.GuildOrDmId Evergreen.V377.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V377.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V377.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V377.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V377.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V377.Range.Range
                , direction : Evergreen.V377.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V377.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V377.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V377.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V377.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V377.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V377.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V377.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V377.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V377.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V377.MyUi.LastCopy
    , drag : Evergreen.V377.Touch.Drag
    , dragPrevious : Evergreen.V377.Touch.Drag
    , aiChatModel : Evergreen.V377.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V377.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V377.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V377.Audio.LoadError Evergreen.V377.Audio.Source
    , startupData : Evergreen.V377.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V377.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V377.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V377.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V377.FileStatus.FileHash
    , metadata : Maybe Evergreen.V377.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId, Evergreen.V377.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId, Evergreen.V377.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V377.DmChannelId.DmChannelId, Evergreen.V377.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId, Evergreen.V377.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId, Evergreen.V377.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId, Evergreen.V377.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V377.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V377.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V377.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V377.NonemptyDict.NonemptyDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V377.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V377.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V377.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V377.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V377.DmChannelId.DmChannelId Evergreen.V377.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) Evergreen.V377.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.Slack.Id Evergreen.V377.Slack.ChannelId) Evergreen.V377.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V377.OneToOne.OneToOne String (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    , slackUsers : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.Slack.Id Evergreen.V377.Slack.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    , slackServers : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.Slack.Id Evergreen.V377.Slack.TeamId) (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    , slackToken : Maybe Evergreen.V377.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V377.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V377.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V377.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V377.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId, Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V377.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V377.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V377.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V377.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.LocalState.LoadingDiscordChannel Evergreen.V377.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V377.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId) Evergreen.V377.Sticker.StickerData
    , discordStickers : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.Discord.Id Evergreen.V377.Discord.StickerId) (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId) Evergreen.V377.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V377.OneToOne.OneToOne Evergreen.V377.RichText.DiscordCustomEmojiIdAndName (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V377.Postmark.ApiKey
    , serverSecret : Evergreen.V377.SecretId.SecretId Evergreen.V377.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V377.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.GamePublicId) ( Evergreen.V377.DmChannelId.GuildOrFullDmId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V377.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V377.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V377.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.Id.ThreadRoute (Maybe Evergreen.V377.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V377.DmChannelId.DmChannelId Evergreen.V377.Id.ThreadRoute (Maybe Evergreen.V377.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V377.Id.Id Evergreen.V377.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V377.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V377.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V377.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V377.Untrusted.Untrusted Evergreen.V377.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V377.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V377.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V377.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V377.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V377.PersonName.PersonName Evergreen.V377.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V377.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V377.Slack.OAuthCode Evergreen.V377.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V377.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V377.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V377.Id.Id Evergreen.V377.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V377.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V377.EmailAddress.EmailAddress (Result Evergreen.V377.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V377.EmailAddress.EmailAddress (Result Evergreen.V377.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V377.EmailAddress.EmailAddress (Result Evergreen.V377.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V377.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMaybeMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Result Evergreen.V377.Discord.HttpError Evergreen.V377.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V377.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Result Evergreen.V377.Discord.HttpError Evergreen.V377.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) (Result Evergreen.V377.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) (Result Evergreen.V377.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) (Result Evergreen.V377.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) (Result Evergreen.V377.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji (Result Evergreen.V377.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji (Result Evergreen.V377.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji (Result Evergreen.V377.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji (Result Evergreen.V377.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V377.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V377.Discord.HttpError (List ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId, Maybe Evergreen.V377.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Effect.Time.Posix Evergreen.V377.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V377.Slack.CurrentUser
            , team : Evergreen.V377.Slack.Team
            , users : List Evergreen.V377.Slack.User
            , channels : List ( Evergreen.V377.Slack.Channel, List Evergreen.V377.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Result Effect.Http.Error Evergreen.V377.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Discord.UserAuth (Result Evergreen.V377.Discord.HttpError Evergreen.V377.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Result Evergreen.V377.Discord.HttpError Evergreen.V377.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
        (Result
            Evergreen.V377.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId
                , members : List (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
                }
            , List
                ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId
                , { guild : Evergreen.V377.Discord.GatewayGuild
                  , channels : List Evergreen.V377.Discord.Channel
                  , icon : Maybe Evergreen.V377.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V377.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V377.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.AttachmentId, Evergreen.V377.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V377.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.AttachmentId, Evergreen.V377.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V377.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V377.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V377.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V377.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (Result Evergreen.V377.Discord.HttpError Evergreen.V377.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Result Evergreen.V377.Discord.HttpError (List Evergreen.V377.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V377.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V377.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V377.DmChannelId.DmChannelId Evergreen.V377.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V377.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V377.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V377.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
        (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V377.Discord.HttpError
            { guild : Evergreen.V377.Discord.GatewayGuild
            , channels : List Evergreen.V377.Discord.Channel
            , icon : Maybe Evergreen.V377.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Result Evergreen.V377.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V377.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (List ( Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId, Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId, Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (List ( Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V377.Discord.HttpError (List Evergreen.V377.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V377.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V377.SecretId.SecretId Evergreen.V377.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V377.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Result Evergreen.V377.Discord.HttpError ( Evergreen.V377.Discord.Guild, List Evergreen.V377.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V377.FileStatus.FileHash Int (Maybe (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Call.CallId
