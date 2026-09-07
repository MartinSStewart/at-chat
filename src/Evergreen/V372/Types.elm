module Evergreen.V372.Types exposing (..)

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
import Evergreen.V372.AiChat
import Evergreen.V372.Audio
import Evergreen.V372.Call
import Evergreen.V372.ChannelDescription
import Evergreen.V372.ChannelName
import Evergreen.V372.Coord
import Evergreen.V372.CssPixels
import Evergreen.V372.CustomEmoji
import Evergreen.V372.Discord
import Evergreen.V372.DiscordAttachmentId
import Evergreen.V372.DiscordUserData
import Evergreen.V372.DmChannel
import Evergreen.V372.DmChannelId
import Evergreen.V372.Drawing
import Evergreen.V372.Editable
import Evergreen.V372.EmailAddress
import Evergreen.V372.Embed
import Evergreen.V372.Emoji
import Evergreen.V372.Encryption
import Evergreen.V372.FileStatus
import Evergreen.V372.Game
import Evergreen.V372.Go
import Evergreen.V372.GuildName
import Evergreen.V372.Id
import Evergreen.V372.IdArray
import Evergreen.V372.ImageEditor
import Evergreen.V372.ImageViewer
import Evergreen.V372.LinkedAndOtherDiscordUsers
import Evergreen.V372.Local
import Evergreen.V372.LocalState
import Evergreen.V372.Log
import Evergreen.V372.LoginForm
import Evergreen.V372.MembersAndOwner
import Evergreen.V372.Message
import Evergreen.V372.MessageInput
import Evergreen.V372.MessageView
import Evergreen.V372.MuteSettings
import Evergreen.V372.MyUi
import Evergreen.V372.NonemptyDict
import Evergreen.V372.NonemptySet
import Evergreen.V372.OneOrGreater
import Evergreen.V372.OneToOne
import Evergreen.V372.Pages.Admin
import Evergreen.V372.Pagination
import Evergreen.V372.PersonName
import Evergreen.V372.Ports
import Evergreen.V372.Postmark
import Evergreen.V372.Range
import Evergreen.V372.RecoveryLogin
import Evergreen.V372.RichText
import Evergreen.V372.Route
import Evergreen.V372.Scroll
import Evergreen.V372.SecretId
import Evergreen.V372.SessionIdHash
import Evergreen.V372.SheepGame
import Evergreen.V372.Slack
import Evergreen.V372.Sticker
import Evergreen.V372.TextEditor
import Evergreen.V372.ToBackendLog
import Evergreen.V372.Touch
import Evergreen.V372.TwoFactorAuthentication
import Evergreen.V372.Ui.Anim
import Evergreen.V372.Untrusted
import Evergreen.V372.User
import Evergreen.V372.UserAgent
import Evergreen.V372.UserColor
import Evergreen.V372.UserSession
import Evergreen.V372.WordSpellingGame
import Evergreen.V372.X25519
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
    | LoginFormMsg Evergreen.V372.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V372.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V372.Pages.Admin.Msg
    | PressedLogOut Evergreen.V372.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V372.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V372.Route.Route
    | SelectedFilesToAttach ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V372.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V372.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V372.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V372.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V372.NonemptyDict.NonemptyDict Int Evergreen.V372.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V372.NonemptyDict.NonemptyDict Int Evergreen.V372.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRoute Evergreen.V372.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V372.NonemptySet.NonemptySet (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V372.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V372.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V372.AiChat.Msg
    | GameMsg Evergreen.V372.Game.Msg
    | GoSpectatorMsg Evergreen.V372.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V372.Editable.Msg Evergreen.V372.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V372.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) (Maybe Evergreen.V372.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute )
        { fileId : Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute )
        { fileId : Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage Evergreen.V372.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V372.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V372.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V372.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V372.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V372.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V372.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | PressedDisableE2ee (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | TypedPrivateKey (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V372.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId
        , otherUserId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V372.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRoute Evergreen.V372.MessageInput.Msg
    | MessageInputMsg Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRoute Evergreen.V372.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V372.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V372.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V372.Range.Range, Evergreen.V372.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V372.Range.Range, Evergreen.V372.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V372.Call.FromJs)
    | VoiceChatMsg Evergreen.V372.Call.Msg
    | PressedChannelHeaderTab Evergreen.V372.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V372.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V372.Audio.LoadError Evergreen.V372.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V372.Id.AnyGuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V372.Id.AnyGuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) Evergreen.V372.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V372.Encryption.FromJs (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V372.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V372.UserSession.UserSession
    , currentlyViewing : Evergreen.V372.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) Evergreen.V372.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.LocalState.DiscordFrontendGuild
    , user : Evergreen.V372.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.User.FrontendUser
    , discordUsers : Evergreen.V372.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V372.SessionIdHash.SessionIdHash Evergreen.V372.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V372.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId) Evergreen.V372.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId) Evergreen.V372.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V372.Call.CallId (Evergreen.V372.NonemptyDict.NonemptyDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V372.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V372.Go.PublicGoMatchData Evergreen.V372.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V372.Route.Route
    , windowSize : Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V372.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V372.Audio.LoadError Evergreen.V372.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Encryption.EncryptedData (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.NonemptyDict.NonemptyDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Encryption.EncryptedData (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V372.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V372.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V372.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileData) (List Evergreen.V372.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V372.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V372.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.ChannelName.ChannelName Evergreen.V372.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.ChannelName.ChannelName Evergreen.V372.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V372.GuildName.GuildName (Evergreen.V372.UserSession.ToBeFilledInByBackend (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V372.Id.Viewing_DiscordDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V372.UserSession.SetViewing
    | Local_SetName Evergreen.V372.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V372.Id.GuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V372.Id.GuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V372.Id.DiscordGuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V372.Id.DiscordGuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V372.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V372.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V372.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.QuestionId Evergreen.V372.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V372.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V372.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V372.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V372.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V372.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V372.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V372.NonemptySet.NonemptySet (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V372.Call.LocalChange
    | Local_Game Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Game.LocalChange
    | Local_Drawing Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Drawing.AnchorType Evergreen.V372.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V372.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V372.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V372.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V372.X25519.PublicKey (Evergreen.V372.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V372.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V372.Id.Viewing_DmId (List ( Evergreen.V372.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V372.FileStatus.FileHash, Evergreen.V372.Encryption.EncryptedData (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V372.Id.Viewing_DmId (Evergreen.V372.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V372.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V372.Id.ThreadRouteWithMessage, Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V372.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V372.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V372.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V372.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V372.FileStatus.FileHash) (Evergreen.V372.Encryption.EncryptedData (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))) Evergreen.V372.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V372.Id.Viewing_DmId Evergreen.V372.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V372.FileStatus.FileHash) (Evergreen.V372.Encryption.EncryptedData (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.User.FrontendUser Effect.Time.Posix Evergreen.V372.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V372.RichText.RichText (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))) Evergreen.V372.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId) Evergreen.V372.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V372.Id.DiscordGuildOrDmId Evergreen.V372.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V372.RichText.RichText (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))) Evergreen.V372.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId) Evergreen.V372.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.ChannelName.ChannelName Evergreen.V372.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.ChannelName.ChannelName Evergreen.V372.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.User.FrontendUser
    | Server_MemberLeft (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V372.LocalState.JoinGuildError
            { guildId : Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId
            , guild : Evergreen.V372.LocalState.FrontendGuild
            , owner : Evergreen.V372.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V372.RichText.RichText (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V372.RichText.RichText (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V372.Id.Viewing_DiscordDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V372.RichText.RichText (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Maybe Evergreen.V372.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Maybe Evergreen.V372.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V372.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V372.SessionIdHash.SessionIdHash Evergreen.V372.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V372.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V372.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V372.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V372.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V372.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Bool Evergreen.V372.ChannelName.ChannelName (Evergreen.V372.Discord.OptionalData (Maybe String)) (List Evergreen.V372.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
        (Evergreen.V372.NonemptyDict.NonemptyDict
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) Evergreen.V372.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Maybe (Evergreen.V372.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V372.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V372.Log.Log
    | Server_BackupGenerated Evergreen.V372.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V372.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V372.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V372.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V372.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (Evergreen.V372.Discord.OptionalData (Maybe String)) (Evergreen.V372.Discord.OptionalData (Maybe String)) (List Evergreen.V372.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId) Evergreen.V372.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
        (Evergreen.V372.MembersAndOwner.MembersAndOwner
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.PersonName.PersonName Evergreen.V372.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId) Evergreen.V372.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId) Evergreen.V372.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V372.Call.ServerChange
    | Server_Game (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Game.LocalChange
    | Server_Drawing (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Drawing.AnchorType Evergreen.V372.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V372.Id.Viewing_DmId ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V372.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V372.Id.Viewing_DmId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | Server_E2eeAccepted Evergreen.V372.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.User.FrontendUser Effect.Time.Posix Evergreen.V372.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V372.FileStatus.FileHash) (Evergreen.V372.Encryption.EncryptedData (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))) Evergreen.V372.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.Viewing_DmId Evergreen.V372.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V372.FileStatus.FileHash) (Evergreen.V372.Encryption.EncryptedData (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V372.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V372.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V372.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V372.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V372.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V372.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V372.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V372.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V372.Id.AnyGuildOrDmId Evergreen.V372.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V372.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels) (Maybe Evergreen.V372.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V372.SheepGame.Input (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels) (Maybe Evergreen.V372.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V372.Id.GuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V372.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V372.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V372.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , threadRoute : Evergreen.V372.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V372.Encryption.BytesHash
    , id : Evergreen.V372.Id.Viewing_DmId
    , senderId : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , threadRoute : Evergreen.V372.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V372.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V372.Id.Viewing_DmId
    , messages : List Evergreen.V372.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V372.Id.Viewing_DmId
    , messages : List ( Evergreen.V372.Id.ThreadRouteWithMessage, Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V372.Id.Viewing_DmId
    , threadRoute : Evergreen.V372.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute )
    , fileId : Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Encryption.EncryptRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V372.Id.Id Evergreen.V372.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V372.Id.Id Evergreen.V372.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V372.Id.Id Evergreen.V372.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V372.Id.Id Evergreen.V372.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V372.Id.Id Evergreen.V372.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V372.Local.Local LocalMsg Evergreen.V372.LocalState.LocalState
    , admin : Evergreen.V372.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V372.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V372.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V372.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V372.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V372.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.ThreadRoute ) (Evergreen.V372.NonemptyDict.NonemptyDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V372.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V372.Scroll.ScrollPosition
    , textEditor : Evergreen.V372.TextEditor.Model
    , profilePictureEditor : Evergreen.V372.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId, Evergreen.V372.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V372.Emoji.Model
    , voiceChat : Evergreen.V372.Call.Model
    , games : SeqDict.SeqDict Evergreen.V372.Id.GuildOrDmId Evergreen.V372.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V372.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V372.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V372.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V372.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V372.Range.Range
                , direction : Evergreen.V372.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V372.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V372.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V372.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V372.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V372.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V372.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V372.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V372.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V372.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V372.MyUi.LastCopy
    , drag : Evergreen.V372.Touch.Drag
    , dragPrevious : Evergreen.V372.Touch.Drag
    , aiChatModel : Evergreen.V372.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V372.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V372.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V372.Audio.LoadError Evergreen.V372.Audio.Source
    , startupData : Evergreen.V372.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V372.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V372.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V372.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V372.FileStatus.FileHash
    , metadata : Maybe Evergreen.V372.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId, Evergreen.V372.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId, Evergreen.V372.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V372.DmChannelId.DmChannelId, Evergreen.V372.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId, Evergreen.V372.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId, Evergreen.V372.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId, Evergreen.V372.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V372.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V372.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V372.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V372.NonemptyDict.NonemptyDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V372.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V372.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V372.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V372.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V372.DmChannelId.DmChannelId Evergreen.V372.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) Evergreen.V372.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.Slack.Id Evergreen.V372.Slack.ChannelId) Evergreen.V372.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V372.OneToOne.OneToOne String (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    , slackUsers : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.Slack.Id Evergreen.V372.Slack.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    , slackServers : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.Slack.Id Evergreen.V372.Slack.TeamId) (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    , slackToken : Maybe Evergreen.V372.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V372.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V372.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V372.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V372.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId, Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V372.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V372.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V372.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V372.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.LocalState.LoadingDiscordChannel Evergreen.V372.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V372.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId) Evergreen.V372.Sticker.StickerData
    , discordStickers : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.Discord.Id Evergreen.V372.Discord.StickerId) (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId) Evergreen.V372.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V372.OneToOne.OneToOne Evergreen.V372.RichText.DiscordCustomEmojiIdAndName (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V372.Postmark.ApiKey
    , serverSecret : Evergreen.V372.SecretId.SecretId Evergreen.V372.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V372.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.GamePublicId) ( Evergreen.V372.DmChannelId.GuildOrFullDmId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V372.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V372.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V372.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.Id.ThreadRoute (Maybe Evergreen.V372.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V372.DmChannelId.DmChannelId Evergreen.V372.Id.ThreadRoute (Maybe Evergreen.V372.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V372.Id.Id Evergreen.V372.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V372.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V372.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V372.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V372.Untrusted.Untrusted Evergreen.V372.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V372.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V372.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V372.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V372.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V372.PersonName.PersonName Evergreen.V372.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V372.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V372.Slack.OAuthCode Evergreen.V372.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V372.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V372.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V372.Id.Id Evergreen.V372.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V372.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V372.EmailAddress.EmailAddress (Result Evergreen.V372.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V372.EmailAddress.EmailAddress (Result Evergreen.V372.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V372.EmailAddress.EmailAddress (Result Evergreen.V372.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V372.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMaybeMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Result Evergreen.V372.Discord.HttpError Evergreen.V372.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V372.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Result Evergreen.V372.Discord.HttpError Evergreen.V372.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) (Result Evergreen.V372.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) (Result Evergreen.V372.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) (Result Evergreen.V372.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) (Result Evergreen.V372.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji (Result Evergreen.V372.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji (Result Evergreen.V372.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji (Result Evergreen.V372.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji (Result Evergreen.V372.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V372.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V372.Discord.HttpError (List ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId, Maybe Evergreen.V372.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Effect.Time.Posix Evergreen.V372.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V372.Slack.CurrentUser
            , team : Evergreen.V372.Slack.Team
            , users : List Evergreen.V372.Slack.User
            , channels : List ( Evergreen.V372.Slack.Channel, List Evergreen.V372.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Result Effect.Http.Error Evergreen.V372.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Discord.UserAuth (Result Evergreen.V372.Discord.HttpError Evergreen.V372.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Result Evergreen.V372.Discord.HttpError Evergreen.V372.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
        (Result
            Evergreen.V372.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId
                , members : List (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
                }
            , List
                ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId
                , { guild : Evergreen.V372.Discord.GatewayGuild
                  , channels : List Evergreen.V372.Discord.Channel
                  , icon : Maybe Evergreen.V372.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V372.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V372.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.AttachmentId, Evergreen.V372.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V372.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.AttachmentId, Evergreen.V372.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V372.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V372.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V372.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V372.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (Result Evergreen.V372.Discord.HttpError Evergreen.V372.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Result Evergreen.V372.Discord.HttpError (List Evergreen.V372.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V372.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V372.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V372.DmChannelId.DmChannelId Evergreen.V372.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V372.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V372.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V372.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
        (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V372.Discord.HttpError
            { guild : Evergreen.V372.Discord.GatewayGuild
            , channels : List Evergreen.V372.Discord.Channel
            , icon : Maybe Evergreen.V372.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Result Evergreen.V372.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V372.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (List ( Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId, Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId, Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (List ( Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V372.Discord.HttpError (List Evergreen.V372.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V372.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V372.SecretId.SecretId Evergreen.V372.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V372.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Result Evergreen.V372.Discord.HttpError ( Evergreen.V372.Discord.Guild, List Evergreen.V372.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V372.FileStatus.FileHash Int (Maybe (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Call.CallId
