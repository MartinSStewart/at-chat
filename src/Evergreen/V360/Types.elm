module Evergreen.V360.Types exposing (..)

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
import Evergreen.V360.AiChat
import Evergreen.V360.Audio
import Evergreen.V360.Call
import Evergreen.V360.ChannelDescription
import Evergreen.V360.ChannelName
import Evergreen.V360.Coord
import Evergreen.V360.CssPixels
import Evergreen.V360.CustomEmoji
import Evergreen.V360.Discord
import Evergreen.V360.DiscordAttachmentId
import Evergreen.V360.DiscordUserData
import Evergreen.V360.DmChannel
import Evergreen.V360.DmChannelId
import Evergreen.V360.Drawing
import Evergreen.V360.Editable
import Evergreen.V360.EmailAddress
import Evergreen.V360.Embed
import Evergreen.V360.Emoji
import Evergreen.V360.FileStatus
import Evergreen.V360.Game
import Evergreen.V360.Go
import Evergreen.V360.GuildName
import Evergreen.V360.Id
import Evergreen.V360.ImageEditor
import Evergreen.V360.ImageViewer
import Evergreen.V360.LinkedAndOtherDiscordUsers
import Evergreen.V360.Local
import Evergreen.V360.LocalState
import Evergreen.V360.Log
import Evergreen.V360.LoginForm
import Evergreen.V360.MembersAndOwner
import Evergreen.V360.Message
import Evergreen.V360.MessageInput
import Evergreen.V360.MessageView
import Evergreen.V360.MuteSettings
import Evergreen.V360.MyUi
import Evergreen.V360.NonemptyDict
import Evergreen.V360.NonemptySet
import Evergreen.V360.OneOrGreater
import Evergreen.V360.OneToOne
import Evergreen.V360.Pages.Admin
import Evergreen.V360.Pagination
import Evergreen.V360.PersonName
import Evergreen.V360.Ports
import Evergreen.V360.Postmark
import Evergreen.V360.Range
import Evergreen.V360.RecoveryLogin
import Evergreen.V360.RichText
import Evergreen.V360.Route
import Evergreen.V360.Scroll
import Evergreen.V360.SecretId
import Evergreen.V360.SessionIdHash
import Evergreen.V360.SheepGame
import Evergreen.V360.Slack
import Evergreen.V360.Sticker
import Evergreen.V360.TextEditor
import Evergreen.V360.ToBackendLog
import Evergreen.V360.Touch
import Evergreen.V360.TwoFactorAuthentication
import Evergreen.V360.Ui.Anim
import Evergreen.V360.Untrusted
import Evergreen.V360.User
import Evergreen.V360.UserAgent
import Evergreen.V360.UserColor
import Evergreen.V360.UserSession
import Evergreen.V360.WordSpellingGame
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
    | LoginFormMsg Evergreen.V360.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V360.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V360.Pages.Admin.Msg
    | PressedLogOut Evergreen.V360.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V360.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V360.Route.Route
    | SelectedFilesToAttach ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V360.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V360.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V360.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V360.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V360.NonemptyDict.NonemptyDict Int Evergreen.V360.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V360.NonemptyDict.NonemptyDict Int Evergreen.V360.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRoute Evergreen.V360.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V360.NonemptySet.NonemptySet (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V360.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V360.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V360.AiChat.Msg
    | GameMsg Evergreen.V360.Game.Msg
    | GoSpectatorMsg Evergreen.V360.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V360.Editable.Msg Evergreen.V360.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V360.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute )
        { fileId : Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute )
        { fileId : Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage Evergreen.V360.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V360.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V360.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V360.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V360.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V360.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V360.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V360.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId
        , otherUserId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V360.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRoute Evergreen.V360.MessageInput.Msg
    | MessageInputMsg Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRoute Evergreen.V360.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V360.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V360.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V360.Range.Range, Evergreen.V360.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V360.Range.Range, Evergreen.V360.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V360.Call.FromJs)
    | VoiceChatMsg Evergreen.V360.Call.Msg
    | PressedChannelHeaderTab Evergreen.V360.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V360.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V360.Audio.LoadError Evergreen.V360.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V360.Id.AnyGuildOrDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V360.Id.AnyGuildOrDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) Evergreen.V360.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V360.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V360.UserSession.UserSession
    , currentlyViewing : Evergreen.V360.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) Evergreen.V360.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.LocalState.DiscordFrontendGuild
    , user : Evergreen.V360.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.User.FrontendUser
    , discordUsers : Evergreen.V360.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V360.SessionIdHash.SessionIdHash Evergreen.V360.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V360.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId) Evergreen.V360.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId) Evergreen.V360.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V360.Call.CallId (Evergreen.V360.NonemptyDict.NonemptyDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V360.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V360.Go.PublicGoMatchData Evergreen.V360.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V360.Route.Route
    , windowSize : Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V360.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V360.Audio.LoadError Evergreen.V360.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V360.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V360.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V360.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileData) (List Evergreen.V360.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V360.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V360.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.ChannelName.ChannelName Evergreen.V360.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.ChannelName.ChannelName Evergreen.V360.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V360.GuildName.GuildName (Evergreen.V360.UserSession.ToBeFilledInByBackend (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V360.Id.Viewing_DiscordDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V360.UserSession.SetViewing
    | Local_SetName Evergreen.V360.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V360.Id.GuildOrDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V360.Id.GuildOrDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V360.Id.DiscordGuildOrDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V360.Id.DiscordGuildOrDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V360.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V360.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V360.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Array.Array Evergreen.V360.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V360.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V360.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V360.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V360.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V360.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V360.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V360.NonemptySet.NonemptySet (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V360.Call.LocalChange
    | Local_Game Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Game.LocalChange
    | Local_Drawing Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Drawing.AnchorType Evergreen.V360.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.User.FrontendUser Effect.Time.Posix Evergreen.V360.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V360.RichText.RichText (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))) Evergreen.V360.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId) Evergreen.V360.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V360.Id.DiscordGuildOrDmId Evergreen.V360.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V360.RichText.RichText (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))) Evergreen.V360.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId) Evergreen.V360.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.ChannelName.ChannelName Evergreen.V360.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.ChannelName.ChannelName Evergreen.V360.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.User.FrontendUser
    | Server_MemberLeft (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V360.LocalState.JoinGuildError
            { guildId : Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId
            , guild : Evergreen.V360.LocalState.FrontendGuild
            , owner : Evergreen.V360.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V360.RichText.RichText (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V360.RichText.RichText (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V360.Id.Viewing_DiscordDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V360.RichText.RichText (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Maybe Evergreen.V360.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Maybe Evergreen.V360.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V360.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V360.SessionIdHash.SessionIdHash Evergreen.V360.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V360.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V360.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V360.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V360.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V360.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Bool Evergreen.V360.ChannelName.ChannelName (Evergreen.V360.Discord.OptionalData (Maybe String)) (List Evergreen.V360.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
        (Evergreen.V360.NonemptyDict.NonemptyDict
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) Evergreen.V360.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Maybe (Evergreen.V360.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V360.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V360.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V360.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V360.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V360.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V360.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (Evergreen.V360.Discord.OptionalData (Maybe String)) (Evergreen.V360.Discord.OptionalData (Maybe String)) (List Evergreen.V360.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId) Evergreen.V360.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
        (Evergreen.V360.MembersAndOwner.MembersAndOwner
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.PersonName.PersonName Evergreen.V360.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId) Evergreen.V360.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId) Evergreen.V360.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V360.Call.ServerChange
    | Server_Game (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Game.LocalChange
    | Server_Drawing (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Drawing.AnchorType Evergreen.V360.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V360.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V360.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V360.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V360.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V360.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V360.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V360.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V360.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V360.Id.AnyGuildOrDmId Evergreen.V360.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V360.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels) (Maybe Evergreen.V360.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V360.SheepGame.Input (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels) (Maybe Evergreen.V360.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V360.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V360.UserColor.Selection
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V360.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V360.Local.Local LocalMsg Evergreen.V360.LocalState.LocalState
    , admin : Evergreen.V360.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V360.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V360.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V360.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V360.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V360.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.ThreadRoute ) (Evergreen.V360.NonemptyDict.NonemptyDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V360.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V360.Scroll.ScrollPosition
    , textEditor : Evergreen.V360.TextEditor.Model
    , profilePictureEditor : Evergreen.V360.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId, Evergreen.V360.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V360.Emoji.Model
    , voiceChat : Evergreen.V360.Call.Model
    , games : SeqDict.SeqDict Evergreen.V360.Id.GuildOrDmId Evergreen.V360.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V360.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V360.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V360.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V360.Range.Range
                , direction : Evergreen.V360.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V360.NonemptyDict.NonemptyDict Int Evergreen.V360.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V360.NonemptyDict.NonemptyDict Int Evergreen.V360.Touch.Touch
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
    | AdminToFrontend Evergreen.V360.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V360.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V360.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V360.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V360.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V360.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V360.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V360.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V360.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V360.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V360.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V360.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V360.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V360.Audio.LoadError Evergreen.V360.Audio.Source
    , startupData : Evergreen.V360.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V360.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V360.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V360.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V360.FileStatus.FileHash
    , metadata : Maybe Evergreen.V360.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId, Evergreen.V360.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId, Evergreen.V360.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V360.DmChannelId.DmChannelId, Evergreen.V360.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId, Evergreen.V360.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId, Evergreen.V360.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId, Evergreen.V360.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V360.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V360.NonemptyDict.NonemptyDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V360.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V360.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V360.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V360.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V360.DmChannelId.DmChannelId Evergreen.V360.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) Evergreen.V360.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.Slack.Id Evergreen.V360.Slack.ChannelId) Evergreen.V360.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V360.OneToOne.OneToOne String (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    , slackUsers : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.Slack.Id Evergreen.V360.Slack.UserId) (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    , slackServers : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.Slack.Id Evergreen.V360.Slack.TeamId) (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    , slackToken : Maybe Evergreen.V360.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V360.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V360.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V360.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V360.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId, Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V360.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V360.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V360.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V360.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.LocalState.LoadingDiscordChannel Evergreen.V360.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V360.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId) Evergreen.V360.Sticker.StickerData
    , discordStickers : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.Discord.Id Evergreen.V360.Discord.StickerId) (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId) Evergreen.V360.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V360.OneToOne.OneToOne Evergreen.V360.RichText.DiscordCustomEmojiIdAndName (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V360.Postmark.ApiKey
    , serverSecret : Evergreen.V360.SecretId.SecretId Evergreen.V360.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V360.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.GamePublicId) ( Evergreen.V360.DmChannelId.GuildOrFullDmId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V360.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V360.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V360.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.Id.ThreadRoute (Maybe Evergreen.V360.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V360.DmChannelId.DmChannelId Evergreen.V360.Id.ThreadRoute (Maybe Evergreen.V360.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V360.Id.Id Evergreen.V360.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V360.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V360.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V360.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V360.Untrusted.Untrusted Evergreen.V360.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V360.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V360.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V360.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V360.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V360.PersonName.PersonName Evergreen.V360.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V360.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V360.Slack.OAuthCode Evergreen.V360.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V360.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V360.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V360.Id.Id Evergreen.V360.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V360.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V360.EmailAddress.EmailAddress (Result Evergreen.V360.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V360.EmailAddress.EmailAddress (Result Evergreen.V360.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V360.EmailAddress.EmailAddress (Result Evergreen.V360.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V360.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMaybeMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Result Evergreen.V360.Discord.HttpError Evergreen.V360.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V360.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Result Evergreen.V360.Discord.HttpError Evergreen.V360.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) (Result Evergreen.V360.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) (Result Evergreen.V360.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) (Result Evergreen.V360.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) (Result Evergreen.V360.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji (Result Evergreen.V360.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji (Result Evergreen.V360.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji (Result Evergreen.V360.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji (Result Evergreen.V360.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V360.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V360.Discord.HttpError (List ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId, Maybe Evergreen.V360.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Effect.Time.Posix Evergreen.V360.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V360.Slack.CurrentUser
            , team : Evergreen.V360.Slack.Team
            , users : List Evergreen.V360.Slack.User
            , channels : List ( Evergreen.V360.Slack.Channel, List Evergreen.V360.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Result Effect.Http.Error Evergreen.V360.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Discord.UserAuth (Result Evergreen.V360.Discord.HttpError Evergreen.V360.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Result Evergreen.V360.Discord.HttpError Evergreen.V360.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
        (Result
            Evergreen.V360.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId
                , members : List (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
                }
            , List
                ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId
                , { guild : Evergreen.V360.Discord.GatewayGuild
                  , channels : List Evergreen.V360.Discord.Channel
                  , icon : Maybe Evergreen.V360.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Maybe String) Evergreen.V360.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V360.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.AttachmentId, Evergreen.V360.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V360.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.AttachmentId, Evergreen.V360.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V360.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V360.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V360.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V360.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (Result Evergreen.V360.Discord.HttpError Evergreen.V360.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Result Evergreen.V360.Discord.HttpError (List Evergreen.V360.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V360.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V360.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V360.DmChannelId.DmChannelId Evergreen.V360.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V360.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V360.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V360.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
        (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V360.Discord.HttpError
            { guild : Evergreen.V360.Discord.GatewayGuild
            , channels : List Evergreen.V360.Discord.Channel
            , icon : Maybe Evergreen.V360.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Result Evergreen.V360.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V360.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (List ( Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId, Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId, Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (List ( Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V360.Discord.HttpError (List Evergreen.V360.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V360.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V360.SecretId.SecretId Evergreen.V360.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V360.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Result Evergreen.V360.Discord.HttpError ( Evergreen.V360.Discord.Guild, List Evergreen.V360.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V360.FileStatus.FileHash Int (Maybe (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Call.CallId
