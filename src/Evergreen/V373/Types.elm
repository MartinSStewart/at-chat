module Evergreen.V373.Types exposing (..)

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
import Evergreen.V373.AiChat
import Evergreen.V373.Audio
import Evergreen.V373.Call
import Evergreen.V373.ChannelDescription
import Evergreen.V373.ChannelName
import Evergreen.V373.Coord
import Evergreen.V373.CssPixels
import Evergreen.V373.CustomEmoji
import Evergreen.V373.Discord
import Evergreen.V373.DiscordAttachmentId
import Evergreen.V373.DiscordUserData
import Evergreen.V373.DmChannel
import Evergreen.V373.DmChannelId
import Evergreen.V373.Drawing
import Evergreen.V373.Editable
import Evergreen.V373.EmailAddress
import Evergreen.V373.Embed
import Evergreen.V373.Emoji
import Evergreen.V373.Encryption
import Evergreen.V373.FileStatus
import Evergreen.V373.Game
import Evergreen.V373.Go
import Evergreen.V373.GuildName
import Evergreen.V373.Id
import Evergreen.V373.IdArray
import Evergreen.V373.ImageEditor
import Evergreen.V373.ImageViewer
import Evergreen.V373.LinkedAndOtherDiscordUsers
import Evergreen.V373.Local
import Evergreen.V373.LocalState
import Evergreen.V373.Log
import Evergreen.V373.LoginForm
import Evergreen.V373.MembersAndOwner
import Evergreen.V373.Message
import Evergreen.V373.MessageInput
import Evergreen.V373.MessageView
import Evergreen.V373.MuteSettings
import Evergreen.V373.MyUi
import Evergreen.V373.NonemptyDict
import Evergreen.V373.NonemptySet
import Evergreen.V373.OneOrGreater
import Evergreen.V373.OneToOne
import Evergreen.V373.Pages.Admin
import Evergreen.V373.Pagination
import Evergreen.V373.PersonName
import Evergreen.V373.Ports
import Evergreen.V373.Postmark
import Evergreen.V373.Range
import Evergreen.V373.RecoveryLogin
import Evergreen.V373.RichText
import Evergreen.V373.Route
import Evergreen.V373.Scroll
import Evergreen.V373.SecretId
import Evergreen.V373.SessionIdHash
import Evergreen.V373.SheepGame
import Evergreen.V373.Slack
import Evergreen.V373.Sticker
import Evergreen.V373.TextEditor
import Evergreen.V373.ToBackendLog
import Evergreen.V373.Touch
import Evergreen.V373.TwoFactorAuthentication
import Evergreen.V373.Ui.Anim
import Evergreen.V373.Untrusted
import Evergreen.V373.User
import Evergreen.V373.UserAgent
import Evergreen.V373.UserColor
import Evergreen.V373.UserSession
import Evergreen.V373.WordSpellingGame
import Evergreen.V373.X25519
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
    | LoginFormMsg Evergreen.V373.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V373.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V373.Pages.Admin.Msg
    | PressedLogOut Evergreen.V373.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V373.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V373.Route.Route
    | SelectedFilesToAttach ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V373.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V373.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V373.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V373.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V373.NonemptyDict.NonemptyDict Int Evergreen.V373.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V373.NonemptyDict.NonemptyDict Int Evergreen.V373.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRoute Evergreen.V373.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V373.NonemptySet.NonemptySet (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V373.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V373.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V373.AiChat.Msg
    | GameMsg Evergreen.V373.Game.Msg
    | GoSpectatorMsg Evergreen.V373.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V373.Editable.Msg Evergreen.V373.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V373.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) (Maybe Evergreen.V373.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute )
        { fileId : Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute )
        { fileId : Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage Evergreen.V373.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V373.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V373.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V373.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V373.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V373.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V373.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | PressedDisableE2ee (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | TypedPrivateKey (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V373.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId
        , otherUserId : Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V373.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRoute Evergreen.V373.MessageInput.Msg
    | MessageInputMsg Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRoute Evergreen.V373.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V373.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V373.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V373.Range.Range, Evergreen.V373.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V373.Range.Range, Evergreen.V373.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V373.Call.FromJs)
    | VoiceChatMsg Evergreen.V373.Call.Msg
    | PressedChannelHeaderTab Evergreen.V373.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V373.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V373.Audio.LoadError Evergreen.V373.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V373.Id.AnyGuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V373.Id.AnyGuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) Evergreen.V373.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V373.Encryption.FromJs (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V373.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V373.UserSession.UserSession
    , currentlyViewing : Evergreen.V373.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) Evergreen.V373.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.LocalState.DiscordFrontendGuild
    , user : Evergreen.V373.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.User.FrontendUser
    , discordUsers : Evergreen.V373.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V373.SessionIdHash.SessionIdHash Evergreen.V373.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V373.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId) Evergreen.V373.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId) Evergreen.V373.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V373.Call.CallId (Evergreen.V373.NonemptyDict.NonemptyDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V373.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V373.Go.PublicGoMatchData Evergreen.V373.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V373.Route.Route
    , windowSize : Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V373.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V373.Audio.LoadError Evergreen.V373.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Encryption.EncryptedData (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.NonemptyDict.NonemptyDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Encryption.EncryptedData (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V373.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V373.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V373.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData) (List Evergreen.V373.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V373.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V373.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.ChannelName.ChannelName Evergreen.V373.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.ChannelName.ChannelName Evergreen.V373.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V373.GuildName.GuildName (Evergreen.V373.UserSession.ToBeFilledInByBackend (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V373.Id.Viewing_DiscordDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V373.UserSession.SetViewing
    | Local_SetName Evergreen.V373.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V373.Id.GuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V373.Id.GuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V373.Id.DiscordGuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V373.Id.DiscordGuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V373.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V373.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V373.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.QuestionId Evergreen.V373.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V373.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V373.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V373.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V373.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V373.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V373.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V373.NonemptySet.NonemptySet (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V373.Call.LocalChange
    | Local_Game Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Game.LocalChange
    | Local_Drawing Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Drawing.AnchorType Evergreen.V373.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V373.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V373.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V373.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V373.X25519.PublicKey (Evergreen.V373.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V373.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V373.Id.Viewing_DmId (List ( Evergreen.V373.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V373.FileStatus.FileHash, Evergreen.V373.Encryption.EncryptedData (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V373.Id.Viewing_DmId (Evergreen.V373.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V373.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V373.Id.ThreadRouteWithMessage, Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V373.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V373.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V373.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V373.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V373.FileStatus.FileHash) (Evergreen.V373.Encryption.EncryptedData (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))) (Evergreen.V373.Encryption.EncryptedData String) Evergreen.V373.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V373.Id.Viewing_DmId Evergreen.V373.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V373.FileStatus.FileHash) (Evergreen.V373.Encryption.EncryptedData (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.User.FrontendUser Effect.Time.Posix Evergreen.V373.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V373.RichText.RichText (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))) Evergreen.V373.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId) Evergreen.V373.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V373.Id.DiscordGuildOrDmId Evergreen.V373.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V373.RichText.RichText (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))) Evergreen.V373.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId) Evergreen.V373.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.ChannelName.ChannelName Evergreen.V373.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.ChannelName.ChannelName Evergreen.V373.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.User.FrontendUser
    | Server_MemberLeft (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V373.LocalState.JoinGuildError
            { guildId : Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId
            , guild : Evergreen.V373.LocalState.FrontendGuild
            , owner : Evergreen.V373.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V373.RichText.RichText (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V373.RichText.RichText (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V373.Id.Viewing_DiscordDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V373.RichText.RichText (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Maybe Evergreen.V373.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Maybe Evergreen.V373.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V373.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V373.SessionIdHash.SessionIdHash Evergreen.V373.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V373.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V373.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V373.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V373.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V373.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Bool Evergreen.V373.ChannelName.ChannelName (Evergreen.V373.Discord.OptionalData (Maybe String)) (List Evergreen.V373.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
        (Evergreen.V373.NonemptyDict.NonemptyDict
            (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) Evergreen.V373.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Maybe (Evergreen.V373.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V373.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V373.Log.Log
    | Server_BackupGenerated Evergreen.V373.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V373.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V373.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V373.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V373.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (Evergreen.V373.Discord.OptionalData (Maybe String)) (Evergreen.V373.Discord.OptionalData (Maybe String)) (List Evergreen.V373.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.RoleId) Evergreen.V373.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
        (Evergreen.V373.MembersAndOwner.MembersAndOwner
            (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V373.Discord.Id Evergreen.V373.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.PersonName.PersonName Evergreen.V373.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId) Evergreen.V373.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId) Evergreen.V373.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V373.Call.ServerChange
    | Server_Game (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Game.LocalChange
    | Server_Drawing (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Drawing.AnchorType Evergreen.V373.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V373.Id.Viewing_DmId ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V373.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V373.Id.Viewing_DmId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | Server_E2eeAccepted Evergreen.V373.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.User.FrontendUser Effect.Time.Posix Evergreen.V373.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V373.FileStatus.FileHash) (Evergreen.V373.Encryption.EncryptedData (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))) Evergreen.V373.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.Viewing_DmId Evergreen.V373.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V373.FileStatus.FileHash) (Evergreen.V373.Encryption.EncryptedData (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V373.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V373.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V373.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V373.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V373.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V373.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V373.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V373.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V373.Id.AnyGuildOrDmId Evergreen.V373.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V373.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels) (Maybe Evergreen.V373.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V373.SheepGame.Input (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels) (Maybe Evergreen.V373.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V373.Id.GuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V373.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V373.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V373.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V373.Id.Id Evergreen.V373.Id.UserId
    , threadRoute : Evergreen.V373.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V373.Encryption.BytesHash
    , id : Evergreen.V373.Id.Viewing_DmId
    , senderId : Evergreen.V373.Id.Id Evergreen.V373.Id.UserId
    , threadRoute : Evergreen.V373.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V373.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V373.Id.Viewing_DmId
    , messages : List Evergreen.V373.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V373.Id.Viewing_DmId
    , messages : List ( Evergreen.V373.Id.ThreadRouteWithMessage, Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V373.Id.Viewing_DmId
    , threadRoute : Evergreen.V373.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute )
    , fileId : Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V373.Id.Id Evergreen.V373.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V373.Id.Id Evergreen.V373.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V373.Id.Id Evergreen.V373.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V373.Id.Id Evergreen.V373.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V373.Id.Id Evergreen.V373.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V373.Local.Local LocalMsg Evergreen.V373.LocalState.LocalState
    , admin : Evergreen.V373.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V373.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V373.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V373.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V373.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V373.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.ThreadRoute ) (Evergreen.V373.NonemptyDict.NonemptyDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V373.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V373.Scroll.ScrollPosition
    , textEditor : Evergreen.V373.TextEditor.Model
    , profilePictureEditor : Evergreen.V373.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId, Evergreen.V373.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V373.Emoji.Model
    , voiceChat : Evergreen.V373.Call.Model
    , games : SeqDict.SeqDict Evergreen.V373.Id.GuildOrDmId Evergreen.V373.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V373.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V373.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V373.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V373.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V373.Range.Range
                , direction : Evergreen.V373.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V373.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V373.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V373.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V373.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V373.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V373.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V373.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V373.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V373.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V373.MyUi.LastCopy
    , drag : Evergreen.V373.Touch.Drag
    , dragPrevious : Evergreen.V373.Touch.Drag
    , aiChatModel : Evergreen.V373.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V373.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V373.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V373.Audio.LoadError Evergreen.V373.Audio.Source
    , startupData : Evergreen.V373.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V373.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V373.Id.Id Evergreen.V373.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V373.Id.Id Evergreen.V373.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V373.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V373.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V373.FileStatus.FileHash
    , metadata : Maybe Evergreen.V373.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId, Evergreen.V373.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId, Evergreen.V373.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V373.DmChannelId.DmChannelId, Evergreen.V373.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId, Evergreen.V373.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId, Evergreen.V373.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId, Evergreen.V373.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V373.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V373.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V373.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V373.NonemptyDict.NonemptyDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V373.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V373.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V373.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V373.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V373.DmChannelId.DmChannelId Evergreen.V373.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) Evergreen.V373.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V373.OneToOne.OneToOne (Evergreen.V373.Slack.Id Evergreen.V373.Slack.ChannelId) Evergreen.V373.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V373.OneToOne.OneToOne String (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    , slackUsers : Evergreen.V373.OneToOne.OneToOne (Evergreen.V373.Slack.Id Evergreen.V373.Slack.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    , slackServers : Evergreen.V373.OneToOne.OneToOne (Evergreen.V373.Slack.Id Evergreen.V373.Slack.TeamId) (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    , slackToken : Maybe Evergreen.V373.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V373.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V373.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V373.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V373.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId, Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V373.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V373.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V373.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V373.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.LocalState.LoadingDiscordChannel Evergreen.V373.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V373.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId) Evergreen.V373.Sticker.StickerData
    , discordStickers : Evergreen.V373.OneToOne.OneToOne (Evergreen.V373.Discord.Id Evergreen.V373.Discord.StickerId) (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId) Evergreen.V373.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V373.OneToOne.OneToOne Evergreen.V373.RichText.DiscordCustomEmojiIdAndName (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V373.Postmark.ApiKey
    , serverSecret : Evergreen.V373.SecretId.SecretId Evergreen.V373.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V373.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V373.OneToOne.OneToOne (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.GamePublicId) ( Evergreen.V373.DmChannelId.GuildOrFullDmId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V373.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V373.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V373.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.Id.ThreadRoute (Maybe Evergreen.V373.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V373.DmChannelId.DmChannelId Evergreen.V373.Id.ThreadRoute (Maybe Evergreen.V373.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V373.Id.Id Evergreen.V373.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V373.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V373.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V373.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V373.Untrusted.Untrusted Evergreen.V373.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V373.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V373.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V373.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V373.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V373.PersonName.PersonName Evergreen.V373.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V373.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V373.Slack.OAuthCode Evergreen.V373.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V373.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V373.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V373.Id.Id Evergreen.V373.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V373.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V373.EmailAddress.EmailAddress (Result Evergreen.V373.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V373.EmailAddress.EmailAddress (Result Evergreen.V373.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V373.EmailAddress.EmailAddress (Result Evergreen.V373.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V373.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMaybeMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Result Evergreen.V373.Discord.HttpError Evergreen.V373.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V373.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Result Evergreen.V373.Discord.HttpError Evergreen.V373.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) (Result Evergreen.V373.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) (Result Evergreen.V373.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) (Result Evergreen.V373.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) (Result Evergreen.V373.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji (Result Evergreen.V373.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji (Result Evergreen.V373.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji (Result Evergreen.V373.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji (Result Evergreen.V373.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V373.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V373.Discord.HttpError (List ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId, Maybe Evergreen.V373.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Effect.Time.Posix Evergreen.V373.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V373.Slack.CurrentUser
            , team : Evergreen.V373.Slack.Team
            , users : List Evergreen.V373.Slack.User
            , channels : List ( Evergreen.V373.Slack.Channel, List Evergreen.V373.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Result Effect.Http.Error Evergreen.V373.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Discord.UserAuth (Result Evergreen.V373.Discord.HttpError Evergreen.V373.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Result Evergreen.V373.Discord.HttpError Evergreen.V373.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
        (Result
            Evergreen.V373.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId
                , members : List (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
                }
            , List
                ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId
                , { guild : Evergreen.V373.Discord.GatewayGuild
                  , channels : List Evergreen.V373.Discord.Channel
                  , icon : Maybe Evergreen.V373.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V373.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V373.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.AttachmentId, Evergreen.V373.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V373.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.AttachmentId, Evergreen.V373.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V373.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V373.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V373.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V373.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) (Result Evergreen.V373.Discord.HttpError Evergreen.V373.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Result Evergreen.V373.Discord.HttpError (List Evergreen.V373.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V373.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V373.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V373.DmChannelId.DmChannelId Evergreen.V373.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V373.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V373.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V373.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
        (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V373.Discord.HttpError
            { guild : Evergreen.V373.Discord.GatewayGuild
            , channels : List Evergreen.V373.Discord.Channel
            , icon : Maybe Evergreen.V373.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Result Evergreen.V373.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V373.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (List ( Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId, Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId, Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (List ( Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V373.Discord.HttpError (List Evergreen.V373.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V373.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V373.SecretId.SecretId Evergreen.V373.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V373.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Result Evergreen.V373.Discord.HttpError ( Evergreen.V373.Discord.Guild, List Evergreen.V373.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V373.FileStatus.FileHash Int (Maybe (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Call.CallId
