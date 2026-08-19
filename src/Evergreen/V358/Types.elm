module Evergreen.V358.Types exposing (..)

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
import Evergreen.V358.AiChat
import Evergreen.V358.Audio
import Evergreen.V358.Call
import Evergreen.V358.ChannelDescription
import Evergreen.V358.ChannelName
import Evergreen.V358.Coord
import Evergreen.V358.CssPixels
import Evergreen.V358.CustomEmoji
import Evergreen.V358.Discord
import Evergreen.V358.DiscordAttachmentId
import Evergreen.V358.DiscordUserData
import Evergreen.V358.DmChannel
import Evergreen.V358.DmChannelId
import Evergreen.V358.Drawing
import Evergreen.V358.Editable
import Evergreen.V358.EmailAddress
import Evergreen.V358.Embed
import Evergreen.V358.Emoji
import Evergreen.V358.FileStatus
import Evergreen.V358.Game
import Evergreen.V358.Go
import Evergreen.V358.GuildName
import Evergreen.V358.Id
import Evergreen.V358.ImageEditor
import Evergreen.V358.ImageViewer
import Evergreen.V358.LinkedAndOtherDiscordUsers
import Evergreen.V358.Local
import Evergreen.V358.LocalState
import Evergreen.V358.Log
import Evergreen.V358.LoginForm
import Evergreen.V358.MembersAndOwner
import Evergreen.V358.Message
import Evergreen.V358.MessageInput
import Evergreen.V358.MessageView
import Evergreen.V358.MuteSettings
import Evergreen.V358.MyUi
import Evergreen.V358.NonemptyDict
import Evergreen.V358.NonemptySet
import Evergreen.V358.OneOrGreater
import Evergreen.V358.OneToOne
import Evergreen.V358.Pages.Admin
import Evergreen.V358.Pagination
import Evergreen.V358.PersonName
import Evergreen.V358.Ports
import Evergreen.V358.Postmark
import Evergreen.V358.Range
import Evergreen.V358.RecoveryLogin
import Evergreen.V358.RichText
import Evergreen.V358.Route
import Evergreen.V358.Scroll
import Evergreen.V358.SecretId
import Evergreen.V358.SessionIdHash
import Evergreen.V358.Slack
import Evergreen.V358.Sticker
import Evergreen.V358.TextEditor
import Evergreen.V358.ToBackendLog
import Evergreen.V358.Touch
import Evergreen.V358.TwoFactorAuthentication
import Evergreen.V358.Ui.Anim
import Evergreen.V358.Untrusted
import Evergreen.V358.User
import Evergreen.V358.UserAgent
import Evergreen.V358.UserSession
import Evergreen.V358.WordSpellingGame
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


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | LoginFormMsg Evergreen.V358.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V358.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V358.Pages.Admin.Msg
    | PressedLogOut Evergreen.V358.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V358.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V358.Route.Route
    | SelectedFilesToAttach ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V358.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V358.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V358.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V358.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V358.NonemptyDict.NonemptyDict Int Evergreen.V358.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V358.NonemptyDict.NonemptyDict Int Evergreen.V358.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRoute Evergreen.V358.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V358.NonemptySet.NonemptySet (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V358.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V358.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V358.AiChat.Msg
    | GameMsg Evergreen.V358.Game.Msg
    | GoSpectatorMsg Evergreen.V358.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V358.Editable.Msg Evergreen.V358.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V358.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V358.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute )
        { fileId : Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute )
        { fileId : Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V358.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage Evergreen.V358.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V358.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V358.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V358.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V358.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V358.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V358.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V358.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId
        , otherUserId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRoute Evergreen.V358.MessageInput.Msg
    | MessageInputMsg Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRoute Evergreen.V358.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V358.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V358.Range.Range, Evergreen.V358.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V358.Range.Range, Evergreen.V358.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V358.Call.FromJs)
    | VoiceChatMsg Evergreen.V358.Call.Msg
    | PressedChannelHeaderTab Evergreen.V358.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V358.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V358.Audio.LoadError Evergreen.V358.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V358.Id.AnyGuildOrDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V358.Id.AnyGuildOrDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) Evergreen.V358.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V358.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V358.UserSession.UserSession
    , currentlyViewing : Evergreen.V358.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) Evergreen.V358.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.LocalState.DiscordFrontendGuild
    , user : Evergreen.V358.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.User.FrontendUser
    , discordUsers : Evergreen.V358.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V358.SessionIdHash.SessionIdHash Evergreen.V358.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V358.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId) Evergreen.V358.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId) Evergreen.V358.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V358.Call.CallId (Evergreen.V358.NonemptyDict.NonemptyDict ( Evergreen.V358.Id.Id Evergreen.V358.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V358.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V358.Go.PublicGoMatchData Evergreen.V358.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V358.Route.Route
    , windowSize : Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V358.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V358.Audio.LoadError Evergreen.V358.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V358.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V358.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V358.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileData) (List Evergreen.V358.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V358.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V358.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.ChannelName.ChannelName Evergreen.V358.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.ChannelName.ChannelName Evergreen.V358.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V358.GuildName.GuildName (Evergreen.V358.UserSession.ToBeFilledInByBackend (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V358.Id.Viewing_DiscordDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V358.UserSession.SetViewing
    | Local_SetName Evergreen.V358.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V358.Id.GuildOrDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V358.Id.GuildOrDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V358.Id.DiscordGuildOrDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V358.Id.DiscordGuildOrDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V358.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V358.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V358.UserSession.UserOptionSection
    | Local_SetEmailNotifications Evergreen.V358.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V358.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V358.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V358.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V358.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V358.NonemptySet.NonemptySet (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V358.Call.LocalChange
    | Local_Game Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Game.LocalChange
    | Local_Drawing Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Drawing.AnchorType Evergreen.V358.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.User.FrontendUser Effect.Time.Posix Evergreen.V358.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V358.RichText.RichText (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))) Evergreen.V358.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId) Evergreen.V358.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V358.Id.DiscordGuildOrDmId Evergreen.V358.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V358.RichText.RichText (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))) Evergreen.V358.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId) Evergreen.V358.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.ChannelName.ChannelName Evergreen.V358.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.ChannelName.ChannelName Evergreen.V358.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.User.FrontendUser
    | Server_MemberLeft (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V358.LocalState.JoinGuildError
            { guildId : Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId
            , guild : Evergreen.V358.LocalState.FrontendGuild
            , owner : Evergreen.V358.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V358.RichText.RichText (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V358.RichText.RichText (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V358.Id.Viewing_DiscordDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V358.RichText.RichText (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Maybe Evergreen.V358.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Maybe Evergreen.V358.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V358.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V358.SessionIdHash.SessionIdHash Evergreen.V358.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V358.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V358.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V358.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V358.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V358.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Bool Evergreen.V358.ChannelName.ChannelName (Evergreen.V358.Discord.OptionalData (Maybe String)) (List Evergreen.V358.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
        (Evergreen.V358.NonemptyDict.NonemptyDict
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) Evergreen.V358.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Maybe (Evergreen.V358.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V358.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V358.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V358.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V358.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V358.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V358.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (Evergreen.V358.Discord.OptionalData (Maybe String)) (Evergreen.V358.Discord.OptionalData (Maybe String)) (List Evergreen.V358.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId) Evergreen.V358.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
        (Evergreen.V358.MembersAndOwner.MembersAndOwner
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId) Evergreen.V358.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId) Evergreen.V358.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V358.Call.ServerChange
    | Server_Game (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Game.LocalChange
    | Server_Drawing (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Drawing.AnchorType Evergreen.V358.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V358.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V358.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V358.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V358.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V358.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V358.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V358.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V358.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V358.Id.AnyGuildOrDmId Evergreen.V358.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V358.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels) (Maybe Evergreen.V358.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V358.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V358.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V358.Local.Local LocalMsg Evergreen.V358.LocalState.LocalState
    , admin : Evergreen.V358.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V358.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V358.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V358.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V358.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V358.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.ThreadRoute ) (Evergreen.V358.NonemptyDict.NonemptyDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V358.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V358.Scroll.ScrollPosition
    , textEditor : Evergreen.V358.TextEditor.Model
    , profilePictureEditor : Evergreen.V358.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId, Evergreen.V358.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V358.Emoji.Model
    , voiceChat : Evergreen.V358.Call.Model
    , games : SeqDict.SeqDict Evergreen.V358.Id.GuildOrDmId Evergreen.V358.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V358.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V358.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V358.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V358.Range.Range
                , direction : Evergreen.V358.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V358.NonemptyDict.NonemptyDict Int Evergreen.V358.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V358.NonemptyDict.NonemptyDict Int Evergreen.V358.Touch.Touch
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
    | AdminToFrontend Evergreen.V358.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V358.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V358.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V358.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V358.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V358.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V358.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V358.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V358.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V358.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V358.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V358.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V358.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V358.Audio.LoadError Evergreen.V358.Audio.Source
    , startupData : Evergreen.V358.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V358.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V358.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V358.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V358.FileStatus.FileHash
    , metadata : Maybe Evergreen.V358.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId, Evergreen.V358.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId, Evergreen.V358.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V358.DmChannelId.DmChannelId, Evergreen.V358.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId, Evergreen.V358.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId, Evergreen.V358.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId, Evergreen.V358.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V358.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V358.NonemptyDict.NonemptyDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V358.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V358.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V358.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V358.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V358.DmChannelId.DmChannelId Evergreen.V358.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) Evergreen.V358.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.Slack.Id Evergreen.V358.Slack.ChannelId) Evergreen.V358.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V358.OneToOne.OneToOne String (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    , slackUsers : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.Slack.Id Evergreen.V358.Slack.UserId) (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    , slackServers : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.Slack.Id Evergreen.V358.Slack.TeamId) (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    , slackToken : Maybe Evergreen.V358.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V358.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V358.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V358.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V358.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId, Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V358.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V358.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V358.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V358.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.LocalState.LoadingDiscordChannel Evergreen.V358.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V358.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId) Evergreen.V358.Sticker.StickerData
    , discordStickers : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.Discord.Id Evergreen.V358.Discord.StickerId) (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId) Evergreen.V358.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V358.OneToOne.OneToOne Evergreen.V358.RichText.DiscordCustomEmojiIdAndName (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V358.Postmark.ApiKey
    , serverSecret : Evergreen.V358.SecretId.SecretId Evergreen.V358.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V358.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.GamePublicId) ( Evergreen.V358.DmChannelId.GuildOrFullDmId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V358.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V358.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V358.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.Id.ThreadRoute (Maybe Evergreen.V358.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V358.DmChannelId.DmChannelId Evergreen.V358.Id.ThreadRoute (Maybe Evergreen.V358.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V358.Id.Id Evergreen.V358.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V358.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V358.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V358.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V358.Untrusted.Untrusted Evergreen.V358.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V358.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V358.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V358.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V358.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V358.PersonName.PersonName Evergreen.V358.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V358.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V358.Slack.OAuthCode Evergreen.V358.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V358.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V358.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V358.Id.Id Evergreen.V358.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V358.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V358.EmailAddress.EmailAddress (Result Evergreen.V358.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V358.EmailAddress.EmailAddress (Result Evergreen.V358.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V358.EmailAddress.EmailAddress (Result Evergreen.V358.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V358.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMaybeMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Result Evergreen.V358.Discord.HttpError Evergreen.V358.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V358.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Result Evergreen.V358.Discord.HttpError Evergreen.V358.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) (Result Evergreen.V358.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) (Result Evergreen.V358.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) (Result Evergreen.V358.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) (Result Evergreen.V358.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji (Result Evergreen.V358.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji (Result Evergreen.V358.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji (Result Evergreen.V358.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji (Result Evergreen.V358.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V358.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V358.Discord.HttpError (List ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId, Maybe Evergreen.V358.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Effect.Time.Posix Evergreen.V358.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V358.Slack.CurrentUser
            , team : Evergreen.V358.Slack.Team
            , users : List Evergreen.V358.Slack.User
            , channels : List ( Evergreen.V358.Slack.Channel, List Evergreen.V358.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Result Effect.Http.Error Evergreen.V358.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Discord.UserAuth (Result Evergreen.V358.Discord.HttpError Evergreen.V358.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Result Evergreen.V358.Discord.HttpError Evergreen.V358.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
        (Result
            Evergreen.V358.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId
                , members : List (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
                }
            , List
                ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId
                , { guild : Evergreen.V358.Discord.GatewayGuild
                  , channels : List Evergreen.V358.Discord.Channel
                  , icon : Maybe Evergreen.V358.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Maybe String) Evergreen.V358.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V358.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.AttachmentId, Evergreen.V358.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V358.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.AttachmentId, Evergreen.V358.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V358.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V358.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V358.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V358.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (Result Evergreen.V358.Discord.HttpError Evergreen.V358.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Result Evergreen.V358.Discord.HttpError (List Evergreen.V358.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V358.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V358.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V358.DmChannelId.DmChannelId Evergreen.V358.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V358.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V358.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V358.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
        (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V358.Discord.HttpError
            { guild : Evergreen.V358.Discord.GatewayGuild
            , channels : List Evergreen.V358.Discord.Channel
            , icon : Maybe Evergreen.V358.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Result Evergreen.V358.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V358.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (List ( Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId, Result Effect.Http.Error Evergreen.V358.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId, Result Effect.Http.Error Evergreen.V358.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (List ( Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V358.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V358.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V358.Discord.HttpError (List Evergreen.V358.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V358.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V358.SecretId.SecretId Evergreen.V358.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V358.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Result Evergreen.V358.Discord.HttpError ( Evergreen.V358.Discord.Guild, List Evergreen.V358.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V358.FileStatus.FileHash Int (Maybe (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Call.CallId
