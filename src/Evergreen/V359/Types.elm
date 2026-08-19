module Evergreen.V359.Types exposing (..)

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
import Evergreen.V359.AiChat
import Evergreen.V359.Audio
import Evergreen.V359.Call
import Evergreen.V359.ChannelDescription
import Evergreen.V359.ChannelName
import Evergreen.V359.Coord
import Evergreen.V359.CssPixels
import Evergreen.V359.CustomEmoji
import Evergreen.V359.Discord
import Evergreen.V359.DiscordAttachmentId
import Evergreen.V359.DiscordUserData
import Evergreen.V359.DmChannel
import Evergreen.V359.DmChannelId
import Evergreen.V359.Drawing
import Evergreen.V359.Editable
import Evergreen.V359.EmailAddress
import Evergreen.V359.Embed
import Evergreen.V359.Emoji
import Evergreen.V359.FileStatus
import Evergreen.V359.Game
import Evergreen.V359.Go
import Evergreen.V359.GuildName
import Evergreen.V359.Id
import Evergreen.V359.ImageEditor
import Evergreen.V359.ImageViewer
import Evergreen.V359.LinkedAndOtherDiscordUsers
import Evergreen.V359.Local
import Evergreen.V359.LocalState
import Evergreen.V359.Log
import Evergreen.V359.LoginForm
import Evergreen.V359.MembersAndOwner
import Evergreen.V359.Message
import Evergreen.V359.MessageInput
import Evergreen.V359.MessageView
import Evergreen.V359.MuteSettings
import Evergreen.V359.MyUi
import Evergreen.V359.NonemptyDict
import Evergreen.V359.NonemptySet
import Evergreen.V359.OneOrGreater
import Evergreen.V359.OneToOne
import Evergreen.V359.Pages.Admin
import Evergreen.V359.Pagination
import Evergreen.V359.PersonName
import Evergreen.V359.Ports
import Evergreen.V359.Postmark
import Evergreen.V359.Range
import Evergreen.V359.RecoveryLogin
import Evergreen.V359.RichText
import Evergreen.V359.Route
import Evergreen.V359.Scroll
import Evergreen.V359.SecretId
import Evergreen.V359.SessionIdHash
import Evergreen.V359.Slack
import Evergreen.V359.Sticker
import Evergreen.V359.TextEditor
import Evergreen.V359.ToBackendLog
import Evergreen.V359.Touch
import Evergreen.V359.TwoFactorAuthentication
import Evergreen.V359.Ui.Anim
import Evergreen.V359.Untrusted
import Evergreen.V359.User
import Evergreen.V359.UserAgent
import Evergreen.V359.UserSession
import Evergreen.V359.WordSpellingGame
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
    | LoginFormMsg Evergreen.V359.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V359.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V359.Pages.Admin.Msg
    | PressedLogOut Evergreen.V359.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V359.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V359.Route.Route
    | SelectedFilesToAttach ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V359.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V359.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V359.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V359.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V359.NonemptyDict.NonemptyDict Int Evergreen.V359.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V359.NonemptyDict.NonemptyDict Int Evergreen.V359.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRoute Evergreen.V359.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V359.NonemptySet.NonemptySet (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V359.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V359.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V359.AiChat.Msg
    | GameMsg Evergreen.V359.Game.Msg
    | GoSpectatorMsg Evergreen.V359.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V359.Editable.Msg Evergreen.V359.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V359.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V359.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute )
        { fileId : Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute )
        { fileId : Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V359.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage Evergreen.V359.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V359.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V359.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V359.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V359.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V359.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V359.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V359.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId
        , otherUserId : Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRoute Evergreen.V359.MessageInput.Msg
    | MessageInputMsg Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRoute Evergreen.V359.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V359.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V359.Range.Range, Evergreen.V359.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V359.Range.Range, Evergreen.V359.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V359.Call.FromJs)
    | VoiceChatMsg Evergreen.V359.Call.Msg
    | PressedChannelHeaderTab Evergreen.V359.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V359.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V359.Audio.LoadError Evergreen.V359.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V359.Id.AnyGuildOrDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V359.Id.AnyGuildOrDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId) Evergreen.V359.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V359.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V359.UserSession.UserSession
    , currentlyViewing : Evergreen.V359.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) Evergreen.V359.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.LocalState.DiscordFrontendGuild
    , user : Evergreen.V359.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.User.FrontendUser
    , discordUsers : Evergreen.V359.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V359.SessionIdHash.SessionIdHash Evergreen.V359.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V359.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId) Evergreen.V359.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId) Evergreen.V359.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V359.Call.CallId (Evergreen.V359.NonemptyDict.NonemptyDict ( Evergreen.V359.Id.Id Evergreen.V359.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V359.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V359.Go.PublicGoMatchData Evergreen.V359.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V359.Route.Route
    , windowSize : Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V359.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V359.Audio.LoadError Evergreen.V359.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V359.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V359.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V359.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileData) (List Evergreen.V359.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V359.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V359.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.ChannelName.ChannelName Evergreen.V359.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.ChannelName.ChannelName Evergreen.V359.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V359.GuildName.GuildName (Evergreen.V359.UserSession.ToBeFilledInByBackend (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V359.Id.Viewing_DiscordDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V359.UserSession.SetViewing
    | Local_SetName Evergreen.V359.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V359.Id.GuildOrDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Message.Message Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V359.Id.GuildOrDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId) (Evergreen.V359.Message.Message Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V359.Id.DiscordGuildOrDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Message.Message Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V359.Id.DiscordGuildOrDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId) (Evergreen.V359.Message.Message Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V359.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V359.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V359.UserSession.UserOptionSection
    | Local_SetEmailNotifications Evergreen.V359.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V359.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V359.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V359.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V359.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V359.NonemptySet.NonemptySet (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V359.Call.LocalChange
    | Local_Game Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Game.LocalChange
    | Local_Drawing Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Drawing.AnchorType Evergreen.V359.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.User.FrontendUser Effect.Time.Posix Evergreen.V359.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V359.RichText.RichText (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))) Evergreen.V359.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId) Evergreen.V359.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V359.Id.DiscordGuildOrDmId Evergreen.V359.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V359.RichText.RichText (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))) Evergreen.V359.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId) Evergreen.V359.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.ChannelName.ChannelName Evergreen.V359.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.ChannelName.ChannelName Evergreen.V359.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.User.FrontendUser
    | Server_MemberLeft (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V359.LocalState.JoinGuildError
            { guildId : Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId
            , guild : Evergreen.V359.LocalState.FrontendGuild
            , owner : Evergreen.V359.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V359.RichText.RichText (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))) (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V359.RichText.RichText (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V359.Id.Viewing_DiscordDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V359.RichText.RichText (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Maybe Evergreen.V359.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Maybe Evergreen.V359.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V359.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V359.SessionIdHash.SessionIdHash Evergreen.V359.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V359.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V359.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V359.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V359.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V359.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Bool Evergreen.V359.ChannelName.ChannelName (Evergreen.V359.Discord.OptionalData (Maybe String)) (List Evergreen.V359.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
        (Evergreen.V359.NonemptyDict.NonemptyDict
            (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) Evergreen.V359.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Maybe (Evergreen.V359.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V359.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V359.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V359.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V359.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V359.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V359.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (Evergreen.V359.Discord.OptionalData (Maybe String)) (Evergreen.V359.Discord.OptionalData (Maybe String)) (List Evergreen.V359.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.RoleId) Evergreen.V359.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
        (Evergreen.V359.MembersAndOwner.MembersAndOwner
            (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V359.Discord.Id Evergreen.V359.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId) Evergreen.V359.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId) Evergreen.V359.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V359.Call.ServerChange
    | Server_Game (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Game.LocalChange
    | Server_Drawing (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Drawing.AnchorType Evergreen.V359.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V359.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V359.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V359.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V359.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V359.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V359.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V359.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V359.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V359.Id.AnyGuildOrDmId Evergreen.V359.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V359.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels) (Maybe Evergreen.V359.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId) (Evergreen.V359.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V359.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V359.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V359.Local.Local LocalMsg Evergreen.V359.LocalState.LocalState
    , admin : Evergreen.V359.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId, Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V359.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V359.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V359.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V359.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V359.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.ThreadRoute ) (Evergreen.V359.NonemptyDict.NonemptyDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V359.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V359.Scroll.ScrollPosition
    , textEditor : Evergreen.V359.TextEditor.Model
    , profilePictureEditor : Evergreen.V359.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId, Evergreen.V359.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V359.Emoji.Model
    , voiceChat : Evergreen.V359.Call.Model
    , games : SeqDict.SeqDict Evergreen.V359.Id.GuildOrDmId Evergreen.V359.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V359.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V359.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V359.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V359.Range.Range
                , direction : Evergreen.V359.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V359.NonemptyDict.NonemptyDict Int Evergreen.V359.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V359.NonemptyDict.NonemptyDict Int Evergreen.V359.Touch.Touch
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
    | AdminToFrontend Evergreen.V359.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V359.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V359.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V359.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V359.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V359.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V359.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V359.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V359.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V359.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V359.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V359.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V359.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V359.Audio.LoadError Evergreen.V359.Audio.Source
    , startupData : Evergreen.V359.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V359.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V359.Id.Id Evergreen.V359.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V359.Id.Id Evergreen.V359.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V359.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V359.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V359.FileStatus.FileHash
    , metadata : Maybe Evergreen.V359.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId, Evergreen.V359.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId, Evergreen.V359.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V359.DmChannelId.DmChannelId, Evergreen.V359.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId, Evergreen.V359.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId, Evergreen.V359.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId, Evergreen.V359.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V359.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V359.NonemptyDict.NonemptyDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V359.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V359.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V359.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V359.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V359.DmChannelId.DmChannelId Evergreen.V359.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) Evergreen.V359.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V359.OneToOne.OneToOne (Evergreen.V359.Slack.Id Evergreen.V359.Slack.ChannelId) Evergreen.V359.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V359.OneToOne.OneToOne String (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    , slackUsers : Evergreen.V359.OneToOne.OneToOne (Evergreen.V359.Slack.Id Evergreen.V359.Slack.UserId) (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    , slackServers : Evergreen.V359.OneToOne.OneToOne (Evergreen.V359.Slack.Id Evergreen.V359.Slack.TeamId) (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    , slackToken : Maybe Evergreen.V359.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V359.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V359.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V359.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V359.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId, Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V359.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V359.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V359.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V359.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.LocalState.LoadingDiscordChannel Evergreen.V359.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V359.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId) Evergreen.V359.Sticker.StickerData
    , discordStickers : Evergreen.V359.OneToOne.OneToOne (Evergreen.V359.Discord.Id Evergreen.V359.Discord.StickerId) (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId) Evergreen.V359.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V359.OneToOne.OneToOne Evergreen.V359.RichText.DiscordCustomEmojiIdAndName (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V359.Postmark.ApiKey
    , serverSecret : Evergreen.V359.SecretId.SecretId Evergreen.V359.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V359.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V359.OneToOne.OneToOne (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.GamePublicId) ( Evergreen.V359.DmChannelId.GuildOrFullDmId, Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V359.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V359.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V359.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.Id.ThreadRoute (Maybe Evergreen.V359.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V359.DmChannelId.DmChannelId Evergreen.V359.Id.ThreadRoute (Maybe Evergreen.V359.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V359.Id.Id Evergreen.V359.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V359.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V359.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V359.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V359.Untrusted.Untrusted Evergreen.V359.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V359.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V359.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V359.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V359.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V359.PersonName.PersonName Evergreen.V359.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V359.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V359.Slack.OAuthCode Evergreen.V359.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V359.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V359.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V359.Id.Id Evergreen.V359.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V359.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V359.EmailAddress.EmailAddress (Result Evergreen.V359.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V359.EmailAddress.EmailAddress (Result Evergreen.V359.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V359.EmailAddress.EmailAddress (Result Evergreen.V359.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V359.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMaybeMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Result Evergreen.V359.Discord.HttpError Evergreen.V359.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V359.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Result Evergreen.V359.Discord.HttpError Evergreen.V359.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) (Result Evergreen.V359.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) (Result Evergreen.V359.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) (Result Evergreen.V359.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) (Result Evergreen.V359.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji (Result Evergreen.V359.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji (Result Evergreen.V359.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji (Result Evergreen.V359.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji (Result Evergreen.V359.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V359.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V359.Discord.HttpError (List ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId, Maybe Evergreen.V359.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Effect.Time.Posix Evergreen.V359.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V359.Slack.CurrentUser
            , team : Evergreen.V359.Slack.Team
            , users : List Evergreen.V359.Slack.User
            , channels : List ( Evergreen.V359.Slack.Channel, List Evergreen.V359.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Result Effect.Http.Error Evergreen.V359.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Discord.UserAuth (Result Evergreen.V359.Discord.HttpError Evergreen.V359.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Result Evergreen.V359.Discord.HttpError Evergreen.V359.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
        (Result
            Evergreen.V359.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId
                , members : List (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
                }
            , List
                ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId
                , { guild : Evergreen.V359.Discord.GatewayGuild
                  , channels : List Evergreen.V359.Discord.Channel
                  , icon : Maybe Evergreen.V359.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Maybe String) Evergreen.V359.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V359.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.AttachmentId, Evergreen.V359.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V359.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.AttachmentId, Evergreen.V359.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V359.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V359.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V359.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V359.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) (Result Evergreen.V359.Discord.HttpError Evergreen.V359.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Result Evergreen.V359.Discord.HttpError (List Evergreen.V359.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V359.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V359.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V359.DmChannelId.DmChannelId Evergreen.V359.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V359.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V359.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V359.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
        (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V359.Discord.HttpError
            { guild : Evergreen.V359.Discord.GatewayGuild
            , channels : List Evergreen.V359.Discord.Channel
            , icon : Maybe Evergreen.V359.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Result Evergreen.V359.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V359.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (List ( Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId, Result Effect.Http.Error Evergreen.V359.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId, Result Effect.Http.Error Evergreen.V359.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (List ( Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V359.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V359.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V359.Discord.HttpError (List Evergreen.V359.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V359.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V359.SecretId.SecretId Evergreen.V359.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V359.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Result Evergreen.V359.Discord.HttpError ( Evergreen.V359.Discord.Guild, List Evergreen.V359.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V359.FileStatus.FileHash Int (Maybe (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Call.CallId
