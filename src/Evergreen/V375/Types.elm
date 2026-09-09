module Evergreen.V375.Types exposing (..)

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
import Evergreen.V375.AiChat
import Evergreen.V375.Audio
import Evergreen.V375.Call
import Evergreen.V375.ChannelDescription
import Evergreen.V375.ChannelName
import Evergreen.V375.Coord
import Evergreen.V375.CssPixels
import Evergreen.V375.CustomEmoji
import Evergreen.V375.Discord
import Evergreen.V375.DiscordAttachmentId
import Evergreen.V375.DiscordUserData
import Evergreen.V375.DmChannel
import Evergreen.V375.DmChannelId
import Evergreen.V375.Drawing
import Evergreen.V375.Editable
import Evergreen.V375.EmailAddress
import Evergreen.V375.Embed
import Evergreen.V375.Emoji
import Evergreen.V375.Encryption
import Evergreen.V375.FileStatus
import Evergreen.V375.Game
import Evergreen.V375.Go
import Evergreen.V375.GuildName
import Evergreen.V375.Id
import Evergreen.V375.IdArray
import Evergreen.V375.ImageEditor
import Evergreen.V375.ImageViewer
import Evergreen.V375.LinkedAndOtherDiscordUsers
import Evergreen.V375.Local
import Evergreen.V375.LocalState
import Evergreen.V375.Log
import Evergreen.V375.LoginForm
import Evergreen.V375.MembersAndOwner
import Evergreen.V375.Message
import Evergreen.V375.MessageInput
import Evergreen.V375.MessageView
import Evergreen.V375.MuteSettings
import Evergreen.V375.MyUi
import Evergreen.V375.NonemptyDict
import Evergreen.V375.NonemptySet
import Evergreen.V375.OneOrGreater
import Evergreen.V375.OneToOne
import Evergreen.V375.Pages.Admin
import Evergreen.V375.Pagination
import Evergreen.V375.PersonName
import Evergreen.V375.Ports
import Evergreen.V375.Postmark
import Evergreen.V375.Range
import Evergreen.V375.RecoveryLogin
import Evergreen.V375.RichText
import Evergreen.V375.Route
import Evergreen.V375.Scroll
import Evergreen.V375.SecretId
import Evergreen.V375.SessionIdHash
import Evergreen.V375.SheepGame
import Evergreen.V375.Slack
import Evergreen.V375.Sticker
import Evergreen.V375.TextEditor
import Evergreen.V375.ToBackendLog
import Evergreen.V375.Touch
import Evergreen.V375.TwoFactorAuthentication
import Evergreen.V375.Ui.Anim
import Evergreen.V375.Untrusted
import Evergreen.V375.User
import Evergreen.V375.UserAgent
import Evergreen.V375.UserColor
import Evergreen.V375.UserSession
import Evergreen.V375.WordSpellingGame
import Evergreen.V375.X25519
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
    | LoginFormMsg Evergreen.V375.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V375.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V375.Pages.Admin.Msg
    | PressedLogOut Evergreen.V375.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V375.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V375.Route.Route
    | SelectedFilesToAttach ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V375.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V375.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V375.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V375.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V375.NonemptyDict.NonemptyDict Int Evergreen.V375.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V375.NonemptyDict.NonemptyDict Int Evergreen.V375.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRoute Evergreen.V375.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V375.NonemptySet.NonemptySet (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V375.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V375.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V375.AiChat.Msg
    | GameMsg Evergreen.V375.Game.Msg
    | GoSpectatorMsg Evergreen.V375.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V375.Editable.Msg Evergreen.V375.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V375.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileToEncrypt ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) String Bytes.Bytes
    | GotFileHashName ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) (Maybe Evergreen.V375.FileStatus.FileMetadata) (Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute )
        { fileId : Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute )
        { fileId : Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage Evergreen.V375.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V375.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V375.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V375.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V375.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V375.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V375.Id.ExportChannelId
    | PressedAddPrivateKeyToAccount
    | PressedCloseNewPrivateKey
    | PressedExpandE2eeSection (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | PressedE2eeRisksAccepted Bool
    | PressedEnableE2ee (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | PressedCancelE2eeRequest (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | PressedDisableE2ee (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | PressedDeclineE2eeRequest (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | TypedPrivateKey (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) String
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V375.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId
        , otherUserId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V375.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRoute Evergreen.V375.MessageInput.Msg
    | MessageInputMsg Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRoute Evergreen.V375.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V375.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V375.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V375.Range.Range, Evergreen.V375.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V375.Range.Range, Evergreen.V375.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V375.Call.FromJs)
    | VoiceChatMsg Evergreen.V375.Call.Msg
    | PressedChannelHeaderTab Evergreen.V375.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V375.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V375.Audio.LoadError Evergreen.V375.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V375.Id.AnyGuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V375.Id.AnyGuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) Evergreen.V375.MessageView.MessageViewMsg
    | ValidatedE2eePrivateKey String E2eeKeysValid
    | EncryptionFromJs (Result String (Evergreen.V375.Encryption.FromJs (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))))


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V375.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V375.UserSession.UserSession
    , currentlyViewing : Evergreen.V375.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) Evergreen.V375.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.LocalState.DiscordFrontendGuild
    , user : Evergreen.V375.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.User.FrontendUser
    , discordUsers : Evergreen.V375.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V375.SessionIdHash.SessionIdHash Evergreen.V375.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V375.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId) Evergreen.V375.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId) Evergreen.V375.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V375.Call.CallId (Evergreen.V375.NonemptyDict.NonemptyDict ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V375.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V375.Go.PublicGoMatchData Evergreen.V375.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V375.Route.Route
    , windowSize : Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V375.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V375.Audio.LoadError Evergreen.V375.Audio.Source
    }


type alias ChannelDataToEncrypt =
    { channel : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)))
    }


type alias ChannelDataToDecrypt =
    { channel : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Encryption.EncryptedData (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)))
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.NonemptyDict.NonemptyDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) (Evergreen.V375.Encryption.EncryptedData (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))))
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V375.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V375.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V375.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData) (List Evergreen.V375.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V375.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V375.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.ChannelName.ChannelName Evergreen.V375.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.ChannelName.ChannelName Evergreen.V375.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V375.GuildName.GuildName (Evergreen.V375.UserSession.ToBeFilledInByBackend (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V375.Id.Viewing_DiscordDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V375.UserSession.SetViewing
    | Local_SetName Evergreen.V375.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V375.Id.GuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V375.Id.GuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) (Evergreen.V375.Message.Message Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V375.Id.DiscordGuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V375.Id.DiscordGuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) (Evergreen.V375.Message.Message Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V375.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V375.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V375.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.QuestionId Evergreen.V375.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V375.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V375.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V375.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V375.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V375.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V375.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V375.NonemptySet.NonemptySet (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V375.Call.LocalChange
    | Local_Game Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Game.LocalChange
    | Local_Drawing Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Drawing.AnchorType Evergreen.V375.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.MuteSettings.IsMuted
    | Local_RequestE2ee Evergreen.V375.Id.Viewing_DmId
    | Local_DeclineE2eeRequestAsInitiator Evergreen.V375.Id.Viewing_DmId
    | Local_DeclineE2eeRequest Evergreen.V375.Id.Viewing_DmId
    | Local_SetPublicKey Evergreen.V375.X25519.PublicKey (Evergreen.V375.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V375.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_EncryptOldMessages Evergreen.V375.Id.Viewing_DmId (List ( Evergreen.V375.Id.ThreadRouteWithMessage, SeqSet.SeqSet Evergreen.V375.FileStatus.FileHash, Evergreen.V375.Encryption.EncryptedData (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)) ))
    | Local_DisableE2ee Evergreen.V375.Id.Viewing_DmId (Evergreen.V375.UserSession.ToBeFilledInByBackend ChannelDataToDecrypt)
    | Local_DecryptOldMessages Evergreen.V375.Id.Viewing_DmId Effect.Time.Posix (List ( Evergreen.V375.Id.ThreadRouteWithMessage, Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) ))
    | Local_SetE2eeRisksAccepted Bool
    | Local_AcceptE2ee Evergreen.V375.Id.Viewing_DmId Effect.Time.Posix (Evergreen.V375.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V375.Id.Viewing_DmId ChannelDataToEncrypt))
    | Local_SendEncryptedMessage Effect.Time.Posix Evergreen.V375.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V375.FileStatus.FileHash) (Evergreen.V375.Encryption.EncryptedData (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))) (Evergreen.V375.Encryption.EncryptedData String) Evergreen.V375.Id.ThreadRouteWithMaybeMessage
    | Local_SendEncryptedEditMessage Effect.Time.Posix Evergreen.V375.Id.Viewing_DmId Evergreen.V375.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V375.FileStatus.FileHash) (Evergreen.V375.Encryption.EncryptedData (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)))


type ServerChange
    = Server_SendMessage (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.User.FrontendUser Effect.Time.Posix Evergreen.V375.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V375.RichText.RichText (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))) Evergreen.V375.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId) Evergreen.V375.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V375.Id.DiscordGuildOrDmId Evergreen.V375.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V375.RichText.RichText (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))) Evergreen.V375.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId) Evergreen.V375.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.ChannelName.ChannelName Evergreen.V375.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.ChannelName.ChannelName Evergreen.V375.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.User.FrontendUser
    | Server_MemberLeft (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V375.LocalState.JoinGuildError
            { guildId : Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId
            , guild : Evergreen.V375.LocalState.FrontendGuild
            , owner : Evergreen.V375.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V375.RichText.RichText (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))) (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V375.RichText.RichText (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V375.Id.Viewing_DiscordDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V375.RichText.RichText (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Maybe Evergreen.V375.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Maybe Evergreen.V375.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V375.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V375.SessionIdHash.SessionIdHash Evergreen.V375.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V375.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V375.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V375.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V375.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V375.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Bool Evergreen.V375.ChannelName.ChannelName (Evergreen.V375.Discord.OptionalData (Maybe String)) (List Evergreen.V375.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
        (Evergreen.V375.NonemptyDict.NonemptyDict
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) Evergreen.V375.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Maybe (Evergreen.V375.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V375.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V375.Log.Log
    | Server_BackupGenerated Evergreen.V375.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V375.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V375.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V375.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V375.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (Evergreen.V375.Discord.OptionalData (Maybe String)) (Evergreen.V375.Discord.OptionalData (Maybe String)) (List Evergreen.V375.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId) Evergreen.V375.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
        (Evergreen.V375.MembersAndOwner.MembersAndOwner
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.PersonName.PersonName Evergreen.V375.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId) Evergreen.V375.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId) Evergreen.V375.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V375.Call.ServerChange
    | Server_Game (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Game.LocalChange
    | Server_Drawing (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Drawing.AnchorType Evergreen.V375.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.UserSession.DiscordFrontendUser
    | Server_E2eeRequested Evergreen.V375.Id.Viewing_DmId ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Evergreen.V375.SessionIdHash.SessionIdHash )
    | Server_E2eeRequestCancelled Evergreen.V375.Id.Viewing_DmId
    | Server_E2eeRequestDeclined Evergreen.V375.Id.Viewing_DmId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | Server_E2eeAccepted Evergreen.V375.Id.Viewing_DmId Effect.Time.Posix
    | Server_SetPublicKey (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.X25519.PublicKey
    | Server_SendEncryptedMessage (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.User.FrontendUser Effect.Time.Posix Evergreen.V375.Id.Viewing_DmId (SeqSet.SeqSet Evergreen.V375.FileStatus.FileHash) (Evergreen.V375.Encryption.EncryptedData (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))) Evergreen.V375.Id.ThreadRouteWithMaybeMessage
    | Server_SendEncryptedEditMessage Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.Viewing_DmId Evergreen.V375.Id.ThreadRouteWithMessage (SeqSet.SeqSet Evergreen.V375.FileStatus.FileHash) (Evergreen.V375.Encryption.EncryptedData (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)))
    | Server_DisableE2ee Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.Viewing_DmId


type LocalMsg
    = LocalChange (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V375.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V375.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V375.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V375.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V375.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V375.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V375.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V375.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V375.Id.AnyGuildOrDmId Evergreen.V375.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V375.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels) (Maybe Evergreen.V375.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V375.SheepGame.Input (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels) (Maybe Evergreen.V375.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V375.Id.GuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId) (Evergreen.V375.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V375.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V375.UserColor.Selection
    , e2eeKeysValid : E2eeKeysValid
    , privateKeyText : String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V375.OneOrGreater.OneOrGreater


type alias PendingEncryptedMessage =
    { otherUserId : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , threadRoute : Evergreen.V375.Id.ThreadRouteWithMaybeMessage
    , contentAndEmbeds : Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    }


type alias PendingDecryptedMessage =
    { hash : Evergreen.V375.Encryption.BytesHash
    , id : Evergreen.V375.Id.Viewing_DmId
    , senderId : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , threadRoute : Evergreen.V375.Id.ThreadRouteWithMaybeMessage
    }


type alias PendingDecryptedManyMessages =
    { messageHashes : List Evergreen.V375.Encryption.BytesHash
    , shiftScrollFrom : Maybe Effect.Browser.Dom.HtmlId
    }


type alias PendingDecryptedOldMessages =
    { id : Evergreen.V375.Id.Viewing_DmId
    , messages : List Evergreen.V375.Id.ThreadRouteWithMessage
    }


type alias PendingEncryptedManyMessages =
    { id : Evergreen.V375.Id.Viewing_DmId
    , messages : List ( Evergreen.V375.Id.ThreadRouteWithMessage, Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) )
    }


type alias PendingEncryptedEdit =
    { id : Evergreen.V375.Id.Viewing_DmId
    , threadRoute : Evergreen.V375.Id.ThreadRouteWithMessage
    , contentAndEmbeds : Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    }


type alias PendingEncryptedFile =
    { guildOrDmId : ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute )
    , fileId : Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId
    }


type alias EncryptionRequests =
    { pendingEncryptedMessages : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Encryption.EncryptManyRequestId) PendingEncryptedMessage
    , nextEncryptionRequestId : Evergreen.V375.Id.Id Evergreen.V375.Encryption.EncryptRequestId
    , pendingDecryptedMessages : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Encryption.DecryptRequestId) PendingDecryptedMessage
    , nextDecryptionRequestId : Evergreen.V375.Id.Id Evergreen.V375.Encryption.DecryptRequestId
    , pendingDecryptedManyMessages : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Encryption.DecryptManyRequestId) PendingDecryptedManyMessages
    , pendingDecryptedOldMessages : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Encryption.DecryptManyRequestId) PendingDecryptedOldMessages
    , nextDecryptManyRequestId : Evergreen.V375.Id.Id Evergreen.V375.Encryption.DecryptManyRequestId
    , pendingEncryptedManyMessages : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Encryption.EncryptManyRequestId) PendingEncryptedManyMessages
    , nextEncryptManyRequestId : Evergreen.V375.Id.Id Evergreen.V375.Encryption.EncryptManyRequestId
    , pendingEncryptedEdits : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Encryption.EncryptRequestId) PendingEncryptedEdit
    , pendingEncryptedFiles : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Encryption.EncryptFileRequestId) PendingEncryptedFile
    , nextEncryptFileRequestId : Evergreen.V375.Id.Id Evergreen.V375.Encryption.EncryptFileRequestId
    }


type alias LoggedIn2 =
    { localState : Evergreen.V375.Local.Local LocalMsg Evergreen.V375.LocalState.LocalState
    , admin : Evergreen.V375.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId, Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V375.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V375.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V375.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V375.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V375.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.ThreadRoute ) (Evergreen.V375.NonemptyDict.NonemptyDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V375.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V375.Scroll.ScrollPosition
    , textEditor : Evergreen.V375.TextEditor.Model
    , profilePictureEditor : Evergreen.V375.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId, Evergreen.V375.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V375.Emoji.Model
    , voiceChat : Evergreen.V375.Call.Model
    , games : SeqDict.SeqDict Evergreen.V375.Id.GuildOrDmId Evergreen.V375.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V375.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , showNewPrivateKey : Maybe Evergreen.V375.X25519.PrivateKey
    , e2eeError : Maybe String
    , e2eePrivateKeyText : String
    , e2eeKeysOnThisDevice : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    , encryptionRequests : EncryptionRequests
    , e2eeSectionsExpanded : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Bool
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V375.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V375.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V375.Range.Range
                , direction : Evergreen.V375.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V375.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V375.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V375.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V375.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V375.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V375.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V375.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V375.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V375.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V375.MyUi.LastCopy
    , drag : Evergreen.V375.Touch.Drag
    , dragPrevious : Evergreen.V375.Touch.Drag
    , aiChatModel : Evergreen.V375.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V375.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V375.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V375.Audio.LoadError Evergreen.V375.Audio.Source
    , startupData : Evergreen.V375.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V375.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V375.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V375.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V375.FileStatus.FileHash
    , metadata : Maybe Evergreen.V375.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId, Evergreen.V375.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId, Evergreen.V375.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V375.DmChannelId.DmChannelId, Evergreen.V375.DmChannel.BackendDmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId, Evergreen.V375.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId, Evergreen.V375.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId, Evergreen.V375.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V375.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V375.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V375.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V375.NonemptyDict.NonemptyDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V375.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V375.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V375.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V375.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V375.DmChannelId.DmChannelId Evergreen.V375.DmChannel.BackendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) Evergreen.V375.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.Slack.Id Evergreen.V375.Slack.ChannelId) Evergreen.V375.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V375.OneToOne.OneToOne String (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    , slackUsers : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.Slack.Id Evergreen.V375.Slack.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    , slackServers : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.Slack.Id Evergreen.V375.Slack.TeamId) (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    , slackToken : Maybe Evergreen.V375.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V375.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V375.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V375.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V375.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId, Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V375.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V375.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V375.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V375.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.LocalState.LoadingDiscordChannel Evergreen.V375.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V375.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId) Evergreen.V375.Sticker.StickerData
    , discordStickers : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.Discord.Id Evergreen.V375.Discord.StickerId) (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId) Evergreen.V375.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V375.OneToOne.OneToOne Evergreen.V375.RichText.DiscordCustomEmojiIdAndName (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V375.Postmark.ApiKey
    , serverSecret : Evergreen.V375.SecretId.SecretId Evergreen.V375.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V375.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.GamePublicId) ( Evergreen.V375.DmChannelId.GuildOrFullDmId, Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V375.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V375.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V375.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.Id.ThreadRoute (Maybe Evergreen.V375.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V375.DmChannelId.DmChannelId Evergreen.V375.Id.ThreadRoute (Maybe Evergreen.V375.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V375.Id.Id Evergreen.V375.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V375.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V375.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V375.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V375.Untrusted.Untrusted Evergreen.V375.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V375.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V375.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V375.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V375.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V375.PersonName.PersonName Evergreen.V375.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V375.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V375.Slack.OAuthCode Evergreen.V375.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V375.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V375.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V375.Id.Id Evergreen.V375.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V375.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V375.EmailAddress.EmailAddress (Result Evergreen.V375.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V375.EmailAddress.EmailAddress (Result Evergreen.V375.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V375.EmailAddress.EmailAddress (Result Evergreen.V375.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V375.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMaybeMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Result Evergreen.V375.Discord.HttpError Evergreen.V375.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V375.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Result Evergreen.V375.Discord.HttpError Evergreen.V375.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) (Result Evergreen.V375.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) (Result Evergreen.V375.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) (Result Evergreen.V375.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) (Result Evergreen.V375.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji (Result Evergreen.V375.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji (Result Evergreen.V375.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji (Result Evergreen.V375.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji (Result Evergreen.V375.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V375.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V375.Discord.HttpError (List ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId, Maybe Evergreen.V375.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Effect.Time.Posix Evergreen.V375.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V375.Slack.CurrentUser
            , team : Evergreen.V375.Slack.Team
            , users : List Evergreen.V375.Slack.User
            , channels : List ( Evergreen.V375.Slack.Channel, List Evergreen.V375.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Result Effect.Http.Error Evergreen.V375.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Discord.UserAuth (Result Evergreen.V375.Discord.HttpError Evergreen.V375.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Result Evergreen.V375.Discord.HttpError Evergreen.V375.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
        (Result
            Evergreen.V375.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId
                , members : List (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
                }
            , List
                ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId
                , { guild : Evergreen.V375.Discord.GatewayGuild
                  , channels : List Evergreen.V375.Discord.Channel
                  , icon : Maybe Evergreen.V375.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V375.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V375.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.AttachmentId, Evergreen.V375.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V375.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.AttachmentId, Evergreen.V375.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V375.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V375.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V375.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V375.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (Result Evergreen.V375.Discord.HttpError Evergreen.V375.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Result Evergreen.V375.Discord.HttpError (List Evergreen.V375.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V375.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V375.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V375.DmChannelId.DmChannelId Evergreen.V375.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V375.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V375.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V375.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
        (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V375.Discord.HttpError
            { guild : Evergreen.V375.Discord.GatewayGuild
            , channels : List Evergreen.V375.Discord.Channel
            , icon : Maybe Evergreen.V375.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Result Evergreen.V375.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V375.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (List ( Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId, Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId, Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (List ( Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V375.Discord.HttpError (List Evergreen.V375.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V375.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V375.SecretId.SecretId Evergreen.V375.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V375.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Result Evergreen.V375.Discord.HttpError ( Evergreen.V375.Discord.Guild, List Evergreen.V375.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V375.FileStatus.FileHash Int (Maybe (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Call.CallId
