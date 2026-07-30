module Evergreen.V340.Types exposing (..)

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
import Evergreen.V340.AiChat
import Evergreen.V340.Audio
import Evergreen.V340.Call
import Evergreen.V340.ChannelDescription
import Evergreen.V340.ChannelName
import Evergreen.V340.Cloudflare
import Evergreen.V340.Coord
import Evergreen.V340.CssPixels
import Evergreen.V340.CustomEmoji
import Evergreen.V340.Discord
import Evergreen.V340.DiscordAttachmentId
import Evergreen.V340.DiscordUserData
import Evergreen.V340.DmChannel
import Evergreen.V340.DmChannelId
import Evergreen.V340.Drawing
import Evergreen.V340.Editable
import Evergreen.V340.EmailAddress
import Evergreen.V340.Embed
import Evergreen.V340.Emoji
import Evergreen.V340.FileStatus
import Evergreen.V340.Game
import Evergreen.V340.Go
import Evergreen.V340.GuildName
import Evergreen.V340.Id
import Evergreen.V340.ImageEditor
import Evergreen.V340.ImageViewer
import Evergreen.V340.LinkedAndOtherDiscordUsers
import Evergreen.V340.Local
import Evergreen.V340.LocalState
import Evergreen.V340.Log
import Evergreen.V340.LoginForm
import Evergreen.V340.MembersAndOwner
import Evergreen.V340.Message
import Evergreen.V340.MessageInput
import Evergreen.V340.MessageView
import Evergreen.V340.MuteSettings
import Evergreen.V340.MyUi
import Evergreen.V340.NonemptyDict
import Evergreen.V340.NonemptySet
import Evergreen.V340.OneOrGreater
import Evergreen.V340.OneToOne
import Evergreen.V340.Pages.Admin
import Evergreen.V340.Pagination
import Evergreen.V340.PersonName
import Evergreen.V340.Ports
import Evergreen.V340.Postmark
import Evergreen.V340.Range
import Evergreen.V340.RecoveryLogin
import Evergreen.V340.RichText
import Evergreen.V340.Route
import Evergreen.V340.Scroll
import Evergreen.V340.SecretId
import Evergreen.V340.SessionIdHash
import Evergreen.V340.Slack
import Evergreen.V340.Sticker
import Evergreen.V340.TextEditor
import Evergreen.V340.ToBackendLog
import Evergreen.V340.Touch
import Evergreen.V340.TwoFactorAuthentication
import Evergreen.V340.Ui.Anim
import Evergreen.V340.Untrusted
import Evergreen.V340.User
import Evergreen.V340.UserAgent
import Evergreen.V340.UserSession
import Evergreen.V340.WordSpellingGame
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
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type UserOptionSection
    = UserOption_TwoFactorAuthentication
    | UserOption_Settings
    | UserOption_WhitelistedDomains
    | UserOption_Discord
    | UserOption_ConnectedDevices
    | UserOption_Debug


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V340.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V340.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V340.Pages.Admin.Msg
    | PressedLogOut Evergreen.V340.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V340.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V340.Route.Route
    | SelectedFilesToAttach ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V340.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V340.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V340.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V340.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V340.NonemptyDict.NonemptyDict Int Evergreen.V340.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V340.NonemptyDict.NonemptyDict Int Evergreen.V340.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRoute Evergreen.V340.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V340.NonemptySet.NonemptySet (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V340.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V340.AiChat.Msg
    | GameMsg Evergreen.V340.Game.Msg
    | GoSpectatorMsg Evergreen.V340.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V340.Editable.Msg Evergreen.V340.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V340.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V340.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute )
        { fileId : Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute )
        { fileId : Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V340.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage Evergreen.V340.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V340.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V340.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V340.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V340.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.User.NotificationLevel
    | GotStartupData Evergreen.V340.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V340.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V340.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId
        , otherUserId : Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRoute Evergreen.V340.MessageInput.Msg
    | MessageInputMsg Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRoute Evergreen.V340.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V340.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V340.Range.Range, Evergreen.V340.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V340.Range.Range, Evergreen.V340.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V340.Call.FromJs)
    | VoiceChatMsg Evergreen.V340.Call.Msg
    | PressedChannelHeaderTab Evergreen.V340.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V340.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V340.Audio.LoadError Evergreen.V340.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V340.Id.AnyGuildOrDmId (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | PressedMuteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.MuteSettings.IsMuted


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V340.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V340.UserSession.UserSession
    , currentlyViewing : Evergreen.V340.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) Evergreen.V340.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.LocalState.DiscordFrontendGuild
    , user : Evergreen.V340.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.User.FrontendUser
    , discordUsers : Evergreen.V340.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V340.SessionIdHash.SessionIdHash Evergreen.V340.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V340.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId) Evergreen.V340.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId) Evergreen.V340.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V340.Call.CallId (Evergreen.V340.NonemptyDict.NonemptyDict ( Evergreen.V340.Id.Id Evergreen.V340.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V340.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V340.Go.PublicGoMatchData Evergreen.V340.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V340.Route.Route
    , windowSize : Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V340.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V340.Audio.LoadError Evergreen.V340.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V340.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V340.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V340.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V340.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V340.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.ChannelName.ChannelName Evergreen.V340.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.ChannelName.ChannelName Evergreen.V340.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V340.GuildName.GuildName (Evergreen.V340.UserSession.ToBeFilledInByBackend (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V340.Id.DiscordGuildOrDmId_DmData (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V340.UserSession.SetViewing
    | Local_SetName Evergreen.V340.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V340.Id.GuildOrDmId (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V340.Id.GuildOrDmId (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V340.Id.DiscordGuildOrDmId (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V340.Id.DiscordGuildOrDmId (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V340.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V340.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V340.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V340.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V340.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V340.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V340.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V340.NonemptySet.NonemptySet (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V340.Call.LocalChange
    | Local_Game Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Game.LocalChange
    | Local_Drawing Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Drawing.AnchorType Evergreen.V340.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Effect.Time.Posix Evergreen.V340.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V340.RichText.RichText (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))) Evergreen.V340.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId) Evergreen.V340.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V340.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V340.RichText.RichText (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))) Evergreen.V340.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId) Evergreen.V340.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.ChannelName.ChannelName Evergreen.V340.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.ChannelName.ChannelName Evergreen.V340.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V340.LocalState.JoinGuildError
            { guildId : Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId
            , guild : Evergreen.V340.LocalState.FrontendGuild
            , owner : Evergreen.V340.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V340.RichText.RichText (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V340.RichText.RichText (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V340.Id.DiscordGuildOrDmId_DmData (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V340.RichText.RichText (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Maybe Evergreen.V340.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Maybe Evergreen.V340.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V340.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V340.SessionIdHash.SessionIdHash Evergreen.V340.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V340.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V340.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V340.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V340.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V340.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Evergreen.V340.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.ChannelName.ChannelName (Evergreen.V340.Discord.OptionalData (Maybe String)) (List Evergreen.V340.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
        (Evergreen.V340.NonemptyDict.NonemptyDict
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) Evergreen.V340.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Evergreen.V340.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Maybe (Evergreen.V340.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V340.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V340.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V340.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V340.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V340.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V340.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Discord.OptionalData String) (Evergreen.V340.Discord.OptionalData (Maybe String)) (List Evergreen.V340.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId) Evergreen.V340.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
        (Evergreen.V340.MembersAndOwner.MembersAndOwner
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Evergreen.V340.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId) Evergreen.V340.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId) Evergreen.V340.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V340.Call.ServerChange
    | Server_Game (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Game.LocalChange
    | Server_Drawing (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Drawing.AnchorType Evergreen.V340.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V340.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V340.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V340.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V340.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V340.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V340.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V340.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V340.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V340.Id.AnyGuildOrDmId Evergreen.V340.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V340.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels) (Maybe Evergreen.V340.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId) (Evergreen.V340.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V340.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V340.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V340.Local.Local LocalMsg Evergreen.V340.LocalState.LocalState
    , admin : Evergreen.V340.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId, Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V340.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V340.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V340.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V340.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.ThreadRoute ) (Evergreen.V340.NonemptyDict.NonemptyDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V340.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V340.Scroll.ScrollPosition
    , textEditor : Evergreen.V340.TextEditor.Model
    , profilePictureEditor : Evergreen.V340.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId, Evergreen.V340.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V340.Emoji.Model
    , voiceChat : Evergreen.V340.Call.Model
    , games : SeqDict.SeqDict Evergreen.V340.Id.GuildOrDmId Evergreen.V340.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V340.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V340.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V340.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V340.Range.Range
                , direction : Evergreen.V340.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V340.NonemptyDict.NonemptyDict Int Evergreen.V340.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V340.NonemptyDict.NonemptyDict Int Evergreen.V340.Touch.Touch
        , target : DragTarget
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
    | AdminToFrontend Evergreen.V340.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V340.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V340.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V340.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V340.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V340.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V340.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V340.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V340.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V340.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V340.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V340.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V340.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V340.Audio.LoadError Evergreen.V340.Audio.Source
    , startupData : Evergreen.V340.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V340.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V340.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V340.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V340.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V340.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId, Evergreen.V340.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V340.DmChannelId.DmChannelId, Evergreen.V340.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId, Evergreen.V340.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId, Evergreen.V340.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V340.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V340.NonemptyDict.NonemptyDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V340.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V340.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V340.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V340.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V340.DmChannelId.DmChannelId Evergreen.V340.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) Evergreen.V340.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.Slack.Id Evergreen.V340.Slack.ChannelId) Evergreen.V340.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V340.OneToOne.OneToOne String (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    , slackUsers : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.Slack.Id Evergreen.V340.Slack.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    , slackServers : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.Slack.Id Evergreen.V340.Slack.TeamId) (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    , slackToken : Maybe Evergreen.V340.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V340.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V340.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V340.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V340.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V340.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V340.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V340.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V340.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Evergreen.V340.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId, Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V340.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V340.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V340.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V340.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.LocalState.LoadingDiscordChannel (List Evergreen.V340.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V340.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId) Evergreen.V340.Sticker.StickerData
    , discordStickers : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.Discord.Id Evergreen.V340.Discord.StickerId) (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId) Evergreen.V340.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V340.OneToOne.OneToOne Evergreen.V340.RichText.DiscordCustomEmojiIdAndName (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V340.Postmark.ApiKey
    , serverSecret : Evergreen.V340.SecretId.SecretId Evergreen.V340.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V340.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.GamePublicId) ( Evergreen.V340.DmChannelId.GuildOrFullDmId, Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V340.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V340.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V340.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.Id.ThreadRoute (Maybe Evergreen.V340.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V340.DmChannelId.DmChannelId Evergreen.V340.Id.ThreadRoute (Maybe Evergreen.V340.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V340.Id.Id Evergreen.V340.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V340.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V340.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V340.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V340.Untrusted.Untrusted Evergreen.V340.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V340.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V340.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V340.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V340.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V340.PersonName.PersonName Evergreen.V340.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V340.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V340.Slack.OAuthCode Evergreen.V340.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V340.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V340.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V340.Id.Id Evergreen.V340.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V340.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V340.EmailAddress.EmailAddress (Result Evergreen.V340.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V340.EmailAddress.EmailAddress (Result Evergreen.V340.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V340.EmailAddress.EmailAddress (Result Evergreen.V340.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V340.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMaybeMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Result Evergreen.V340.Discord.HttpError Evergreen.V340.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V340.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Result Evergreen.V340.Discord.HttpError Evergreen.V340.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) (Result Evergreen.V340.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) (Result Evergreen.V340.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) (Result Evergreen.V340.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) (Result Evergreen.V340.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji (Result Evergreen.V340.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji (Result Evergreen.V340.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji (Result Evergreen.V340.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji (Result Evergreen.V340.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V340.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V340.Discord.HttpError (List ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId, Maybe Evergreen.V340.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Effect.Time.Posix Evergreen.V340.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V340.Slack.CurrentUser
            , team : Evergreen.V340.Slack.Team
            , users : List Evergreen.V340.Slack.User
            , channels : List ( Evergreen.V340.Slack.Channel, List Evergreen.V340.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Result Effect.Http.Error Evergreen.V340.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V340.Local.ChangeId Effect.Time.Posix Evergreen.V340.Call.CallId Evergreen.V340.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V340.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V340.Local.ChangeId Effect.Time.Posix Evergreen.V340.Call.CallId Evergreen.V340.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V340.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V340.Local.ChangeId Evergreen.V340.Call.ConnectionId Evergreen.V340.Cloudflare.RealtimeSessionId (List Evergreen.V340.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V340.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V340.Local.ChangeId Evergreen.V340.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Discord.UserAuth (Result Evergreen.V340.Discord.HttpError Evergreen.V340.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Result Evergreen.V340.Discord.HttpError Evergreen.V340.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
        (Result
            Evergreen.V340.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId
                , members : List (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
                }
            , List
                ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId
                , { guild : Evergreen.V340.Discord.GatewayGuild
                  , channels : List Evergreen.V340.Discord.Channel
                  , icon : Maybe Evergreen.V340.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Bool Evergreen.V340.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V340.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.AttachmentId, Evergreen.V340.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V340.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.AttachmentId, Evergreen.V340.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V340.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V340.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V340.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V340.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Result Evergreen.V340.Discord.HttpError (List Evergreen.V340.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Result Evergreen.V340.Discord.HttpError (List Evergreen.V340.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V340.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V340.DmChannelId.DmChannelId Evergreen.V340.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V340.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V340.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V340.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
        (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V340.Discord.HttpError
            { guild : Evergreen.V340.Discord.GatewayGuild
            , channels : List Evergreen.V340.Discord.Channel
            , icon : Maybe Evergreen.V340.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Result Evergreen.V340.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V340.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (List ( Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId, Result Effect.Http.Error Evergreen.V340.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId, Result Effect.Http.Error Evergreen.V340.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (List ( Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V340.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V340.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V340.Discord.HttpError (List Evergreen.V340.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V340.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V340.SecretId.SecretId Evergreen.V340.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V340.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Result Evergreen.V340.Discord.HttpError ( Evergreen.V340.Discord.Guild, List Evergreen.V340.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V340.FileStatus.FileHash Int (Maybe (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
