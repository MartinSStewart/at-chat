module Evergreen.V376.Types exposing (..)

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
import Evergreen.V376.AiChat
import Evergreen.V376.Audio
import Evergreen.V376.Call
import Evergreen.V376.ChannelDescription
import Evergreen.V376.ChannelName
import Evergreen.V376.Coord
import Evergreen.V376.CssPixels
import Evergreen.V376.CustomEmoji
import Evergreen.V376.Discord
import Evergreen.V376.DiscordAttachmentId
import Evergreen.V376.DiscordUserData
import Evergreen.V376.DmChannel
import Evergreen.V376.DmChannelId
import Evergreen.V376.Drawing
import Evergreen.V376.Editable
import Evergreen.V376.EmailAddress
import Evergreen.V376.Embed
import Evergreen.V376.Emoji
import Evergreen.V376.Encryption
import Evergreen.V376.FileStatus
import Evergreen.V376.Game
import Evergreen.V376.Go
import Evergreen.V376.GuildName
import Evergreen.V376.Id
import Evergreen.V376.IdArray
import Evergreen.V376.ImageEditor
import Evergreen.V376.ImageViewer
import Evergreen.V376.LinkedAndOtherDiscordUsers
import Evergreen.V376.Local
import Evergreen.V376.LocalState
import Evergreen.V376.Log
import Evergreen.V376.LoginForm
import Evergreen.V376.MembersAndOwner
import Evergreen.V376.Message
import Evergreen.V376.MessageInput
import Evergreen.V376.MessageView
import Evergreen.V376.MuteSettings
import Evergreen.V376.MyUi
import Evergreen.V376.NonemptyDict
import Evergreen.V376.NonemptySet
import Evergreen.V376.OneOrGreater
import Evergreen.V376.OneToOne
import Evergreen.V376.Pages.Admin
import Evergreen.V376.Pagination
import Evergreen.V376.PersonName
import Evergreen.V376.Ports
import Evergreen.V376.Postmark
import Evergreen.V376.Range
import Evergreen.V376.RecoveryLogin
import Evergreen.V376.RichText
import Evergreen.V376.Route
import Evergreen.V376.Scroll
import Evergreen.V376.SecretId
import Evergreen.V376.SessionIdHash
import Evergreen.V376.SheepGame
import Evergreen.V376.Slack
import Evergreen.V376.Sticker
import Evergreen.V376.TextEditor
import Evergreen.V376.ToBackendLog
import Evergreen.V376.Touch
import Evergreen.V376.TwoFactorAuthentication
import Evergreen.V376.Ui.Anim
import Evergreen.V376.Untrusted
import Evergreen.V376.User
import Evergreen.V376.UserAgent
import Evergreen.V376.UserColor
import Evergreen.V376.UserSession
import Evergreen.V376.WordSpellingGame
import Evergreen.V376.X25519
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
    | LoginFormMsg Evergreen.V376.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V376.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V376.Pages.Admin.Msg
    | PressedLogOut Evergreen.V376.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V376.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V376.Route.Route
    | SelectedFilesToAttach ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V376.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V376.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V376.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V376.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V376.NonemptyDict.NonemptyDict Int Evergreen.V376.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V376.NonemptyDict.NonemptyDict Int Evergreen.V376.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRoute Evergreen.V376.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V376.NonemptySet.NonemptySet (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseOverlay
    | PressedExpandContainer Evergreen.V376.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V376.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V376.AiChat.Msg
    | GameMsg Evergreen.V376.Game.Msg
    | GoSpectatorMsg Evergreen.V376.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V376.Editable.Msg Evergreen.V376.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V376.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) (Maybe Evergreen.V376.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute )
        { fileId : Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute )
        { fileId : Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage Evergreen.V376.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V376.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V376.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V376.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V376.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V376.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V376.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | PressedDisableE2ee (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | TypedPrivateKey (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V376.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId
        , otherUserId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V376.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRoute Evergreen.V376.MessageInput.Msg
    | MessageInputMsg Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRoute Evergreen.V376.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V376.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V376.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V376.Range.Range, Evergreen.V376.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V376.Range.Range, Evergreen.V376.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V376.Call.FromJs)
    | VoiceChatMsg Evergreen.V376.Call.Msg
    | PressedChannelHeaderTab Evergreen.V376.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V376.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V376.Audio.LoadError Evergreen.V376.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V376.Id.AnyGuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V376.Id.AnyGuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) Evergreen.V376.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V376.Encryption.FromJs (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V376.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V376.UserSession.UserSession
    , currentlyViewing : Evergreen.V376.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) Evergreen.V376.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.LocalState.DiscordFrontendGuild
    , user : Evergreen.V376.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.User.FrontendUser
    , discordUsers : Evergreen.V376.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V376.SessionIdHash.SessionIdHash Evergreen.V376.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V376.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId) Evergreen.V376.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId) Evergreen.V376.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V376.Call.CallId (Evergreen.V376.NonemptyDict.NonemptyDict ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V376.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V376.Go.PublicGoMatchData Evergreen.V376.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V376.Route.Route
    , windowSize : Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V376.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V376.Audio.LoadError Evergreen.V376.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Encryption.EncryptedData (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.NonemptyDict.NonemptyDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) (Evergreen.V376.Encryption.EncryptedData (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V376.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V376.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V376.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData) (List Evergreen.V376.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V376.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V376.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.ChannelName.ChannelName Evergreen.V376.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.ChannelName.ChannelName Evergreen.V376.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V376.GuildName.GuildName (Evergreen.V376.UserSession.ToBeFilledInByBackend (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V376.Id.Viewing_DiscordDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V376.UserSession.SetViewing
    | Local_SetName Evergreen.V376.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V376.Id.GuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V376.Id.GuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) (Evergreen.V376.Message.Message Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V376.Id.DiscordGuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V376.Id.DiscordGuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) (Evergreen.V376.Message.Message Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V376.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V376.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V376.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.QuestionId Evergreen.V376.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V376.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V376.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V376.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V376.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V376.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V376.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V376.NonemptySet.NonemptySet (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V376.Call.LocalChange
    | Local_Game Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Game.LocalChange
    | Local_Drawing Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Drawing.AnchorType Evergreen.V376.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V376.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V376.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V376.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V376.X25519.PublicKey (Evergreen.V376.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V376.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V376.Id.Viewing_DmId (List ( Evergreen.V376.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V376.FileStatus.FileHash, Evergreen.V376.Encryption.EncryptedData (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V376.Id.Viewing_DmId (Evergreen.V376.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V376.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V376.Id.ThreadRouteWithMessage, Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V376.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V376.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V376.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V376.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V376.FileStatus.FileHash) (Evergreen.V376.Encryption.EncryptedData (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))) (Evergreen.V376.Encryption.EncryptedData String) Evergreen.V376.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V376.Id.Viewing_DmId Evergreen.V376.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V376.FileStatus.FileHash) (Evergreen.V376.Encryption.EncryptedData (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.User.FrontendUser Effect.Time.Posix Evergreen.V376.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V376.RichText.RichText (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))) Evergreen.V376.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId) Evergreen.V376.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V376.Id.DiscordGuildOrDmId Evergreen.V376.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V376.RichText.RichText (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))) Evergreen.V376.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId) Evergreen.V376.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.ChannelName.ChannelName Evergreen.V376.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.ChannelName.ChannelName Evergreen.V376.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.User.FrontendUser
    | Server_MemberLeft (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V376.LocalState.JoinGuildError
            { guildId : Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId
            , guild : Evergreen.V376.LocalState.FrontendGuild
            , owner : Evergreen.V376.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V376.RichText.RichText (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))) (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V376.RichText.RichText (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V376.Id.Viewing_DiscordDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V376.RichText.RichText (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Maybe Evergreen.V376.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Maybe Evergreen.V376.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V376.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V376.SessionIdHash.SessionIdHash Evergreen.V376.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V376.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V376.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V376.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V376.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V376.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Bool Evergreen.V376.ChannelName.ChannelName (Evergreen.V376.Discord.OptionalData (Maybe String)) (List Evergreen.V376.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
        (Evergreen.V376.NonemptyDict.NonemptyDict
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) Evergreen.V376.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Maybe (Evergreen.V376.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V376.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V376.Log.Log
    | Server_BackupGenerated Evergreen.V376.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V376.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V376.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V376.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V376.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (Evergreen.V376.Discord.OptionalData (Maybe String)) (Evergreen.V376.Discord.OptionalData (Maybe String)) (List Evergreen.V376.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId) Evergreen.V376.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
        (Evergreen.V376.MembersAndOwner.MembersAndOwner
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.PersonName.PersonName Evergreen.V376.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId) Evergreen.V376.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId) Evergreen.V376.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V376.Call.ServerChange
    | Server_Game (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Game.LocalChange
    | Server_Drawing (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Drawing.AnchorType Evergreen.V376.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V376.Id.Viewing_DmId ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Evergreen.V376.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V376.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V376.Id.Viewing_DmId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | Server_E2eeAccepted Evergreen.V376.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.User.FrontendUser Effect.Time.Posix Evergreen.V376.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V376.FileStatus.FileHash) (Evergreen.V376.Encryption.EncryptedData (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))) Evergreen.V376.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.Viewing_DmId Evergreen.V376.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V376.FileStatus.FileHash) (Evergreen.V376.Encryption.EncryptedData (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V376.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V376.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V376.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V376.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V376.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V376.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V376.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V376.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V376.Id.AnyGuildOrDmId Evergreen.V376.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V376.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels) (Maybe Evergreen.V376.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V376.SheepGame.Input (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels) (Maybe Evergreen.V376.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V376.Id.GuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId) (Evergreen.V376.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V376.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V376.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V376.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , threadRoute : Evergreen.V376.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V376.Encryption.BytesHash
    , id : Evergreen.V376.Id.Viewing_DmId
    , senderId : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , threadRoute : Evergreen.V376.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V376.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V376.Id.Viewing_DmId
    , messages : List Evergreen.V376.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V376.Id.Viewing_DmId
    , messages : List ( Evergreen.V376.Id.ThreadRouteWithMessage, Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V376.Id.Viewing_DmId
    , threadRoute : Evergreen.V376.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute )
    , fileId : Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V376.Id.Id Evergreen.V376.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V376.Id.Id Evergreen.V376.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V376.Id.Id Evergreen.V376.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V376.Id.Id Evergreen.V376.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V376.Id.Id Evergreen.V376.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V376.Local.Local LocalMsg Evergreen.V376.LocalState.LocalState
    , admin : Evergreen.V376.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId, Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V376.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V376.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V376.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V376.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V376.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.ThreadRoute ) (Evergreen.V376.NonemptyDict.NonemptyDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V376.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V376.Scroll.ScrollPosition
    , textEditor : Evergreen.V376.TextEditor.Model
    , profilePictureEditor : Evergreen.V376.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId, Evergreen.V376.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V376.Emoji.Model
    , voiceChat : Evergreen.V376.Call.Model
    , games : SeqDict.SeqDict Evergreen.V376.Id.GuildOrDmId Evergreen.V376.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V376.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V376.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V376.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V376.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V376.Range.Range
                , direction : Evergreen.V376.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V376.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V376.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V376.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V376.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V376.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V376.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V376.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V376.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V376.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V376.MyUi.LastCopy
    , drag : Evergreen.V376.Touch.Drag
    , dragPrevious : Evergreen.V376.Touch.Drag
    , aiChatModel : Evergreen.V376.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V376.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V376.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V376.Audio.LoadError Evergreen.V376.Audio.Source
    , startupData : Evergreen.V376.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V376.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V376.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V376.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V376.FileStatus.FileHash
    , metadata : Maybe Evergreen.V376.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId, Evergreen.V376.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId, Evergreen.V376.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V376.DmChannelId.DmChannelId, Evergreen.V376.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId, Evergreen.V376.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId, Evergreen.V376.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId, Evergreen.V376.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V376.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V376.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V376.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V376.NonemptyDict.NonemptyDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V376.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V376.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V376.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V376.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V376.DmChannelId.DmChannelId Evergreen.V376.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) Evergreen.V376.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.Slack.Id Evergreen.V376.Slack.ChannelId) Evergreen.V376.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V376.OneToOne.OneToOne String (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    , slackUsers : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.Slack.Id Evergreen.V376.Slack.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    , slackServers : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.Slack.Id Evergreen.V376.Slack.TeamId) (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    , slackToken : Maybe Evergreen.V376.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V376.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V376.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V376.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V376.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId, Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V376.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V376.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V376.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V376.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.LocalState.LoadingDiscordChannel Evergreen.V376.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V376.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId) Evergreen.V376.Sticker.StickerData
    , discordStickers : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.Discord.Id Evergreen.V376.Discord.StickerId) (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId) Evergreen.V376.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V376.OneToOne.OneToOne Evergreen.V376.RichText.DiscordCustomEmojiIdAndName (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V376.Postmark.ApiKey
    , serverSecret : Evergreen.V376.SecretId.SecretId Evergreen.V376.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V376.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.GamePublicId) ( Evergreen.V376.DmChannelId.GuildOrFullDmId, Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V376.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V376.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V376.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.Id.ThreadRoute (Maybe Evergreen.V376.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V376.DmChannelId.DmChannelId Evergreen.V376.Id.ThreadRoute (Maybe Evergreen.V376.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V376.Id.Id Evergreen.V376.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V376.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V376.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V376.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V376.Untrusted.Untrusted Evergreen.V376.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V376.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V376.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V376.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V376.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V376.PersonName.PersonName Evergreen.V376.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V376.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V376.Slack.OAuthCode Evergreen.V376.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V376.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V376.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V376.Id.Id Evergreen.V376.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V376.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V376.EmailAddress.EmailAddress (Result Evergreen.V376.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V376.EmailAddress.EmailAddress (Result Evergreen.V376.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V376.EmailAddress.EmailAddress (Result Evergreen.V376.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V376.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMaybeMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Result Evergreen.V376.Discord.HttpError Evergreen.V376.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V376.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Result Evergreen.V376.Discord.HttpError Evergreen.V376.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) (Result Evergreen.V376.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) (Result Evergreen.V376.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) (Result Evergreen.V376.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) (Result Evergreen.V376.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji (Result Evergreen.V376.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji (Result Evergreen.V376.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji (Result Evergreen.V376.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji (Result Evergreen.V376.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V376.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V376.Discord.HttpError (List ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId, Maybe Evergreen.V376.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Effect.Time.Posix Evergreen.V376.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V376.Slack.CurrentUser
            , team : Evergreen.V376.Slack.Team
            , users : List Evergreen.V376.Slack.User
            , channels : List ( Evergreen.V376.Slack.Channel, List Evergreen.V376.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Result Effect.Http.Error Evergreen.V376.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Discord.UserAuth (Result Evergreen.V376.Discord.HttpError Evergreen.V376.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Result Evergreen.V376.Discord.HttpError Evergreen.V376.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
        (Result
            Evergreen.V376.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId
                , members : List (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
                }
            , List
                ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId
                , { guild : Evergreen.V376.Discord.GatewayGuild
                  , channels : List Evergreen.V376.Discord.Channel
                  , icon : Maybe Evergreen.V376.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V376.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V376.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.AttachmentId, Evergreen.V376.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V376.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.AttachmentId, Evergreen.V376.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V376.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V376.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V376.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V376.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (Result Evergreen.V376.Discord.HttpError Evergreen.V376.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Result Evergreen.V376.Discord.HttpError (List Evergreen.V376.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V376.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V376.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V376.DmChannelId.DmChannelId Evergreen.V376.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V376.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V376.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V376.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
        (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V376.Discord.HttpError
            { guild : Evergreen.V376.Discord.GatewayGuild
            , channels : List Evergreen.V376.Discord.Channel
            , icon : Maybe Evergreen.V376.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Result Evergreen.V376.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V376.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (List ( Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId, Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId, Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (List ( Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V376.Discord.HttpError (List Evergreen.V376.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V376.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V376.SecretId.SecretId Evergreen.V376.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V376.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Result Evergreen.V376.Discord.HttpError ( Evergreen.V376.Discord.Guild, List Evergreen.V376.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V376.FileStatus.FileHash Int (Maybe (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Call.CallId
