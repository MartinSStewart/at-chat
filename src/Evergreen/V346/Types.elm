module Evergreen.V346.Types exposing (..)

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
import Evergreen.V346.AiChat
import Evergreen.V346.Audio
import Evergreen.V346.Call
import Evergreen.V346.ChannelDescription
import Evergreen.V346.ChannelName
import Evergreen.V346.Cloudflare
import Evergreen.V346.Coord
import Evergreen.V346.CssPixels
import Evergreen.V346.CustomEmoji
import Evergreen.V346.Discord
import Evergreen.V346.DiscordAttachmentId
import Evergreen.V346.DiscordUserData
import Evergreen.V346.DmChannel
import Evergreen.V346.DmChannelId
import Evergreen.V346.Drawing
import Evergreen.V346.Editable
import Evergreen.V346.EmailAddress
import Evergreen.V346.Embed
import Evergreen.V346.Emoji
import Evergreen.V346.FileStatus
import Evergreen.V346.Game
import Evergreen.V346.Go
import Evergreen.V346.GuildName
import Evergreen.V346.Id
import Evergreen.V346.ImageEditor
import Evergreen.V346.ImageViewer
import Evergreen.V346.LinkedAndOtherDiscordUsers
import Evergreen.V346.Local
import Evergreen.V346.LocalState
import Evergreen.V346.Log
import Evergreen.V346.LoginForm
import Evergreen.V346.MembersAndOwner
import Evergreen.V346.Message
import Evergreen.V346.MessageInput
import Evergreen.V346.MessageView
import Evergreen.V346.MuteSettings
import Evergreen.V346.MyUi
import Evergreen.V346.NonemptyDict
import Evergreen.V346.NonemptySet
import Evergreen.V346.OneOrGreater
import Evergreen.V346.OneToOne
import Evergreen.V346.Pages.Admin
import Evergreen.V346.Pagination
import Evergreen.V346.PersonName
import Evergreen.V346.Ports
import Evergreen.V346.Postmark
import Evergreen.V346.Range
import Evergreen.V346.RecoveryLogin
import Evergreen.V346.RichText
import Evergreen.V346.Route
import Evergreen.V346.Scroll
import Evergreen.V346.SecretId
import Evergreen.V346.SessionIdHash
import Evergreen.V346.Slack
import Evergreen.V346.Sticker
import Evergreen.V346.TextEditor
import Evergreen.V346.ToBackendLog
import Evergreen.V346.Touch
import Evergreen.V346.TwoFactorAuthentication
import Evergreen.V346.Ui.Anim
import Evergreen.V346.Untrusted
import Evergreen.V346.User
import Evergreen.V346.UserAgent
import Evergreen.V346.UserSession
import Evergreen.V346.WordSpellingGame
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
    | LoginFormMsg Evergreen.V346.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V346.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V346.Pages.Admin.Msg
    | PressedLogOut Evergreen.V346.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V346.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V346.Route.Route
    | SelectedFilesToAttach ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V346.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V346.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V346.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V346.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V346.NonemptyDict.NonemptyDict Int Evergreen.V346.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V346.NonemptyDict.NonemptyDict Int Evergreen.V346.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRoute Evergreen.V346.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V346.NonemptySet.NonemptySet (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V346.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V346.AiChat.Msg
    | GameMsg Evergreen.V346.Game.Msg
    | GoSpectatorMsg Evergreen.V346.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V346.Editable.Msg Evergreen.V346.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V346.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V346.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute )
        { fileId : Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute )
        { fileId : Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V346.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage Evergreen.V346.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V346.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V346.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V346.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V346.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.User.NotificationLevel
    | GotStartupData Evergreen.V346.Ports.StartupData
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V346.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V346.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId
        , otherUserId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRoute Evergreen.V346.MessageInput.Msg
    | MessageInputMsg Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRoute Evergreen.V346.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V346.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V346.Range.Range, Evergreen.V346.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V346.Range.Range, Evergreen.V346.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V346.Call.FromJs)
    | VoiceChatMsg Evergreen.V346.Call.Msg
    | PressedChannelHeaderTab Evergreen.V346.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V346.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V346.Audio.LoadError Evergreen.V346.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V346.Id.AnyGuildOrDmId (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V346.Id.AnyGuildOrDmId (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) Evergreen.V346.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V346.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V346.UserSession.UserSession
    , currentlyViewing : Evergreen.V346.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) Evergreen.V346.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.LocalState.DiscordFrontendGuild
    , user : Evergreen.V346.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.User.FrontendUser
    , discordUsers : Evergreen.V346.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V346.SessionIdHash.SessionIdHash Evergreen.V346.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V346.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId) Evergreen.V346.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId) Evergreen.V346.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V346.Call.CallId (Evergreen.V346.NonemptyDict.NonemptyDict ( Evergreen.V346.Id.Id Evergreen.V346.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V346.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V346.Go.PublicGoMatchData Evergreen.V346.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V346.Route.Route
    , windowSize : Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V346.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V346.Audio.LoadError Evergreen.V346.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V346.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V346.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V346.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileData) (List Evergreen.V346.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V346.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V346.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.ChannelName.ChannelName Evergreen.V346.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.ChannelName.ChannelName Evergreen.V346.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V346.GuildName.GuildName (Evergreen.V346.UserSession.ToBeFilledInByBackend (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V346.Id.DiscordGuildOrDmId_DmData (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V346.UserSession.SetViewing
    | Local_SetName Evergreen.V346.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V346.Id.GuildOrDmId (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V346.Id.GuildOrDmId (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V346.Id.DiscordGuildOrDmId (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V346.Id.DiscordGuildOrDmId (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V346.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V346.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V346.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V346.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V346.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V346.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V346.NonemptySet.NonemptySet (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V346.Call.LocalChange
    | Local_Game Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Game.LocalChange
    | Local_Drawing Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Drawing.AnchorType Evergreen.V346.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.User.FrontendUser Effect.Time.Posix Evergreen.V346.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V346.RichText.RichText (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))) Evergreen.V346.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId) Evergreen.V346.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V346.Id.DiscordGuildOrDmId Evergreen.V346.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V346.RichText.RichText (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))) Evergreen.V346.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId) Evergreen.V346.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.ChannelName.ChannelName Evergreen.V346.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.ChannelName.ChannelName Evergreen.V346.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V346.LocalState.JoinGuildError
            { guildId : Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId
            , guild : Evergreen.V346.LocalState.FrontendGuild
            , owner : Evergreen.V346.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V346.RichText.RichText (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V346.RichText.RichText (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V346.Id.DiscordGuildOrDmId_DmData (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V346.RichText.RichText (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Maybe Evergreen.V346.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Maybe Evergreen.V346.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V346.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V346.SessionIdHash.SessionIdHash Evergreen.V346.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V346.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V346.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V346.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V346.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V346.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Evergreen.V346.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.ChannelName.ChannelName (Evergreen.V346.Discord.OptionalData (Maybe String)) (List Evergreen.V346.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
        (Evergreen.V346.NonemptyDict.NonemptyDict
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) Evergreen.V346.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Evergreen.V346.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Maybe (Evergreen.V346.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V346.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V346.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V346.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V346.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V346.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V346.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Discord.OptionalData String) (Evergreen.V346.Discord.OptionalData (Maybe String)) (List Evergreen.V346.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId) Evergreen.V346.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
        (Evergreen.V346.MembersAndOwner.MembersAndOwner
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Evergreen.V346.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId) Evergreen.V346.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId) Evergreen.V346.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V346.Call.ServerChange
    | Server_Game (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Game.LocalChange
    | Server_Drawing (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Drawing.AnchorType Evergreen.V346.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V346.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V346.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V346.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V346.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V346.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V346.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V346.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V346.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V346.Id.AnyGuildOrDmId Evergreen.V346.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V346.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels) (Maybe Evergreen.V346.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V346.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V346.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V346.Local.Local LocalMsg Evergreen.V346.LocalState.LocalState
    , admin : Evergreen.V346.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V346.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V346.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V346.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V346.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V346.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.ThreadRoute ) (Evergreen.V346.NonemptyDict.NonemptyDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V346.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V346.Scroll.ScrollPosition
    , textEditor : Evergreen.V346.TextEditor.Model
    , profilePictureEditor : Evergreen.V346.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId, Evergreen.V346.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V346.Emoji.Model
    , voiceChat : Evergreen.V346.Call.Model
    , games : SeqDict.SeqDict Evergreen.V346.Id.GuildOrDmId Evergreen.V346.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V346.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V346.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V346.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V346.Range.Range
                , direction : Evergreen.V346.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V346.NonemptyDict.NonemptyDict Int Evergreen.V346.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V346.NonemptyDict.NonemptyDict Int Evergreen.V346.Touch.Touch
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
    | AdminToFrontend Evergreen.V346.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V346.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V346.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V346.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V346.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V346.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V346.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V346.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V346.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V346.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V346.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V346.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V346.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V346.Audio.LoadError Evergreen.V346.Audio.Source
    , startupData : Evergreen.V346.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V346.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V346.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V346.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V346.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V346.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId, Evergreen.V346.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V346.DmChannelId.DmChannelId, Evergreen.V346.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId, Evergreen.V346.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId, Evergreen.V346.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V346.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V346.NonemptyDict.NonemptyDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V346.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V346.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V346.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V346.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V346.DmChannelId.DmChannelId Evergreen.V346.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) Evergreen.V346.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.Slack.Id Evergreen.V346.Slack.ChannelId) Evergreen.V346.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V346.OneToOne.OneToOne String (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    , slackUsers : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.Slack.Id Evergreen.V346.Slack.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    , slackServers : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.Slack.Id Evergreen.V346.Slack.TeamId) (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    , slackToken : Maybe Evergreen.V346.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V346.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V346.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V346.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V346.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V346.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V346.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V346.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V346.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Evergreen.V346.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId, Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V346.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V346.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V346.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V346.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.LocalState.LoadingDiscordChannel Evergreen.V346.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V346.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId) Evergreen.V346.Sticker.StickerData
    , discordStickers : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.Discord.Id Evergreen.V346.Discord.StickerId) (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId) Evergreen.V346.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V346.OneToOne.OneToOne Evergreen.V346.RichText.DiscordCustomEmojiIdAndName (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V346.Postmark.ApiKey
    , serverSecret : Evergreen.V346.SecretId.SecretId Evergreen.V346.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V346.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.GamePublicId) ( Evergreen.V346.DmChannelId.GuildOrFullDmId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V346.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V346.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V346.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.Id.ThreadRoute (Maybe Evergreen.V346.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V346.DmChannelId.DmChannelId Evergreen.V346.Id.ThreadRoute (Maybe Evergreen.V346.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V346.Id.Id Evergreen.V346.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V346.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V346.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V346.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V346.Untrusted.Untrusted Evergreen.V346.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V346.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V346.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V346.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V346.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V346.PersonName.PersonName Evergreen.V346.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V346.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V346.Slack.OAuthCode Evergreen.V346.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V346.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V346.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V346.Id.Id Evergreen.V346.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V346.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V346.EmailAddress.EmailAddress (Result Evergreen.V346.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V346.EmailAddress.EmailAddress (Result Evergreen.V346.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V346.EmailAddress.EmailAddress (Result Evergreen.V346.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V346.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMaybeMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Result Evergreen.V346.Discord.HttpError Evergreen.V346.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V346.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Result Evergreen.V346.Discord.HttpError Evergreen.V346.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) (Result Evergreen.V346.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) (Result Evergreen.V346.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) (Result Evergreen.V346.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) (Result Evergreen.V346.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji (Result Evergreen.V346.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji (Result Evergreen.V346.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji (Result Evergreen.V346.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji (Result Evergreen.V346.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V346.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V346.Discord.HttpError (List ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId, Maybe Evergreen.V346.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Effect.Time.Posix Evergreen.V346.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V346.Slack.CurrentUser
            , team : Evergreen.V346.Slack.Team
            , users : List Evergreen.V346.Slack.User
            , channels : List ( Evergreen.V346.Slack.Channel, List Evergreen.V346.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Result Effect.Http.Error Evergreen.V346.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V346.Local.ChangeId Effect.Time.Posix Evergreen.V346.Call.CallId Evergreen.V346.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V346.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V346.Local.ChangeId Effect.Time.Posix Evergreen.V346.Call.CallId Evergreen.V346.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V346.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V346.Local.ChangeId Evergreen.V346.Call.ConnectionId Evergreen.V346.Cloudflare.RealtimeSessionId (List Evergreen.V346.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V346.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V346.Local.ChangeId Evergreen.V346.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Discord.UserAuth (Result Evergreen.V346.Discord.HttpError Evergreen.V346.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Result Evergreen.V346.Discord.HttpError Evergreen.V346.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
        (Result
            Evergreen.V346.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId
                , members : List (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
                }
            , List
                ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId
                , { guild : Evergreen.V346.Discord.GatewayGuild
                  , channels : List Evergreen.V346.Discord.Channel
                  , icon : Maybe Evergreen.V346.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Bool Evergreen.V346.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V346.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.AttachmentId, Evergreen.V346.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V346.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.AttachmentId, Evergreen.V346.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V346.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V346.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V346.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V346.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Result Evergreen.V346.Discord.HttpError Evergreen.V346.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Result Evergreen.V346.Discord.HttpError (List Evergreen.V346.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V346.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V346.DmChannelId.DmChannelId Evergreen.V346.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V346.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V346.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V346.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
        (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V346.Discord.HttpError
            { guild : Evergreen.V346.Discord.GatewayGuild
            , channels : List Evergreen.V346.Discord.Channel
            , icon : Maybe Evergreen.V346.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Result Evergreen.V346.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V346.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (List ( Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId, Result Effect.Http.Error Evergreen.V346.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId, Result Effect.Http.Error Evergreen.V346.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (List ( Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V346.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V346.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V346.Discord.HttpError (List Evergreen.V346.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V346.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V346.SecretId.SecretId Evergreen.V346.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V346.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Result Evergreen.V346.Discord.HttpError ( Evergreen.V346.Discord.Guild, List Evergreen.V346.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V346.FileStatus.FileHash Int (Maybe (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
