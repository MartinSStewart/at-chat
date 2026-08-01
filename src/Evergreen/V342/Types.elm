module Evergreen.V342.Types exposing (..)

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
import Evergreen.V342.AiChat
import Evergreen.V342.Audio
import Evergreen.V342.Call
import Evergreen.V342.ChannelDescription
import Evergreen.V342.ChannelName
import Evergreen.V342.Cloudflare
import Evergreen.V342.Coord
import Evergreen.V342.CssPixels
import Evergreen.V342.CustomEmoji
import Evergreen.V342.Discord
import Evergreen.V342.DiscordAttachmentId
import Evergreen.V342.DiscordUserData
import Evergreen.V342.DmChannel
import Evergreen.V342.DmChannelId
import Evergreen.V342.Drawing
import Evergreen.V342.Editable
import Evergreen.V342.EmailAddress
import Evergreen.V342.Embed
import Evergreen.V342.Emoji
import Evergreen.V342.FileStatus
import Evergreen.V342.Game
import Evergreen.V342.Go
import Evergreen.V342.GuildName
import Evergreen.V342.Id
import Evergreen.V342.ImageEditor
import Evergreen.V342.ImageViewer
import Evergreen.V342.LinkedAndOtherDiscordUsers
import Evergreen.V342.Local
import Evergreen.V342.LocalState
import Evergreen.V342.Log
import Evergreen.V342.LoginForm
import Evergreen.V342.MembersAndOwner
import Evergreen.V342.Message
import Evergreen.V342.MessageInput
import Evergreen.V342.MessageView
import Evergreen.V342.MuteSettings
import Evergreen.V342.MyUi
import Evergreen.V342.NonemptyDict
import Evergreen.V342.NonemptySet
import Evergreen.V342.OneOrGreater
import Evergreen.V342.OneToOne
import Evergreen.V342.Pages.Admin
import Evergreen.V342.Pagination
import Evergreen.V342.PersonName
import Evergreen.V342.Ports
import Evergreen.V342.Postmark
import Evergreen.V342.Range
import Evergreen.V342.RecoveryLogin
import Evergreen.V342.RichText
import Evergreen.V342.Route
import Evergreen.V342.Scroll
import Evergreen.V342.SecretId
import Evergreen.V342.SessionIdHash
import Evergreen.V342.Slack
import Evergreen.V342.Sticker
import Evergreen.V342.TextEditor
import Evergreen.V342.ToBackendLog
import Evergreen.V342.Touch
import Evergreen.V342.TwoFactorAuthentication
import Evergreen.V342.Ui.Anim
import Evergreen.V342.Untrusted
import Evergreen.V342.User
import Evergreen.V342.UserAgent
import Evergreen.V342.UserSession
import Evergreen.V342.WordSpellingGame
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
    | LoginFormMsg Evergreen.V342.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V342.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V342.Pages.Admin.Msg
    | PressedLogOut Evergreen.V342.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V342.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V342.Route.Route
    | SelectedFilesToAttach ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V342.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V342.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V342.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V342.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V342.NonemptyDict.NonemptyDict Int Evergreen.V342.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V342.NonemptyDict.NonemptyDict Int Evergreen.V342.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRoute Evergreen.V342.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V342.NonemptySet.NonemptySet (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V342.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V342.AiChat.Msg
    | GameMsg Evergreen.V342.Game.Msg
    | GoSpectatorMsg Evergreen.V342.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V342.Editable.Msg Evergreen.V342.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V342.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V342.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute )
        { fileId : Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute )
        { fileId : Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V342.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage Evergreen.V342.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V342.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V342.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V342.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V342.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.User.NotificationLevel
    | GotStartupData Evergreen.V342.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V342.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V342.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId
        , otherUserId : Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRoute Evergreen.V342.MessageInput.Msg
    | MessageInputMsg Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRoute Evergreen.V342.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V342.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V342.Range.Range, Evergreen.V342.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V342.Range.Range, Evergreen.V342.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V342.Call.FromJs)
    | VoiceChatMsg Evergreen.V342.Call.Msg
    | PressedChannelHeaderTab Evergreen.V342.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V342.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V342.Audio.LoadError Evergreen.V342.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.MuteSettings.IsMuted


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V342.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V342.UserSession.UserSession
    , currentlyViewing : Evergreen.V342.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) Evergreen.V342.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.LocalState.DiscordFrontendGuild
    , user : Evergreen.V342.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.User.FrontendUser
    , discordUsers : Evergreen.V342.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V342.SessionIdHash.SessionIdHash Evergreen.V342.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V342.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId) Evergreen.V342.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId) Evergreen.V342.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V342.Call.CallId (Evergreen.V342.NonemptyDict.NonemptyDict ( Evergreen.V342.Id.Id Evergreen.V342.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V342.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V342.Go.PublicGoMatchData Evergreen.V342.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V342.Route.Route
    , windowSize : Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V342.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V342.Audio.LoadError Evergreen.V342.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V342.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V342.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V342.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V342.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V342.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.ChannelName.ChannelName Evergreen.V342.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.ChannelName.ChannelName Evergreen.V342.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.UserSession.ToBeFilledInByBackend (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V342.GuildName.GuildName (Evergreen.V342.UserSession.ToBeFilledInByBackend (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V342.Id.DiscordGuildOrDmId_DmData (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V342.UserSession.SetViewing
    | Local_SetName Evergreen.V342.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V342.Id.GuildOrDmId (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V342.Id.GuildOrDmId (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V342.Id.DiscordGuildOrDmId (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V342.Id.DiscordGuildOrDmId (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V342.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V342.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V342.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V342.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V342.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V342.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V342.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V342.NonemptySet.NonemptySet (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V342.Call.LocalChange
    | Local_Game Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Game.LocalChange
    | Local_Drawing Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Drawing.AnchorType Evergreen.V342.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.User.FrontendUser Effect.Time.Posix Evergreen.V342.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V342.RichText.RichText (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))) Evergreen.V342.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId) Evergreen.V342.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V342.Id.DiscordGuildOrDmId Evergreen.V342.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V342.RichText.RichText (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))) Evergreen.V342.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId) Evergreen.V342.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.ChannelName.ChannelName Evergreen.V342.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.ChannelName.ChannelName Evergreen.V342.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V342.LocalState.JoinGuildError
            { guildId : Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId
            , guild : Evergreen.V342.LocalState.FrontendGuild
            , owner : Evergreen.V342.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V342.RichText.RichText (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V342.RichText.RichText (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V342.Id.DiscordGuildOrDmId_DmData (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V342.RichText.RichText (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Maybe Evergreen.V342.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Maybe Evergreen.V342.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V342.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V342.SessionIdHash.SessionIdHash Evergreen.V342.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V342.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V342.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V342.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V342.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V342.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Evergreen.V342.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.ChannelName.ChannelName (Evergreen.V342.Discord.OptionalData (Maybe String)) (List Evergreen.V342.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)
        (Evergreen.V342.NonemptyDict.NonemptyDict
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) Evergreen.V342.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Evergreen.V342.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Maybe (Evergreen.V342.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V342.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V342.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V342.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V342.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V342.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V342.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Discord.OptionalData String) (Evergreen.V342.Discord.OptionalData (Maybe String)) (List Evergreen.V342.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId) Evergreen.V342.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId)
        (Evergreen.V342.MembersAndOwner.MembersAndOwner
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Evergreen.V342.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId) Evergreen.V342.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId) Evergreen.V342.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V342.Call.ServerChange
    | Server_Game (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Game.LocalChange
    | Server_Drawing (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Drawing.AnchorType Evergreen.V342.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V342.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V342.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V342.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V342.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V342.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V342.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V342.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V342.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V342.Id.AnyGuildOrDmId Evergreen.V342.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V342.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels) (Maybe Evergreen.V342.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V342.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V342.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V342.Local.Local LocalMsg Evergreen.V342.LocalState.LocalState
    , admin : Evergreen.V342.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V342.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V342.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V342.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V342.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.ThreadRoute ) (Evergreen.V342.NonemptyDict.NonemptyDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V342.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V342.Scroll.ScrollPosition
    , textEditor : Evergreen.V342.TextEditor.Model
    , profilePictureEditor : Evergreen.V342.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId, Evergreen.V342.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V342.Emoji.Model
    , voiceChat : Evergreen.V342.Call.Model
    , games : SeqDict.SeqDict Evergreen.V342.Id.GuildOrDmId Evergreen.V342.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V342.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V342.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V342.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V342.Range.Range
                , direction : Evergreen.V342.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V342.NonemptyDict.NonemptyDict Int Evergreen.V342.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V342.NonemptyDict.NonemptyDict Int Evergreen.V342.Touch.Touch
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
    | AdminToFrontend Evergreen.V342.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V342.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V342.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V342.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V342.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V342.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V342.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V342.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V342.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V342.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V342.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V342.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V342.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V342.Audio.LoadError Evergreen.V342.Audio.Source
    , startupData : Evergreen.V342.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V342.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V342.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V342.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V342.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V342.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId, Evergreen.V342.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V342.DmChannelId.DmChannelId, Evergreen.V342.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId, Evergreen.V342.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId, Evergreen.V342.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V342.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V342.NonemptyDict.NonemptyDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V342.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V342.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V342.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V342.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) Evergreen.V342.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V342.DmChannelId.DmChannelId Evergreen.V342.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) Evergreen.V342.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.Slack.Id Evergreen.V342.Slack.ChannelId) Evergreen.V342.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V342.OneToOne.OneToOne String (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    , slackUsers : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.Slack.Id Evergreen.V342.Slack.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
    , slackServers : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.Slack.Id Evergreen.V342.Slack.TeamId) (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    , slackToken : Maybe Evergreen.V342.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V342.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V342.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V342.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V342.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V342.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V342.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V342.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V342.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Evergreen.V342.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId, Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V342.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V342.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V342.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V342.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.LocalState.LoadingDiscordChannel (List Evergreen.V342.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V342.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId) Evergreen.V342.Sticker.StickerData
    , discordStickers : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.Discord.Id Evergreen.V342.Discord.StickerId) (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId) Evergreen.V342.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V342.OneToOne.OneToOne Evergreen.V342.RichText.DiscordCustomEmojiIdAndName (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V342.Postmark.ApiKey
    , serverSecret : Evergreen.V342.SecretId.SecretId Evergreen.V342.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V342.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.GamePublicId) ( Evergreen.V342.DmChannelId.GuildOrFullDmId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V342.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V342.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V342.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.Id.ThreadRoute (Maybe Evergreen.V342.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V342.DmChannelId.DmChannelId Evergreen.V342.Id.ThreadRoute (Maybe Evergreen.V342.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V342.Id.Id Evergreen.V342.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V342.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V342.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V342.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V342.Untrusted.Untrusted Evergreen.V342.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V342.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V342.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V342.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V342.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V342.PersonName.PersonName Evergreen.V342.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V342.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V342.Slack.OAuthCode Evergreen.V342.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V342.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V342.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V342.Id.Id Evergreen.V342.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V342.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V342.EmailAddress.EmailAddress (Result Evergreen.V342.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V342.EmailAddress.EmailAddress (Result Evergreen.V342.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V342.EmailAddress.EmailAddress (Result Evergreen.V342.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V342.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMaybeMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Result Evergreen.V342.Discord.HttpError Evergreen.V342.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V342.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Result Evergreen.V342.Discord.HttpError Evergreen.V342.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) (Result Evergreen.V342.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) (Result Evergreen.V342.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) (Result Evergreen.V342.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) (Result Evergreen.V342.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji (Result Evergreen.V342.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji (Result Evergreen.V342.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji (Result Evergreen.V342.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji (Result Evergreen.V342.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V342.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V342.Discord.HttpError (List ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId, Maybe Evergreen.V342.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Effect.Time.Posix Evergreen.V342.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V342.Slack.CurrentUser
            , team : Evergreen.V342.Slack.Team
            , users : List Evergreen.V342.Slack.User
            , channels : List ( Evergreen.V342.Slack.Channel, List Evergreen.V342.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Result Effect.Http.Error Evergreen.V342.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V342.Local.ChangeId Effect.Time.Posix Evergreen.V342.Call.CallId Evergreen.V342.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V342.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V342.Local.ChangeId Effect.Time.Posix Evergreen.V342.Call.CallId Evergreen.V342.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V342.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V342.Local.ChangeId Evergreen.V342.Call.ConnectionId Evergreen.V342.Cloudflare.RealtimeSessionId (List Evergreen.V342.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V342.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V342.Local.ChangeId Evergreen.V342.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Discord.UserAuth (Result Evergreen.V342.Discord.HttpError Evergreen.V342.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Result Evergreen.V342.Discord.HttpError Evergreen.V342.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
        (Result
            Evergreen.V342.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId
                , members : List (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
                }
            , List
                ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId
                , { guild : Evergreen.V342.Discord.GatewayGuild
                  , channels : List Evergreen.V342.Discord.Channel
                  , icon : Maybe Evergreen.V342.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Bool Evergreen.V342.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V342.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.AttachmentId, Evergreen.V342.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V342.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.AttachmentId, Evergreen.V342.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V342.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V342.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V342.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V342.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Result Evergreen.V342.Discord.HttpError (List Evergreen.V342.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Result Evergreen.V342.Discord.HttpError (List Evergreen.V342.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V342.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V342.DmChannelId.DmChannelId Evergreen.V342.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V342.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V342.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V342.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
        (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V342.Discord.HttpError
            { guild : Evergreen.V342.Discord.GatewayGuild
            , channels : List Evergreen.V342.Discord.Channel
            , icon : Maybe Evergreen.V342.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Result Evergreen.V342.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V342.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (List ( Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId, Result Effect.Http.Error Evergreen.V342.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId, Result Effect.Http.Error Evergreen.V342.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (List ( Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V342.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V342.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V342.Discord.HttpError (List Evergreen.V342.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V342.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V342.SecretId.SecretId Evergreen.V342.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V342.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Result Evergreen.V342.Discord.HttpError ( Evergreen.V342.Discord.Guild, List Evergreen.V342.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V342.FileStatus.FileHash Int (Maybe (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
