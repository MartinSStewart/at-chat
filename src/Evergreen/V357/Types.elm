module Evergreen.V357.Types exposing (..)

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
import Evergreen.V357.AiChat
import Evergreen.V357.Audio
import Evergreen.V357.Call
import Evergreen.V357.ChannelDescription
import Evergreen.V357.ChannelName
import Evergreen.V357.Coord
import Evergreen.V357.CssPixels
import Evergreen.V357.CustomEmoji
import Evergreen.V357.Discord
import Evergreen.V357.DiscordAttachmentId
import Evergreen.V357.DiscordUserData
import Evergreen.V357.DmChannel
import Evergreen.V357.DmChannelId
import Evergreen.V357.Drawing
import Evergreen.V357.Editable
import Evergreen.V357.EmailAddress
import Evergreen.V357.Embed
import Evergreen.V357.Emoji
import Evergreen.V357.FileStatus
import Evergreen.V357.Game
import Evergreen.V357.Go
import Evergreen.V357.GuildName
import Evergreen.V357.Id
import Evergreen.V357.ImageEditor
import Evergreen.V357.ImageViewer
import Evergreen.V357.LinkedAndOtherDiscordUsers
import Evergreen.V357.Local
import Evergreen.V357.LocalState
import Evergreen.V357.Log
import Evergreen.V357.LoginForm
import Evergreen.V357.MembersAndOwner
import Evergreen.V357.Message
import Evergreen.V357.MessageInput
import Evergreen.V357.MessageView
import Evergreen.V357.MuteSettings
import Evergreen.V357.MyUi
import Evergreen.V357.NonemptyDict
import Evergreen.V357.NonemptySet
import Evergreen.V357.OneOrGreater
import Evergreen.V357.OneToOne
import Evergreen.V357.Pages.Admin
import Evergreen.V357.Pagination
import Evergreen.V357.PersonName
import Evergreen.V357.Ports
import Evergreen.V357.Postmark
import Evergreen.V357.Range
import Evergreen.V357.RecoveryLogin
import Evergreen.V357.RichText
import Evergreen.V357.Route
import Evergreen.V357.Scroll
import Evergreen.V357.SecretId
import Evergreen.V357.SessionIdHash
import Evergreen.V357.Slack
import Evergreen.V357.Sticker
import Evergreen.V357.TextEditor
import Evergreen.V357.ToBackendLog
import Evergreen.V357.Touch
import Evergreen.V357.TwoFactorAuthentication
import Evergreen.V357.Ui.Anim
import Evergreen.V357.Untrusted
import Evergreen.V357.User
import Evergreen.V357.UserAgent
import Evergreen.V357.UserSession
import Evergreen.V357.WordSpellingGame
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
    | LoginFormMsg Evergreen.V357.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V357.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V357.Pages.Admin.Msg
    | PressedLogOut Evergreen.V357.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V357.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V357.Route.Route
    | SelectedFilesToAttach ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V357.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V357.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V357.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V357.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V357.NonemptyDict.NonemptyDict Int Evergreen.V357.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V357.NonemptyDict.NonemptyDict Int Evergreen.V357.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRoute Evergreen.V357.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V357.NonemptySet.NonemptySet (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V357.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V357.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V357.AiChat.Msg
    | GameMsg Evergreen.V357.Game.Msg
    | GoSpectatorMsg Evergreen.V357.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V357.Editable.Msg Evergreen.V357.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V357.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V357.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute )
        { fileId : Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute )
        { fileId : Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V357.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage Evergreen.V357.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V357.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V357.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V357.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V357.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V357.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V357.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V357.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId
        , otherUserId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRoute Evergreen.V357.MessageInput.Msg
    | MessageInputMsg Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRoute Evergreen.V357.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V357.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V357.Range.Range, Evergreen.V357.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V357.Range.Range, Evergreen.V357.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V357.Call.FromJs)
    | VoiceChatMsg Evergreen.V357.Call.Msg
    | PressedChannelHeaderTab Evergreen.V357.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V357.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V357.Audio.LoadError Evergreen.V357.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V357.Id.AnyGuildOrDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V357.Id.AnyGuildOrDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId) Evergreen.V357.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V357.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V357.UserSession.UserSession
    , currentlyViewing : Evergreen.V357.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) Evergreen.V357.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.LocalState.DiscordFrontendGuild
    , user : Evergreen.V357.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.User.FrontendUser
    , discordUsers : Evergreen.V357.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V357.SessionIdHash.SessionIdHash Evergreen.V357.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V357.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId) Evergreen.V357.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId) Evergreen.V357.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V357.Call.CallId (Evergreen.V357.NonemptyDict.NonemptyDict ( Evergreen.V357.Id.Id Evergreen.V357.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V357.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V357.Go.PublicGoMatchData Evergreen.V357.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V357.Route.Route
    , windowSize : Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V357.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V357.Audio.LoadError Evergreen.V357.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V357.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V357.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V357.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileData) (List Evergreen.V357.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V357.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V357.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.ChannelName.ChannelName Evergreen.V357.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.ChannelName.ChannelName Evergreen.V357.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V357.GuildName.GuildName (Evergreen.V357.UserSession.ToBeFilledInByBackend (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V357.Id.Viewing_DiscordDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V357.UserSession.SetViewing
    | Local_SetName Evergreen.V357.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V357.Id.GuildOrDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V357.Id.GuildOrDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId) (Evergreen.V357.Message.Message Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V357.Id.DiscordGuildOrDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V357.Id.DiscordGuildOrDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId) (Evergreen.V357.Message.Message Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V357.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V357.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V357.UserSession.UserOptionSection
    | Local_SetEmailNotifications Evergreen.V357.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V357.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V357.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V357.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V357.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V357.NonemptySet.NonemptySet (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V357.Call.LocalChange
    | Local_Game Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Game.LocalChange
    | Local_Drawing Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Drawing.AnchorType Evergreen.V357.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.User.FrontendUser Effect.Time.Posix Evergreen.V357.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V357.RichText.RichText (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))) Evergreen.V357.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId) Evergreen.V357.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V357.Id.DiscordGuildOrDmId Evergreen.V357.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V357.RichText.RichText (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))) Evergreen.V357.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId) Evergreen.V357.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.ChannelName.ChannelName Evergreen.V357.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.ChannelName.ChannelName Evergreen.V357.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.User.FrontendUser
    | Server_MemberLeft (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V357.LocalState.JoinGuildError
            { guildId : Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId
            , guild : Evergreen.V357.LocalState.FrontendGuild
            , owner : Evergreen.V357.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V357.RichText.RichText (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))) (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V357.RichText.RichText (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V357.Id.Viewing_DiscordDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V357.RichText.RichText (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Maybe Evergreen.V357.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Maybe Evergreen.V357.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V357.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V357.SessionIdHash.SessionIdHash Evergreen.V357.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V357.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V357.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V357.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V357.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V357.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Bool Evergreen.V357.ChannelName.ChannelName (Evergreen.V357.Discord.OptionalData (Maybe String)) (List Evergreen.V357.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
        (Evergreen.V357.NonemptyDict.NonemptyDict
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) Evergreen.V357.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Maybe (Evergreen.V357.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V357.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V357.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V357.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V357.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V357.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V357.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (Evergreen.V357.Discord.OptionalData (Maybe String)) (Evergreen.V357.Discord.OptionalData (Maybe String)) (List Evergreen.V357.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId) Evergreen.V357.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
        (Evergreen.V357.MembersAndOwner.MembersAndOwner
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId) Evergreen.V357.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId) Evergreen.V357.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V357.Call.ServerChange
    | Server_Game (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Game.LocalChange
    | Server_Drawing (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Drawing.AnchorType Evergreen.V357.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V357.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V357.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V357.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V357.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V357.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V357.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V357.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V357.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V357.Id.AnyGuildOrDmId Evergreen.V357.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V357.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels) (Maybe Evergreen.V357.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId) (Evergreen.V357.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V357.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V357.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V357.Local.Local LocalMsg Evergreen.V357.LocalState.LocalState
    , admin : Evergreen.V357.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId, Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V357.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V357.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V357.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V357.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V357.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.ThreadRoute ) (Evergreen.V357.NonemptyDict.NonemptyDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V357.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V357.Scroll.ScrollPosition
    , textEditor : Evergreen.V357.TextEditor.Model
    , profilePictureEditor : Evergreen.V357.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId, Evergreen.V357.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V357.Emoji.Model
    , voiceChat : Evergreen.V357.Call.Model
    , games : SeqDict.SeqDict Evergreen.V357.Id.GuildOrDmId Evergreen.V357.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V357.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V357.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V357.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V357.Range.Range
                , direction : Evergreen.V357.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V357.NonemptyDict.NonemptyDict Int Evergreen.V357.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V357.NonemptyDict.NonemptyDict Int Evergreen.V357.Touch.Touch
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
    | AdminToFrontend Evergreen.V357.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V357.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V357.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V357.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V357.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V357.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V357.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V357.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V357.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V357.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V357.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V357.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V357.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V357.Audio.LoadError Evergreen.V357.Audio.Source
    , startupData : Evergreen.V357.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V357.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V357.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V357.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V357.FileStatus.FileHash
    , metadata : Maybe Evergreen.V357.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId, Evergreen.V357.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V357.DmChannelId.DmChannelId, Evergreen.V357.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId, Evergreen.V357.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId, Evergreen.V357.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V357.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V357.NonemptyDict.NonemptyDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V357.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V357.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V357.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V357.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V357.DmChannelId.DmChannelId Evergreen.V357.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) Evergreen.V357.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.Slack.Id Evergreen.V357.Slack.ChannelId) Evergreen.V357.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V357.OneToOne.OneToOne String (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    , slackUsers : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.Slack.Id Evergreen.V357.Slack.UserId) (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    , slackServers : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.Slack.Id Evergreen.V357.Slack.TeamId) (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    , slackToken : Maybe Evergreen.V357.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V357.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V357.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V357.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V357.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId, Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V357.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V357.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V357.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V357.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.LocalState.LoadingDiscordChannel Evergreen.V357.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V357.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId) Evergreen.V357.Sticker.StickerData
    , discordStickers : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.Discord.Id Evergreen.V357.Discord.StickerId) (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId) Evergreen.V357.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V357.OneToOne.OneToOne Evergreen.V357.RichText.DiscordCustomEmojiIdAndName (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V357.Postmark.ApiKey
    , serverSecret : Evergreen.V357.SecretId.SecretId Evergreen.V357.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V357.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.GamePublicId) ( Evergreen.V357.DmChannelId.GuildOrFullDmId, Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V357.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V357.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V357.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.Id.ThreadRoute (Maybe Evergreen.V357.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V357.DmChannelId.DmChannelId Evergreen.V357.Id.ThreadRoute (Maybe Evergreen.V357.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V357.Id.Id Evergreen.V357.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V357.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V357.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V357.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V357.Untrusted.Untrusted Evergreen.V357.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V357.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V357.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V357.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V357.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V357.PersonName.PersonName Evergreen.V357.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V357.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V357.Slack.OAuthCode Evergreen.V357.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V357.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V357.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V357.Id.Id Evergreen.V357.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V357.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V357.EmailAddress.EmailAddress (Result Evergreen.V357.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V357.EmailAddress.EmailAddress (Result Evergreen.V357.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V357.EmailAddress.EmailAddress (Result Evergreen.V357.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V357.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMaybeMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Result Evergreen.V357.Discord.HttpError Evergreen.V357.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V357.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Result Evergreen.V357.Discord.HttpError Evergreen.V357.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) (Result Evergreen.V357.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) (Result Evergreen.V357.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) (Result Evergreen.V357.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) (Result Evergreen.V357.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji (Result Evergreen.V357.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji (Result Evergreen.V357.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji (Result Evergreen.V357.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji (Result Evergreen.V357.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V357.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V357.Discord.HttpError (List ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId, Maybe Evergreen.V357.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Effect.Time.Posix Evergreen.V357.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V357.Slack.CurrentUser
            , team : Evergreen.V357.Slack.Team
            , users : List Evergreen.V357.Slack.User
            , channels : List ( Evergreen.V357.Slack.Channel, List Evergreen.V357.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Result Effect.Http.Error Evergreen.V357.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Discord.UserAuth (Result Evergreen.V357.Discord.HttpError Evergreen.V357.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Result Evergreen.V357.Discord.HttpError Evergreen.V357.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
        (Result
            Evergreen.V357.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId
                , members : List (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
                }
            , List
                ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId
                , { guild : Evergreen.V357.Discord.GatewayGuild
                  , channels : List Evergreen.V357.Discord.Channel
                  , icon : Maybe Evergreen.V357.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Maybe String) Evergreen.V357.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V357.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.AttachmentId, Evergreen.V357.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V357.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.AttachmentId, Evergreen.V357.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V357.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V357.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V357.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V357.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (Result Evergreen.V357.Discord.HttpError Evergreen.V357.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Result Evergreen.V357.Discord.HttpError (List Evergreen.V357.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V357.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V357.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V357.DmChannelId.DmChannelId Evergreen.V357.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V357.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V357.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V357.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
        (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V357.Discord.HttpError
            { guild : Evergreen.V357.Discord.GatewayGuild
            , channels : List Evergreen.V357.Discord.Channel
            , icon : Maybe Evergreen.V357.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Result Evergreen.V357.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V357.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (List ( Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId, Result Effect.Http.Error Evergreen.V357.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId, Result Effect.Http.Error Evergreen.V357.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (List ( Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V357.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V357.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V357.Discord.HttpError (List Evergreen.V357.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V357.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V357.SecretId.SecretId Evergreen.V357.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V357.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Result Evergreen.V357.Discord.HttpError ( Evergreen.V357.Discord.Guild, List Evergreen.V357.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V357.FileStatus.FileHash Int (Maybe (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Call.CallId
