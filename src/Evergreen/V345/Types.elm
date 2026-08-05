module Evergreen.V345.Types exposing (..)

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
import Evergreen.V345.AiChat
import Evergreen.V345.Audio
import Evergreen.V345.Call
import Evergreen.V345.ChannelDescription
import Evergreen.V345.ChannelName
import Evergreen.V345.Cloudflare
import Evergreen.V345.Coord
import Evergreen.V345.CssPixels
import Evergreen.V345.CustomEmoji
import Evergreen.V345.Discord
import Evergreen.V345.DiscordAttachmentId
import Evergreen.V345.DiscordUserData
import Evergreen.V345.DmChannel
import Evergreen.V345.DmChannelId
import Evergreen.V345.Drawing
import Evergreen.V345.Editable
import Evergreen.V345.EmailAddress
import Evergreen.V345.Embed
import Evergreen.V345.Emoji
import Evergreen.V345.FileStatus
import Evergreen.V345.Game
import Evergreen.V345.Go
import Evergreen.V345.GuildName
import Evergreen.V345.Id
import Evergreen.V345.ImageEditor
import Evergreen.V345.ImageViewer
import Evergreen.V345.LinkedAndOtherDiscordUsers
import Evergreen.V345.Local
import Evergreen.V345.LocalState
import Evergreen.V345.Log
import Evergreen.V345.LoginForm
import Evergreen.V345.MembersAndOwner
import Evergreen.V345.Message
import Evergreen.V345.MessageInput
import Evergreen.V345.MessageView
import Evergreen.V345.MuteSettings
import Evergreen.V345.MyUi
import Evergreen.V345.NonemptyDict
import Evergreen.V345.NonemptySet
import Evergreen.V345.OneOrGreater
import Evergreen.V345.OneToOne
import Evergreen.V345.Pages.Admin
import Evergreen.V345.Pagination
import Evergreen.V345.PersonName
import Evergreen.V345.Ports
import Evergreen.V345.Postmark
import Evergreen.V345.Range
import Evergreen.V345.RecoveryLogin
import Evergreen.V345.RichText
import Evergreen.V345.Route
import Evergreen.V345.Scroll
import Evergreen.V345.SecretId
import Evergreen.V345.SessionIdHash
import Evergreen.V345.Slack
import Evergreen.V345.Sticker
import Evergreen.V345.TextEditor
import Evergreen.V345.ToBackendLog
import Evergreen.V345.Touch
import Evergreen.V345.TwoFactorAuthentication
import Evergreen.V345.Ui.Anim
import Evergreen.V345.Untrusted
import Evergreen.V345.User
import Evergreen.V345.UserAgent
import Evergreen.V345.UserSession
import Evergreen.V345.WordSpellingGame
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
    | LoginFormMsg Evergreen.V345.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V345.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V345.Pages.Admin.Msg
    | PressedLogOut Evergreen.V345.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V345.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V345.Route.Route
    | SelectedFilesToAttach ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V345.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V345.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V345.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V345.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V345.NonemptyDict.NonemptyDict Int Evergreen.V345.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V345.NonemptyDict.NonemptyDict Int Evergreen.V345.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRoute Evergreen.V345.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V345.NonemptySet.NonemptySet (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V345.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V345.AiChat.Msg
    | GameMsg Evergreen.V345.Game.Msg
    | GoSpectatorMsg Evergreen.V345.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V345.Editable.Msg Evergreen.V345.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V345.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V345.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute )
        { fileId : Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute )
        { fileId : Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V345.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage Evergreen.V345.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V345.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V345.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V345.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V345.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.User.NotificationLevel
    | GotStartupData Evergreen.V345.Ports.StartupData
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V345.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V345.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId
        , otherUserId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRoute Evergreen.V345.MessageInput.Msg
    | MessageInputMsg Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRoute Evergreen.V345.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V345.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V345.Range.Range, Evergreen.V345.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V345.Range.Range, Evergreen.V345.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V345.Call.FromJs)
    | VoiceChatMsg Evergreen.V345.Call.Msg
    | PressedChannelHeaderTab Evergreen.V345.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V345.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V345.Audio.LoadError Evergreen.V345.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V345.Id.AnyGuildOrDmId (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V345.Id.AnyGuildOrDmId (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) Evergreen.V345.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V345.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V345.UserSession.UserSession
    , currentlyViewing : Evergreen.V345.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) Evergreen.V345.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.LocalState.DiscordFrontendGuild
    , user : Evergreen.V345.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.User.FrontendUser
    , discordUsers : Evergreen.V345.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V345.SessionIdHash.SessionIdHash Evergreen.V345.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V345.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId) Evergreen.V345.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId) Evergreen.V345.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V345.Call.CallId (Evergreen.V345.NonemptyDict.NonemptyDict ( Evergreen.V345.Id.Id Evergreen.V345.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V345.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V345.Go.PublicGoMatchData Evergreen.V345.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V345.Route.Route
    , windowSize : Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V345.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V345.Audio.LoadError Evergreen.V345.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V345.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V345.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V345.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileData) (List Evergreen.V345.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V345.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V345.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.ChannelName.ChannelName Evergreen.V345.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.ChannelName.ChannelName Evergreen.V345.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.UserSession.ToBeFilledInByBackend (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V345.GuildName.GuildName (Evergreen.V345.UserSession.ToBeFilledInByBackend (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V345.Id.DiscordGuildOrDmId_DmData (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V345.UserSession.SetViewing
    | Local_SetName Evergreen.V345.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V345.Id.GuildOrDmId (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V345.Id.GuildOrDmId (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V345.Id.DiscordGuildOrDmId (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V345.Id.DiscordGuildOrDmId (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V345.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V345.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V345.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V345.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V345.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V345.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V345.NonemptySet.NonemptySet (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V345.Call.LocalChange
    | Local_Game Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Game.LocalChange
    | Local_Drawing Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Drawing.AnchorType Evergreen.V345.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.User.FrontendUser Effect.Time.Posix Evergreen.V345.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V345.RichText.RichText (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))) Evergreen.V345.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId) Evergreen.V345.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V345.Id.DiscordGuildOrDmId Evergreen.V345.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V345.RichText.RichText (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))) Evergreen.V345.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId) Evergreen.V345.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.ChannelName.ChannelName Evergreen.V345.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.ChannelName.ChannelName Evergreen.V345.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V345.LocalState.JoinGuildError
            { guildId : Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId
            , guild : Evergreen.V345.LocalState.FrontendGuild
            , owner : Evergreen.V345.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V345.RichText.RichText (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V345.RichText.RichText (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V345.Id.DiscordGuildOrDmId_DmData (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V345.RichText.RichText (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Maybe Evergreen.V345.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Maybe Evergreen.V345.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V345.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V345.SessionIdHash.SessionIdHash Evergreen.V345.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V345.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V345.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V345.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V345.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V345.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Evergreen.V345.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.ChannelName.ChannelName (Evergreen.V345.Discord.OptionalData (Maybe String)) (List Evergreen.V345.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)
        (Evergreen.V345.NonemptyDict.NonemptyDict
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) Evergreen.V345.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Evergreen.V345.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Maybe (Evergreen.V345.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V345.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V345.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V345.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V345.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V345.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V345.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Discord.OptionalData String) (Evergreen.V345.Discord.OptionalData (Maybe String)) (List Evergreen.V345.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId) Evergreen.V345.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId)
        (Evergreen.V345.MembersAndOwner.MembersAndOwner
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Evergreen.V345.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId) Evergreen.V345.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId) Evergreen.V345.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V345.Call.ServerChange
    | Server_Game (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Game.LocalChange
    | Server_Drawing (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Drawing.AnchorType Evergreen.V345.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V345.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V345.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V345.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V345.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V345.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V345.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V345.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V345.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V345.Id.AnyGuildOrDmId Evergreen.V345.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V345.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels) (Maybe Evergreen.V345.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V345.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V345.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V345.Local.Local LocalMsg Evergreen.V345.LocalState.LocalState
    , admin : Evergreen.V345.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V345.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V345.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V345.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V345.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V345.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.ThreadRoute ) (Evergreen.V345.NonemptyDict.NonemptyDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V345.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V345.Scroll.ScrollPosition
    , textEditor : Evergreen.V345.TextEditor.Model
    , profilePictureEditor : Evergreen.V345.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId, Evergreen.V345.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V345.Emoji.Model
    , voiceChat : Evergreen.V345.Call.Model
    , games : SeqDict.SeqDict Evergreen.V345.Id.GuildOrDmId Evergreen.V345.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V345.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V345.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V345.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V345.Range.Range
                , direction : Evergreen.V345.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V345.NonemptyDict.NonemptyDict Int Evergreen.V345.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V345.NonemptyDict.NonemptyDict Int Evergreen.V345.Touch.Touch
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
    | AdminToFrontend Evergreen.V345.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V345.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V345.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V345.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V345.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V345.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V345.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V345.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V345.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V345.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V345.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V345.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V345.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V345.Audio.LoadError Evergreen.V345.Audio.Source
    , startupData : Evergreen.V345.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V345.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V345.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V345.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V345.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V345.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId, Evergreen.V345.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V345.DmChannelId.DmChannelId, Evergreen.V345.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId, Evergreen.V345.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId, Evergreen.V345.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V345.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V345.NonemptyDict.NonemptyDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V345.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V345.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V345.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V345.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) Evergreen.V345.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V345.DmChannelId.DmChannelId Evergreen.V345.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) Evergreen.V345.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.Slack.Id Evergreen.V345.Slack.ChannelId) Evergreen.V345.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V345.OneToOne.OneToOne String (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    , slackUsers : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.Slack.Id Evergreen.V345.Slack.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
    , slackServers : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.Slack.Id Evergreen.V345.Slack.TeamId) (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    , slackToken : Maybe Evergreen.V345.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V345.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V345.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V345.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V345.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V345.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V345.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V345.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V345.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Evergreen.V345.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId, Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V345.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V345.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V345.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V345.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.LocalState.LoadingDiscordChannel Evergreen.V345.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V345.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId) Evergreen.V345.Sticker.StickerData
    , discordStickers : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.Discord.Id Evergreen.V345.Discord.StickerId) (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId) Evergreen.V345.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V345.OneToOne.OneToOne Evergreen.V345.RichText.DiscordCustomEmojiIdAndName (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V345.Postmark.ApiKey
    , serverSecret : Evergreen.V345.SecretId.SecretId Evergreen.V345.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V345.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.GamePublicId) ( Evergreen.V345.DmChannelId.GuildOrFullDmId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V345.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V345.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V345.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.Id.ThreadRoute (Maybe Evergreen.V345.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V345.DmChannelId.DmChannelId Evergreen.V345.Id.ThreadRoute (Maybe Evergreen.V345.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V345.Id.Id Evergreen.V345.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V345.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V345.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V345.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V345.Untrusted.Untrusted Evergreen.V345.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V345.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V345.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V345.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V345.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V345.PersonName.PersonName Evergreen.V345.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V345.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V345.Slack.OAuthCode Evergreen.V345.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V345.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V345.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V345.Id.Id Evergreen.V345.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V345.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V345.EmailAddress.EmailAddress (Result Evergreen.V345.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V345.EmailAddress.EmailAddress (Result Evergreen.V345.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V345.EmailAddress.EmailAddress (Result Evergreen.V345.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V345.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMaybeMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Result Evergreen.V345.Discord.HttpError Evergreen.V345.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V345.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Result Evergreen.V345.Discord.HttpError Evergreen.V345.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) (Result Evergreen.V345.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) (Result Evergreen.V345.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) (Result Evergreen.V345.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) (Result Evergreen.V345.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji (Result Evergreen.V345.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji (Result Evergreen.V345.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji (Result Evergreen.V345.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji (Result Evergreen.V345.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V345.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V345.Discord.HttpError (List ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId, Maybe Evergreen.V345.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Effect.Time.Posix Evergreen.V345.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V345.Slack.CurrentUser
            , team : Evergreen.V345.Slack.Team
            , users : List Evergreen.V345.Slack.User
            , channels : List ( Evergreen.V345.Slack.Channel, List Evergreen.V345.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Result Effect.Http.Error Evergreen.V345.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V345.Local.ChangeId Effect.Time.Posix Evergreen.V345.Call.CallId Evergreen.V345.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V345.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V345.Local.ChangeId Effect.Time.Posix Evergreen.V345.Call.CallId Evergreen.V345.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V345.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V345.Local.ChangeId Evergreen.V345.Call.ConnectionId Evergreen.V345.Cloudflare.RealtimeSessionId (List Evergreen.V345.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V345.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V345.Local.ChangeId Evergreen.V345.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Discord.UserAuth (Result Evergreen.V345.Discord.HttpError Evergreen.V345.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Result Evergreen.V345.Discord.HttpError Evergreen.V345.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
        (Result
            Evergreen.V345.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId
                , members : List (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
                }
            , List
                ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId
                , { guild : Evergreen.V345.Discord.GatewayGuild
                  , channels : List Evergreen.V345.Discord.Channel
                  , icon : Maybe Evergreen.V345.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Bool Evergreen.V345.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V345.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.AttachmentId, Evergreen.V345.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V345.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.AttachmentId, Evergreen.V345.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V345.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V345.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V345.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V345.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Result Evergreen.V345.Discord.HttpError Evergreen.V345.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Result Evergreen.V345.Discord.HttpError (List Evergreen.V345.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V345.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V345.DmChannelId.DmChannelId Evergreen.V345.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V345.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V345.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V345.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
        (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V345.Discord.HttpError
            { guild : Evergreen.V345.Discord.GatewayGuild
            , channels : List Evergreen.V345.Discord.Channel
            , icon : Maybe Evergreen.V345.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Result Evergreen.V345.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V345.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (List ( Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId, Result Effect.Http.Error Evergreen.V345.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId, Result Effect.Http.Error Evergreen.V345.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (List ( Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V345.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V345.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V345.Discord.HttpError (List Evergreen.V345.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V345.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V345.SecretId.SecretId Evergreen.V345.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V345.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Result Evergreen.V345.Discord.HttpError ( Evergreen.V345.Discord.Guild, List Evergreen.V345.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V345.FileStatus.FileHash Int (Maybe (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
