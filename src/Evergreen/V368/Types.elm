module Evergreen.V368.Types exposing (..)

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
import Evergreen.V368.AiChat
import Evergreen.V368.Audio
import Evergreen.V368.Call
import Evergreen.V368.ChannelDescription
import Evergreen.V368.ChannelName
import Evergreen.V368.Coord
import Evergreen.V368.CssPixels
import Evergreen.V368.CustomEmoji
import Evergreen.V368.Discord
import Evergreen.V368.DiscordAttachmentId
import Evergreen.V368.DiscordUserData
import Evergreen.V368.DmChannel
import Evergreen.V368.DmChannelId
import Evergreen.V368.Drawing
import Evergreen.V368.Editable
import Evergreen.V368.EmailAddress
import Evergreen.V368.Embed
import Evergreen.V368.Emoji
import Evergreen.V368.Encryption
import Evergreen.V368.FileStatus
import Evergreen.V368.Game
import Evergreen.V368.Go
import Evergreen.V368.GuildName
import Evergreen.V368.Id
import Evergreen.V368.IdArray
import Evergreen.V368.ImageEditor
import Evergreen.V368.ImageViewer
import Evergreen.V368.LinkedAndOtherDiscordUsers
import Evergreen.V368.Local
import Evergreen.V368.LocalState
import Evergreen.V368.Log
import Evergreen.V368.LoginForm
import Evergreen.V368.MembersAndOwner
import Evergreen.V368.Message
import Evergreen.V368.MessageInput
import Evergreen.V368.MessageView
import Evergreen.V368.MuteSettings
import Evergreen.V368.MyUi
import Evergreen.V368.NonemptyDict
import Evergreen.V368.NonemptySet
import Evergreen.V368.OneOrGreater
import Evergreen.V368.OneToOne
import Evergreen.V368.Pages.Admin
import Evergreen.V368.Pagination
import Evergreen.V368.PersonName
import Evergreen.V368.Ports
import Evergreen.V368.Postmark
import Evergreen.V368.Range
import Evergreen.V368.RecoveryLogin
import Evergreen.V368.RichText
import Evergreen.V368.Route
import Evergreen.V368.Scroll
import Evergreen.V368.SecretId
import Evergreen.V368.SessionIdHash
import Evergreen.V368.SheepGame
import Evergreen.V368.Slack
import Evergreen.V368.Sticker
import Evergreen.V368.TextEditor
import Evergreen.V368.ToBackendLog
import Evergreen.V368.Touch
import Evergreen.V368.TwoFactorAuthentication
import Evergreen.V368.Ui.Anim
import Evergreen.V368.Untrusted
import Evergreen.V368.User
import Evergreen.V368.UserAgent
import Evergreen.V368.UserColor
import Evergreen.V368.UserSession
import Evergreen.V368.WordSpellingGame
import Evergreen.V368.X25519
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
    | LoginFormMsg Evergreen.V368.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V368.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V368.Pages.Admin.Msg
    | PressedLogOut Evergreen.V368.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V368.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V368.Route.Route
    | SelectedFilesToAttach ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V368.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V368.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V368.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V368.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V368.NonemptyDict.NonemptyDict Int Evergreen.V368.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V368.NonemptyDict.NonemptyDict Int Evergreen.V368.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRoute Evergreen.V368.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V368.NonemptySet.NonemptySet (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V368.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V368.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V368.AiChat.Msg
    | GameMsg Evergreen.V368.Game.Msg
    | GoSpectatorMsg Evergreen.V368.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V368.Editable.Msg Evergreen.V368.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V368.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) (Maybe Evergreen.V368.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute )
        { fileId : Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute )
        { fileId : Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage Evergreen.V368.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V368.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V368.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V368.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V368.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V368.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V368.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | PressedDisableE2ee (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | TypedPrivateKey (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V368.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId
        , otherUserId : Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V368.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRoute Evergreen.V368.MessageInput.Msg
    | MessageInputMsg Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRoute Evergreen.V368.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V368.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V368.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V368.Range.Range, Evergreen.V368.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V368.Range.Range, Evergreen.V368.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V368.Call.FromJs)
    | VoiceChatMsg Evergreen.V368.Call.Msg
    | PressedChannelHeaderTab Evergreen.V368.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V368.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V368.Audio.LoadError Evergreen.V368.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V368.Id.AnyGuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V368.Id.AnyGuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) Evergreen.V368.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V368.Encryption.FromJs (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V368.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V368.UserSession.UserSession
    , currentlyViewing : Evergreen.V368.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) Evergreen.V368.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.LocalState.DiscordFrontendGuild
    , user : Evergreen.V368.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.User.FrontendUser
    , discordUsers : Evergreen.V368.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V368.SessionIdHash.SessionIdHash Evergreen.V368.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V368.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId) Evergreen.V368.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId) Evergreen.V368.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V368.Call.CallId (Evergreen.V368.NonemptyDict.NonemptyDict ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V368.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V368.Go.PublicGoMatchData Evergreen.V368.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V368.Route.Route
    , windowSize : Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V368.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V368.Audio.LoadError Evergreen.V368.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Encryption.EncryptedData (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.NonemptyDict.NonemptyDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) (Evergreen.V368.Encryption.EncryptedData (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V368.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V368.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V368.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData) (List Evergreen.V368.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V368.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V368.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.ChannelName.ChannelName Evergreen.V368.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.ChannelName.ChannelName Evergreen.V368.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V368.GuildName.GuildName (Evergreen.V368.UserSession.ToBeFilledInByBackend (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V368.Id.Viewing_DiscordDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V368.UserSession.SetViewing
    | Local_SetName Evergreen.V368.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V368.Id.GuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Message.Message Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V368.Id.GuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) (Evergreen.V368.Message.Message Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V368.Id.DiscordGuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Message.Message Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V368.Id.DiscordGuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) (Evergreen.V368.Message.Message Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V368.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V368.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V368.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.QuestionId Evergreen.V368.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V368.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V368.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V368.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V368.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V368.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V368.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V368.NonemptySet.NonemptySet (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V368.Call.LocalChange
    | Local_Game Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Game.LocalChange
    | Local_Drawing Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Drawing.AnchorType Evergreen.V368.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V368.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V368.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V368.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V368.X25519.PublicKey (Evergreen.V368.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V368.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V368.Id.Viewing_DmId (List ( Evergreen.V368.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V368.FileStatus.FileHash, Evergreen.V368.Encryption.EncryptedData (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V368.Id.Viewing_DmId (Evergreen.V368.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V368.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V368.Id.ThreadRouteWithMessage, Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V368.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V368.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V368.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V368.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V368.FileStatus.FileHash) (Evergreen.V368.Encryption.EncryptedData (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))) Evergreen.V368.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V368.Id.Viewing_DmId Evergreen.V368.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V368.FileStatus.FileHash) (Evergreen.V368.Encryption.EncryptedData (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.User.FrontendUser Effect.Time.Posix Evergreen.V368.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V368.RichText.RichText (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))) Evergreen.V368.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId) Evergreen.V368.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V368.Id.DiscordGuildOrDmId Evergreen.V368.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V368.RichText.RichText (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))) Evergreen.V368.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId) Evergreen.V368.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.ChannelName.ChannelName Evergreen.V368.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.ChannelName.ChannelName Evergreen.V368.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.User.FrontendUser
    | Server_MemberLeft (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V368.LocalState.JoinGuildError
            { guildId : Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId
            , guild : Evergreen.V368.LocalState.FrontendGuild
            , owner : Evergreen.V368.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V368.RichText.RichText (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))) (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V368.RichText.RichText (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V368.Id.Viewing_DiscordDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V368.RichText.RichText (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Maybe Evergreen.V368.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Maybe Evergreen.V368.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V368.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V368.SessionIdHash.SessionIdHash Evergreen.V368.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V368.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V368.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V368.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V368.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V368.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Bool Evergreen.V368.ChannelName.ChannelName (Evergreen.V368.Discord.OptionalData (Maybe String)) (List Evergreen.V368.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
        (Evergreen.V368.NonemptyDict.NonemptyDict
            (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) Evergreen.V368.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Maybe (Evergreen.V368.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V368.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V368.Log.Log
    | Server_BackupGenerated Evergreen.V368.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V368.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V368.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V368.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V368.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (Evergreen.V368.Discord.OptionalData (Maybe String)) (Evergreen.V368.Discord.OptionalData (Maybe String)) (List Evergreen.V368.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.RoleId) Evergreen.V368.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
        (Evergreen.V368.MembersAndOwner.MembersAndOwner
            (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V368.Discord.Id Evergreen.V368.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.PersonName.PersonName Evergreen.V368.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId) Evergreen.V368.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId) Evergreen.V368.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V368.Call.ServerChange
    | Server_Game (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Game.LocalChange
    | Server_Drawing (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Drawing.AnchorType Evergreen.V368.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V368.Id.Viewing_DmId ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Evergreen.V368.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V368.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V368.Id.Viewing_DmId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | Server_E2eeAccepted Evergreen.V368.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.User.FrontendUser Effect.Time.Posix Evergreen.V368.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V368.FileStatus.FileHash) (Evergreen.V368.Encryption.EncryptedData (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))) Evergreen.V368.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.Viewing_DmId Evergreen.V368.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V368.FileStatus.FileHash) (Evergreen.V368.Encryption.EncryptedData (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V368.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V368.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V368.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V368.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V368.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V368.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V368.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V368.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V368.Id.AnyGuildOrDmId Evergreen.V368.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V368.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels) (Maybe Evergreen.V368.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V368.SheepGame.Input (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels) (Maybe Evergreen.V368.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V368.Id.GuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId) (Evergreen.V368.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V368.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V368.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V368.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , threadRoute : Evergreen.V368.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V368.Encryption.BytesHash
    , id : Evergreen.V368.Id.Viewing_DmId
    , senderId : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , threadRoute : Evergreen.V368.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V368.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V368.Id.Viewing_DmId
    , messages : List Evergreen.V368.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V368.Id.Viewing_DmId
    , messages : List ( Evergreen.V368.Id.ThreadRouteWithMessage, Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V368.Id.Viewing_DmId
    , threadRoute : Evergreen.V368.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute )
    , fileId : Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Encryption.EncryptRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V368.Id.Id Evergreen.V368.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V368.Id.Id Evergreen.V368.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V368.Id.Id Evergreen.V368.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V368.Id.Id Evergreen.V368.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V368.Id.Id Evergreen.V368.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V368.Local.Local LocalMsg Evergreen.V368.LocalState.LocalState
    , admin : Evergreen.V368.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId, Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V368.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V368.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V368.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V368.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V368.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.ThreadRoute ) (Evergreen.V368.NonemptyDict.NonemptyDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V368.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V368.Scroll.ScrollPosition
    , textEditor : Evergreen.V368.TextEditor.Model
    , profilePictureEditor : Evergreen.V368.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId, Evergreen.V368.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V368.Emoji.Model
    , voiceChat : Evergreen.V368.Call.Model
    , games : SeqDict.SeqDict Evergreen.V368.Id.GuildOrDmId Evergreen.V368.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V368.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V368.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V368.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V368.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V368.Range.Range
                , direction : Evergreen.V368.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V368.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V368.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V368.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V368.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V368.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V368.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V368.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V368.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V368.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V368.MyUi.LastCopy
    , drag : Evergreen.V368.Touch.Drag
    , dragPrevious : Evergreen.V368.Touch.Drag
    , aiChatModel : Evergreen.V368.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V368.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V368.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V368.Audio.LoadError Evergreen.V368.Audio.Source
    , startupData : Evergreen.V368.Ports.StartupData
    , appBadgeCount : Maybe Int
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V368.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V368.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V368.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V368.FileStatus.FileHash
    , metadata : Maybe Evergreen.V368.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId, Evergreen.V368.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId, Evergreen.V368.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V368.DmChannelId.DmChannelId, Evergreen.V368.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId, Evergreen.V368.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId, Evergreen.V368.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId, Evergreen.V368.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V368.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V368.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V368.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V368.NonemptyDict.NonemptyDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V368.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V368.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V368.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V368.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V368.DmChannelId.DmChannelId Evergreen.V368.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) Evergreen.V368.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V368.OneToOne.OneToOne (Evergreen.V368.Slack.Id Evergreen.V368.Slack.ChannelId) Evergreen.V368.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V368.OneToOne.OneToOne String (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    , slackUsers : Evergreen.V368.OneToOne.OneToOne (Evergreen.V368.Slack.Id Evergreen.V368.Slack.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    , slackServers : Evergreen.V368.OneToOne.OneToOne (Evergreen.V368.Slack.Id Evergreen.V368.Slack.TeamId) (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    , slackToken : Maybe Evergreen.V368.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V368.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V368.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V368.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V368.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId, Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V368.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V368.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V368.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V368.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.LocalState.LoadingDiscordChannel Evergreen.V368.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V368.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId) Evergreen.V368.Sticker.StickerData
    , discordStickers : Evergreen.V368.OneToOne.OneToOne (Evergreen.V368.Discord.Id Evergreen.V368.Discord.StickerId) (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId) Evergreen.V368.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V368.OneToOne.OneToOne Evergreen.V368.RichText.DiscordCustomEmojiIdAndName (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V368.Postmark.ApiKey
    , serverSecret : Evergreen.V368.SecretId.SecretId Evergreen.V368.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V368.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V368.OneToOne.OneToOne (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.GamePublicId) ( Evergreen.V368.DmChannelId.GuildOrFullDmId, Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V368.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V368.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V368.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.Id.ThreadRoute (Maybe Evergreen.V368.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V368.DmChannelId.DmChannelId Evergreen.V368.Id.ThreadRoute (Maybe Evergreen.V368.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V368.Id.Id Evergreen.V368.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V368.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V368.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V368.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V368.Untrusted.Untrusted Evergreen.V368.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V368.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V368.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V368.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V368.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V368.PersonName.PersonName Evergreen.V368.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V368.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V368.Slack.OAuthCode Evergreen.V368.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V368.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V368.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V368.Id.Id Evergreen.V368.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V368.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V368.EmailAddress.EmailAddress (Result Evergreen.V368.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V368.EmailAddress.EmailAddress (Result Evergreen.V368.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V368.EmailAddress.EmailAddress (Result Evergreen.V368.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V368.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMaybeMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Result Evergreen.V368.Discord.HttpError Evergreen.V368.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V368.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Result Evergreen.V368.Discord.HttpError Evergreen.V368.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) (Result Evergreen.V368.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) (Result Evergreen.V368.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) (Result Evergreen.V368.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) (Result Evergreen.V368.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji (Result Evergreen.V368.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji (Result Evergreen.V368.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji (Result Evergreen.V368.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji (Result Evergreen.V368.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V368.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V368.Discord.HttpError (List ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId, Maybe Evergreen.V368.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Effect.Time.Posix Evergreen.V368.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V368.Slack.CurrentUser
            , team : Evergreen.V368.Slack.Team
            , users : List Evergreen.V368.Slack.User
            , channels : List ( Evergreen.V368.Slack.Channel, List Evergreen.V368.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Result Effect.Http.Error Evergreen.V368.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Discord.UserAuth (Result Evergreen.V368.Discord.HttpError Evergreen.V368.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Result Evergreen.V368.Discord.HttpError Evergreen.V368.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
        (Result
            Evergreen.V368.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId
                , members : List (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
                }
            , List
                ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId
                , { guild : Evergreen.V368.Discord.GatewayGuild
                  , channels : List Evergreen.V368.Discord.Channel
                  , icon : Maybe Evergreen.V368.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V368.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V368.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.AttachmentId, Evergreen.V368.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V368.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.AttachmentId, Evergreen.V368.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V368.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V368.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V368.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V368.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) (Result Evergreen.V368.Discord.HttpError Evergreen.V368.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Result Evergreen.V368.Discord.HttpError (List Evergreen.V368.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V368.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V368.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V368.DmChannelId.DmChannelId Evergreen.V368.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V368.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V368.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V368.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
        (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V368.Discord.HttpError
            { guild : Evergreen.V368.Discord.GatewayGuild
            , channels : List Evergreen.V368.Discord.Channel
            , icon : Maybe Evergreen.V368.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Result Evergreen.V368.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V368.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (List ( Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId, Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId, Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (List ( Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V368.Discord.HttpError (List Evergreen.V368.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V368.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V368.SecretId.SecretId Evergreen.V368.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V368.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Result Evergreen.V368.Discord.HttpError ( Evergreen.V368.Discord.Guild, List Evergreen.V368.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V368.FileStatus.FileHash Int (Maybe (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Call.CallId
