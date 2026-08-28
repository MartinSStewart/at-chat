module Evergreen.V364.Types exposing (..)

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
import Evergreen.V364.AiChat
import Evergreen.V364.Audio
import Evergreen.V364.Call
import Evergreen.V364.ChannelDescription
import Evergreen.V364.ChannelName
import Evergreen.V364.Coord
import Evergreen.V364.CssPixels
import Evergreen.V364.CustomEmoji
import Evergreen.V364.Discord
import Evergreen.V364.DiscordAttachmentId
import Evergreen.V364.DiscordUserData
import Evergreen.V364.DmChannel
import Evergreen.V364.DmChannelId
import Evergreen.V364.Drawing
import Evergreen.V364.Editable
import Evergreen.V364.EmailAddress
import Evergreen.V364.Embed
import Evergreen.V364.Emoji
import Evergreen.V364.FileStatus
import Evergreen.V364.Game
import Evergreen.V364.Go
import Evergreen.V364.GuildName
import Evergreen.V364.Id
import Evergreen.V364.IdArray
import Evergreen.V364.ImageEditor
import Evergreen.V364.ImageViewer
import Evergreen.V364.LinkedAndOtherDiscordUsers
import Evergreen.V364.Local
import Evergreen.V364.LocalState
import Evergreen.V364.Log
import Evergreen.V364.LoginForm
import Evergreen.V364.MembersAndOwner
import Evergreen.V364.Message
import Evergreen.V364.MessageInput
import Evergreen.V364.MessageView
import Evergreen.V364.MuteSettings
import Evergreen.V364.MyUi
import Evergreen.V364.NonemptyDict
import Evergreen.V364.NonemptySet
import Evergreen.V364.OneOrGreater
import Evergreen.V364.OneToOne
import Evergreen.V364.Pages.Admin
import Evergreen.V364.Pagination
import Evergreen.V364.PersonName
import Evergreen.V364.Ports
import Evergreen.V364.Postmark
import Evergreen.V364.Range
import Evergreen.V364.RecoveryLogin
import Evergreen.V364.RichText
import Evergreen.V364.Route
import Evergreen.V364.Scroll
import Evergreen.V364.SecretId
import Evergreen.V364.SessionIdHash
import Evergreen.V364.SheepGame
import Evergreen.V364.Slack
import Evergreen.V364.Sticker
import Evergreen.V364.TextEditor
import Evergreen.V364.ToBackendLog
import Evergreen.V364.Touch
import Evergreen.V364.TwoFactorAuthentication
import Evergreen.V364.Ui.Anim
import Evergreen.V364.Untrusted
import Evergreen.V364.User
import Evergreen.V364.UserAgent
import Evergreen.V364.UserColor
import Evergreen.V364.UserSession
import Evergreen.V364.WordSpellingGame
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
    | LoginFormMsg Evergreen.V364.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V364.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V364.Pages.Admin.Msg
    | PressedLogOut Evergreen.V364.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V364.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V364.Route.Route
    | SelectedFilesToAttach ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V364.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V364.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V364.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V364.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V364.NonemptyDict.NonemptyDict Int Evergreen.V364.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V364.NonemptyDict.NonemptyDict Int Evergreen.V364.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRoute Evergreen.V364.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V364.NonemptySet.NonemptySet (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V364.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V364.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V364.AiChat.Msg
    | GameMsg Evergreen.V364.Game.Msg
    | GoSpectatorMsg Evergreen.V364.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V364.Editable.Msg Evergreen.V364.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V364.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute )
        { fileId : Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute )
        { fileId : Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage Evergreen.V364.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V364.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V364.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V364.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V364.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V364.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V364.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V364.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId
        , otherUserId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V364.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRoute Evergreen.V364.MessageInput.Msg
    | MessageInputMsg Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRoute Evergreen.V364.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V364.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V364.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V364.Range.Range, Evergreen.V364.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V364.Range.Range, Evergreen.V364.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V364.Call.FromJs)
    | VoiceChatMsg Evergreen.V364.Call.Msg
    | PressedChannelHeaderTab Evergreen.V364.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V364.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V364.Audio.LoadError Evergreen.V364.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V364.Id.AnyGuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V364.Id.AnyGuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) Evergreen.V364.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V364.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V364.UserSession.UserSession
    , currentlyViewing : Evergreen.V364.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) Evergreen.V364.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.LocalState.DiscordFrontendGuild
    , user : Evergreen.V364.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.User.FrontendUser
    , discordUsers : Evergreen.V364.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V364.SessionIdHash.SessionIdHash Evergreen.V364.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V364.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId) Evergreen.V364.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId) Evergreen.V364.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V364.Call.CallId (Evergreen.V364.NonemptyDict.NonemptyDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V364.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V364.Go.PublicGoMatchData Evergreen.V364.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V364.Route.Route
    , windowSize : Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V364.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V364.Audio.LoadError Evergreen.V364.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V364.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V364.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V364.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData) (List Evergreen.V364.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V364.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V364.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.ChannelName.ChannelName Evergreen.V364.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.ChannelName.ChannelName Evergreen.V364.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V364.GuildName.GuildName (Evergreen.V364.UserSession.ToBeFilledInByBackend (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V364.Id.Viewing_DiscordDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V364.UserSession.SetViewing
    | Local_SetName Evergreen.V364.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V364.Id.GuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V364.Id.GuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V364.Id.DiscordGuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V364.Id.DiscordGuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V364.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V364.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V364.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.QuestionId Evergreen.V364.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V364.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V364.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V364.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V364.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V364.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V364.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V364.NonemptySet.NonemptySet (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V364.Call.LocalChange
    | Local_Game Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Game.LocalChange
    | Local_Drawing Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Drawing.AnchorType Evergreen.V364.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.User.FrontendUser Effect.Time.Posix Evergreen.V364.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V364.RichText.RichText (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))) Evergreen.V364.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId) Evergreen.V364.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V364.Id.DiscordGuildOrDmId Evergreen.V364.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V364.RichText.RichText (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))) Evergreen.V364.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId) Evergreen.V364.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.ChannelName.ChannelName Evergreen.V364.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.ChannelName.ChannelName Evergreen.V364.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.User.FrontendUser
    | Server_MemberLeft (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V364.LocalState.JoinGuildError
            { guildId : Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId
            , guild : Evergreen.V364.LocalState.FrontendGuild
            , owner : Evergreen.V364.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V364.RichText.RichText (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V364.RichText.RichText (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V364.Id.Viewing_DiscordDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V364.RichText.RichText (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Maybe Evergreen.V364.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Maybe Evergreen.V364.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V364.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V364.SessionIdHash.SessionIdHash Evergreen.V364.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V364.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V364.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V364.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V364.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V364.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Bool Evergreen.V364.ChannelName.ChannelName (Evergreen.V364.Discord.OptionalData (Maybe String)) (List Evergreen.V364.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
        (Evergreen.V364.NonemptyDict.NonemptyDict
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) Evergreen.V364.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Maybe (Evergreen.V364.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V364.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V364.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V364.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V364.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V364.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V364.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (Evergreen.V364.Discord.OptionalData (Maybe String)) (Evergreen.V364.Discord.OptionalData (Maybe String)) (List Evergreen.V364.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId) Evergreen.V364.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
        (Evergreen.V364.MembersAndOwner.MembersAndOwner
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.PersonName.PersonName Evergreen.V364.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId) Evergreen.V364.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId) Evergreen.V364.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V364.Call.ServerChange
    | Server_Game (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Game.LocalChange
    | Server_Drawing (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Drawing.AnchorType Evergreen.V364.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V364.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V364.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V364.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V364.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V364.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V364.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V364.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V364.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V364.Id.AnyGuildOrDmId Evergreen.V364.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V364.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels) (Maybe Evergreen.V364.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V364.SheepGame.Input (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels) (Maybe Evergreen.V364.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V364.Id.GuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V364.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V364.UserColor.Selection
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V364.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V364.Local.Local LocalMsg Evergreen.V364.LocalState.LocalState
    , admin : Evergreen.V364.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V364.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V364.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V364.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V364.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V364.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.ThreadRoute ) (Evergreen.V364.NonemptyDict.NonemptyDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V364.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V364.Scroll.ScrollPosition
    , textEditor : Evergreen.V364.TextEditor.Model
    , profilePictureEditor : Evergreen.V364.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId, Evergreen.V364.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V364.Emoji.Model
    , voiceChat : Evergreen.V364.Call.Model
    , games : SeqDict.SeqDict Evergreen.V364.Id.GuildOrDmId Evergreen.V364.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V364.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V364.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V364.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V364.Range.Range
                , direction : Evergreen.V364.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V364.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V364.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V364.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V364.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V364.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V364.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V364.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V364.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V364.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V364.MyUi.LastCopy
    , drag : Evergreen.V364.Touch.Drag
    , dragPrevious : Evergreen.V364.Touch.Drag
    , aiChatModel : Evergreen.V364.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V364.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V364.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V364.Audio.LoadError Evergreen.V364.Audio.Source
    , startupData : Evergreen.V364.Ports.StartupData
    , appBadgeCount : Maybe Int
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V364.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V364.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V364.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V364.FileStatus.FileHash
    , metadata : Maybe Evergreen.V364.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId, Evergreen.V364.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId, Evergreen.V364.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V364.DmChannelId.DmChannelId, Evergreen.V364.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId, Evergreen.V364.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId, Evergreen.V364.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId, Evergreen.V364.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V364.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V364.NonemptyDict.NonemptyDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V364.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V364.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V364.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V364.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V364.DmChannelId.DmChannelId Evergreen.V364.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) Evergreen.V364.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.Slack.Id Evergreen.V364.Slack.ChannelId) Evergreen.V364.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V364.OneToOne.OneToOne String (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    , slackUsers : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.Slack.Id Evergreen.V364.Slack.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    , slackServers : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.Slack.Id Evergreen.V364.Slack.TeamId) (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    , slackToken : Maybe Evergreen.V364.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V364.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V364.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V364.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V364.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId, Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V364.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V364.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V364.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V364.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.LocalState.LoadingDiscordChannel Evergreen.V364.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V364.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId) Evergreen.V364.Sticker.StickerData
    , discordStickers : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.Discord.Id Evergreen.V364.Discord.StickerId) (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId) Evergreen.V364.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V364.OneToOne.OneToOne Evergreen.V364.RichText.DiscordCustomEmojiIdAndName (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V364.Postmark.ApiKey
    , serverSecret : Evergreen.V364.SecretId.SecretId Evergreen.V364.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V364.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.GamePublicId) ( Evergreen.V364.DmChannelId.GuildOrFullDmId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V364.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V364.WordSpellingGame.WordList
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V364.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.Id.ThreadRoute (Maybe Evergreen.V364.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V364.DmChannelId.DmChannelId Evergreen.V364.Id.ThreadRoute (Maybe Evergreen.V364.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V364.Id.Id Evergreen.V364.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V364.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V364.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V364.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V364.Untrusted.Untrusted Evergreen.V364.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V364.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V364.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V364.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V364.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V364.PersonName.PersonName Evergreen.V364.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V364.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V364.Slack.OAuthCode Evergreen.V364.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V364.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V364.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V364.Id.Id Evergreen.V364.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V364.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V364.EmailAddress.EmailAddress (Result Evergreen.V364.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V364.EmailAddress.EmailAddress (Result Evergreen.V364.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V364.EmailAddress.EmailAddress (Result Evergreen.V364.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V364.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMaybeMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Result Evergreen.V364.Discord.HttpError Evergreen.V364.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V364.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Result Evergreen.V364.Discord.HttpError Evergreen.V364.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) (Result Evergreen.V364.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) (Result Evergreen.V364.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) (Result Evergreen.V364.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) (Result Evergreen.V364.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji (Result Evergreen.V364.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji (Result Evergreen.V364.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji (Result Evergreen.V364.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji (Result Evergreen.V364.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V364.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V364.Discord.HttpError (List ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId, Maybe Evergreen.V364.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Effect.Time.Posix Evergreen.V364.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V364.Slack.CurrentUser
            , team : Evergreen.V364.Slack.Team
            , users : List Evergreen.V364.Slack.User
            , channels : List ( Evergreen.V364.Slack.Channel, List Evergreen.V364.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Result Effect.Http.Error Evergreen.V364.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Discord.UserAuth (Result Evergreen.V364.Discord.HttpError Evergreen.V364.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Result Evergreen.V364.Discord.HttpError Evergreen.V364.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
        (Result
            Evergreen.V364.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId
                , members : List (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
                }
            , List
                ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId
                , { guild : Evergreen.V364.Discord.GatewayGuild
                  , channels : List Evergreen.V364.Discord.Channel
                  , icon : Maybe Evergreen.V364.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Maybe String) Evergreen.V364.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V364.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.AttachmentId, Evergreen.V364.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V364.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.AttachmentId, Evergreen.V364.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V364.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V364.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V364.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V364.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (Result Evergreen.V364.Discord.HttpError Evergreen.V364.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Result Evergreen.V364.Discord.HttpError (List Evergreen.V364.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V364.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V364.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V364.DmChannelId.DmChannelId Evergreen.V364.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V364.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V364.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V364.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
        (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V364.Discord.HttpError
            { guild : Evergreen.V364.Discord.GatewayGuild
            , channels : List Evergreen.V364.Discord.Channel
            , icon : Maybe Evergreen.V364.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Result Evergreen.V364.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V364.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (List ( Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId, Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId, Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (List ( Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V364.Discord.HttpError (List Evergreen.V364.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V364.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V364.SecretId.SecretId Evergreen.V364.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V364.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Result Evergreen.V364.Discord.HttpError ( Evergreen.V364.Discord.Guild, List Evergreen.V364.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V364.FileStatus.FileHash Int (Maybe (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Call.CallId
