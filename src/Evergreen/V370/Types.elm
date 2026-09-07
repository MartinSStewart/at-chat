module Evergreen.V370.Types exposing (..)

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
import Evergreen.V370.AiChat
import Evergreen.V370.Audio
import Evergreen.V370.Call
import Evergreen.V370.ChannelDescription
import Evergreen.V370.ChannelName
import Evergreen.V370.Coord
import Evergreen.V370.CssPixels
import Evergreen.V370.CustomEmoji
import Evergreen.V370.Discord
import Evergreen.V370.DiscordAttachmentId
import Evergreen.V370.DiscordUserData
import Evergreen.V370.DmChannel
import Evergreen.V370.DmChannelId
import Evergreen.V370.Drawing
import Evergreen.V370.Editable
import Evergreen.V370.EmailAddress
import Evergreen.V370.Embed
import Evergreen.V370.Emoji
import Evergreen.V370.Encryption
import Evergreen.V370.FileStatus
import Evergreen.V370.Game
import Evergreen.V370.Go
import Evergreen.V370.GuildName
import Evergreen.V370.Id
import Evergreen.V370.IdArray
import Evergreen.V370.ImageEditor
import Evergreen.V370.ImageViewer
import Evergreen.V370.LinkedAndOtherDiscordUsers
import Evergreen.V370.Local
import Evergreen.V370.LocalState
import Evergreen.V370.Log
import Evergreen.V370.LoginForm
import Evergreen.V370.MembersAndOwner
import Evergreen.V370.Message
import Evergreen.V370.MessageInput
import Evergreen.V370.MessageView
import Evergreen.V370.MuteSettings
import Evergreen.V370.MyUi
import Evergreen.V370.NonemptyDict
import Evergreen.V370.NonemptySet
import Evergreen.V370.OneOrGreater
import Evergreen.V370.OneToOne
import Evergreen.V370.Pages.Admin
import Evergreen.V370.Pagination
import Evergreen.V370.PersonName
import Evergreen.V370.Ports
import Evergreen.V370.Postmark
import Evergreen.V370.Range
import Evergreen.V370.RecoveryLogin
import Evergreen.V370.RichText
import Evergreen.V370.Route
import Evergreen.V370.Scroll
import Evergreen.V370.SecretId
import Evergreen.V370.SessionIdHash
import Evergreen.V370.SheepGame
import Evergreen.V370.Slack
import Evergreen.V370.Sticker
import Evergreen.V370.TextEditor
import Evergreen.V370.ToBackendLog
import Evergreen.V370.Touch
import Evergreen.V370.TwoFactorAuthentication
import Evergreen.V370.Ui.Anim
import Evergreen.V370.Untrusted
import Evergreen.V370.User
import Evergreen.V370.UserAgent
import Evergreen.V370.UserColor
import Evergreen.V370.UserSession
import Evergreen.V370.WordSpellingGame
import Evergreen.V370.X25519
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
    | LoginFormMsg Evergreen.V370.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V370.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V370.Pages.Admin.Msg
    | PressedLogOut Evergreen.V370.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V370.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V370.Route.Route
    | SelectedFilesToAttach ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V370.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V370.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V370.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V370.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V370.NonemptyDict.NonemptyDict Int Evergreen.V370.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V370.NonemptyDict.NonemptyDict Int Evergreen.V370.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRoute Evergreen.V370.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V370.NonemptySet.NonemptySet (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V370.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V370.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V370.AiChat.Msg
    | GameMsg Evergreen.V370.Game.Msg
    | GoSpectatorMsg Evergreen.V370.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V370.Editable.Msg Evergreen.V370.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V370.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) (Maybe Evergreen.V370.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute )
        { fileId : Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute )
        { fileId : Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage Evergreen.V370.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V370.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V370.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V370.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V370.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V370.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V370.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | PressedDisableE2ee (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | TypedPrivateKey (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V370.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId
        , otherUserId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V370.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRoute Evergreen.V370.MessageInput.Msg
    | MessageInputMsg Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRoute Evergreen.V370.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V370.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V370.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V370.Range.Range, Evergreen.V370.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V370.Range.Range, Evergreen.V370.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V370.Call.FromJs)
    | VoiceChatMsg Evergreen.V370.Call.Msg
    | PressedChannelHeaderTab Evergreen.V370.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V370.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V370.Audio.LoadError Evergreen.V370.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V370.Id.AnyGuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V370.Id.AnyGuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) Evergreen.V370.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V370.Encryption.FromJs (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V370.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V370.UserSession.UserSession
    , currentlyViewing : Evergreen.V370.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) Evergreen.V370.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.LocalState.DiscordFrontendGuild
    , user : Evergreen.V370.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.User.FrontendUser
    , discordUsers : Evergreen.V370.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V370.SessionIdHash.SessionIdHash Evergreen.V370.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V370.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId) Evergreen.V370.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId) Evergreen.V370.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V370.Call.CallId (Evergreen.V370.NonemptyDict.NonemptyDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V370.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V370.Go.PublicGoMatchData Evergreen.V370.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V370.Route.Route
    , windowSize : Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V370.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V370.Audio.LoadError Evergreen.V370.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Encryption.EncryptedData (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.NonemptyDict.NonemptyDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Encryption.EncryptedData (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V370.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V370.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V370.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData) (List Evergreen.V370.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V370.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V370.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.ChannelName.ChannelName Evergreen.V370.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.ChannelName.ChannelName Evergreen.V370.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V370.GuildName.GuildName (Evergreen.V370.UserSession.ToBeFilledInByBackend (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V370.Id.Viewing_DiscordDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V370.UserSession.SetViewing
    | Local_SetName Evergreen.V370.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V370.Id.GuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V370.Id.GuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V370.Id.DiscordGuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V370.Id.DiscordGuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V370.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V370.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V370.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.QuestionId Evergreen.V370.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V370.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V370.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V370.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V370.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V370.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V370.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V370.NonemptySet.NonemptySet (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V370.Call.LocalChange
    | Local_Game Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Game.LocalChange
    | Local_Drawing Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Drawing.AnchorType Evergreen.V370.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V370.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V370.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V370.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V370.X25519.PublicKey (Evergreen.V370.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V370.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V370.Id.Viewing_DmId (List ( Evergreen.V370.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V370.FileStatus.FileHash, Evergreen.V370.Encryption.EncryptedData (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V370.Id.Viewing_DmId (Evergreen.V370.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V370.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V370.Id.ThreadRouteWithMessage, Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V370.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V370.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V370.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V370.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V370.FileStatus.FileHash) (Evergreen.V370.Encryption.EncryptedData (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))) Evergreen.V370.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V370.Id.Viewing_DmId Evergreen.V370.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V370.FileStatus.FileHash) (Evergreen.V370.Encryption.EncryptedData (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.User.FrontendUser Effect.Time.Posix Evergreen.V370.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V370.RichText.RichText (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))) Evergreen.V370.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId) Evergreen.V370.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V370.Id.DiscordGuildOrDmId Evergreen.V370.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V370.RichText.RichText (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))) Evergreen.V370.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId) Evergreen.V370.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.ChannelName.ChannelName Evergreen.V370.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.ChannelName.ChannelName Evergreen.V370.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.User.FrontendUser
    | Server_MemberLeft (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V370.LocalState.JoinGuildError
            { guildId : Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId
            , guild : Evergreen.V370.LocalState.FrontendGuild
            , owner : Evergreen.V370.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V370.RichText.RichText (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V370.RichText.RichText (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V370.Id.Viewing_DiscordDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V370.RichText.RichText (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Maybe Evergreen.V370.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Maybe Evergreen.V370.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V370.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V370.SessionIdHash.SessionIdHash Evergreen.V370.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V370.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V370.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V370.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V370.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V370.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Bool Evergreen.V370.ChannelName.ChannelName (Evergreen.V370.Discord.OptionalData (Maybe String)) (List Evergreen.V370.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
        (Evergreen.V370.NonemptyDict.NonemptyDict
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) Evergreen.V370.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Maybe (Evergreen.V370.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V370.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V370.Log.Log
    | Server_BackupGenerated Evergreen.V370.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V370.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V370.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V370.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V370.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (Evergreen.V370.Discord.OptionalData (Maybe String)) (Evergreen.V370.Discord.OptionalData (Maybe String)) (List Evergreen.V370.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId) Evergreen.V370.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
        (Evergreen.V370.MembersAndOwner.MembersAndOwner
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.PersonName.PersonName Evergreen.V370.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId) Evergreen.V370.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId) Evergreen.V370.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V370.Call.ServerChange
    | Server_Game (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Game.LocalChange
    | Server_Drawing (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Drawing.AnchorType Evergreen.V370.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V370.Id.Viewing_DmId ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V370.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V370.Id.Viewing_DmId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | Server_E2eeAccepted Evergreen.V370.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.User.FrontendUser Effect.Time.Posix Evergreen.V370.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V370.FileStatus.FileHash) (Evergreen.V370.Encryption.EncryptedData (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))) Evergreen.V370.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.Viewing_DmId Evergreen.V370.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V370.FileStatus.FileHash) (Evergreen.V370.Encryption.EncryptedData (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V370.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V370.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V370.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V370.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V370.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V370.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V370.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V370.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V370.Id.AnyGuildOrDmId Evergreen.V370.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V370.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels) (Maybe Evergreen.V370.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V370.SheepGame.Input (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels) (Maybe Evergreen.V370.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V370.Id.GuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V370.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V370.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V370.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , threadRoute : Evergreen.V370.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V370.Encryption.BytesHash
    , id : Evergreen.V370.Id.Viewing_DmId
    , senderId : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , threadRoute : Evergreen.V370.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V370.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V370.Id.Viewing_DmId
    , messages : List Evergreen.V370.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V370.Id.Viewing_DmId
    , messages : List ( Evergreen.V370.Id.ThreadRouteWithMessage, Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V370.Id.Viewing_DmId
    , threadRoute : Evergreen.V370.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute )
    , fileId : Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Encryption.EncryptRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V370.Id.Id Evergreen.V370.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V370.Id.Id Evergreen.V370.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V370.Id.Id Evergreen.V370.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V370.Id.Id Evergreen.V370.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V370.Id.Id Evergreen.V370.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V370.Local.Local LocalMsg Evergreen.V370.LocalState.LocalState
    , admin : Evergreen.V370.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V370.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V370.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V370.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V370.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V370.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.ThreadRoute ) (Evergreen.V370.NonemptyDict.NonemptyDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V370.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V370.Scroll.ScrollPosition
    , textEditor : Evergreen.V370.TextEditor.Model
    , profilePictureEditor : Evergreen.V370.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId, Evergreen.V370.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V370.Emoji.Model
    , voiceChat : Evergreen.V370.Call.Model
    , games : SeqDict.SeqDict Evergreen.V370.Id.GuildOrDmId Evergreen.V370.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V370.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V370.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V370.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V370.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V370.Range.Range
                , direction : Evergreen.V370.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V370.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V370.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V370.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V370.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V370.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V370.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V370.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V370.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V370.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V370.MyUi.LastCopy
    , drag : Evergreen.V370.Touch.Drag
    , dragPrevious : Evergreen.V370.Touch.Drag
    , aiChatModel : Evergreen.V370.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V370.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V370.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V370.Audio.LoadError Evergreen.V370.Audio.Source
    , startupData : Evergreen.V370.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V370.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V370.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V370.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V370.FileStatus.FileHash
    , metadata : Maybe Evergreen.V370.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId, Evergreen.V370.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId, Evergreen.V370.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V370.DmChannelId.DmChannelId, Evergreen.V370.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId, Evergreen.V370.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId, Evergreen.V370.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId, Evergreen.V370.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V370.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V370.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V370.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V370.NonemptyDict.NonemptyDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V370.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V370.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V370.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V370.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V370.DmChannelId.DmChannelId Evergreen.V370.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) Evergreen.V370.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.Slack.Id Evergreen.V370.Slack.ChannelId) Evergreen.V370.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V370.OneToOne.OneToOne String (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    , slackUsers : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.Slack.Id Evergreen.V370.Slack.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    , slackServers : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.Slack.Id Evergreen.V370.Slack.TeamId) (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    , slackToken : Maybe Evergreen.V370.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V370.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V370.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V370.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V370.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId, Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V370.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V370.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V370.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V370.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.LocalState.LoadingDiscordChannel Evergreen.V370.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V370.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId) Evergreen.V370.Sticker.StickerData
    , discordStickers : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.Discord.Id Evergreen.V370.Discord.StickerId) (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId) Evergreen.V370.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V370.OneToOne.OneToOne Evergreen.V370.RichText.DiscordCustomEmojiIdAndName (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V370.Postmark.ApiKey
    , serverSecret : Evergreen.V370.SecretId.SecretId Evergreen.V370.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V370.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.GamePublicId) ( Evergreen.V370.DmChannelId.GuildOrFullDmId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V370.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V370.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V370.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.Id.ThreadRoute (Maybe Evergreen.V370.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V370.DmChannelId.DmChannelId Evergreen.V370.Id.ThreadRoute (Maybe Evergreen.V370.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V370.Id.Id Evergreen.V370.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V370.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V370.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V370.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V370.Untrusted.Untrusted Evergreen.V370.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V370.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V370.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V370.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V370.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V370.PersonName.PersonName Evergreen.V370.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V370.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V370.Slack.OAuthCode Evergreen.V370.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V370.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V370.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V370.Id.Id Evergreen.V370.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V370.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V370.EmailAddress.EmailAddress (Result Evergreen.V370.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V370.EmailAddress.EmailAddress (Result Evergreen.V370.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V370.EmailAddress.EmailAddress (Result Evergreen.V370.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V370.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMaybeMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Result Evergreen.V370.Discord.HttpError Evergreen.V370.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V370.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Result Evergreen.V370.Discord.HttpError Evergreen.V370.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) (Result Evergreen.V370.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) (Result Evergreen.V370.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) (Result Evergreen.V370.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) (Result Evergreen.V370.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji (Result Evergreen.V370.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji (Result Evergreen.V370.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji (Result Evergreen.V370.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji (Result Evergreen.V370.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V370.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V370.Discord.HttpError (List ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId, Maybe Evergreen.V370.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Effect.Time.Posix Evergreen.V370.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V370.Slack.CurrentUser
            , team : Evergreen.V370.Slack.Team
            , users : List Evergreen.V370.Slack.User
            , channels : List ( Evergreen.V370.Slack.Channel, List Evergreen.V370.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Result Effect.Http.Error Evergreen.V370.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Discord.UserAuth (Result Evergreen.V370.Discord.HttpError Evergreen.V370.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Result Evergreen.V370.Discord.HttpError Evergreen.V370.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
        (Result
            Evergreen.V370.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId
                , members : List (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
                }
            , List
                ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId
                , { guild : Evergreen.V370.Discord.GatewayGuild
                  , channels : List Evergreen.V370.Discord.Channel
                  , icon : Maybe Evergreen.V370.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V370.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V370.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.AttachmentId, Evergreen.V370.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V370.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.AttachmentId, Evergreen.V370.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V370.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V370.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V370.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V370.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (Result Evergreen.V370.Discord.HttpError Evergreen.V370.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Result Evergreen.V370.Discord.HttpError (List Evergreen.V370.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V370.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V370.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V370.DmChannelId.DmChannelId Evergreen.V370.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V370.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V370.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V370.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
        (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V370.Discord.HttpError
            { guild : Evergreen.V370.Discord.GatewayGuild
            , channels : List Evergreen.V370.Discord.Channel
            , icon : Maybe Evergreen.V370.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Result Evergreen.V370.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V370.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (List ( Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId, Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId, Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (List ( Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V370.Discord.HttpError (List Evergreen.V370.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V370.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V370.SecretId.SecretId Evergreen.V370.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V370.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Result Evergreen.V370.Discord.HttpError ( Evergreen.V370.Discord.Guild, List Evergreen.V370.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V370.FileStatus.FileHash Int (Maybe (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Call.CallId
