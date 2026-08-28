module Evergreen.V363.Types exposing (..)

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
import Evergreen.V363.AiChat
import Evergreen.V363.Audio
import Evergreen.V363.Call
import Evergreen.V363.ChannelDescription
import Evergreen.V363.ChannelName
import Evergreen.V363.Coord
import Evergreen.V363.CssPixels
import Evergreen.V363.CustomEmoji
import Evergreen.V363.Discord
import Evergreen.V363.DiscordAttachmentId
import Evergreen.V363.DiscordUserData
import Evergreen.V363.DmChannel
import Evergreen.V363.DmChannelId
import Evergreen.V363.Drawing
import Evergreen.V363.Editable
import Evergreen.V363.EmailAddress
import Evergreen.V363.Embed
import Evergreen.V363.Emoji
import Evergreen.V363.FileStatus
import Evergreen.V363.Game
import Evergreen.V363.Go
import Evergreen.V363.GuildName
import Evergreen.V363.Id
import Evergreen.V363.ImageEditor
import Evergreen.V363.ImageViewer
import Evergreen.V363.LinkedAndOtherDiscordUsers
import Evergreen.V363.Local
import Evergreen.V363.LocalState
import Evergreen.V363.Log
import Evergreen.V363.LoginForm
import Evergreen.V363.MembersAndOwner
import Evergreen.V363.Message
import Evergreen.V363.MessageInput
import Evergreen.V363.MessageView
import Evergreen.V363.MuteSettings
import Evergreen.V363.MyUi
import Evergreen.V363.NonemptyDict
import Evergreen.V363.NonemptySet
import Evergreen.V363.OneOrGreater
import Evergreen.V363.OneToOne
import Evergreen.V363.Pages.Admin
import Evergreen.V363.Pagination
import Evergreen.V363.PersonName
import Evergreen.V363.Ports
import Evergreen.V363.Postmark
import Evergreen.V363.Range
import Evergreen.V363.RecoveryLogin
import Evergreen.V363.RichText
import Evergreen.V363.Route
import Evergreen.V363.Scroll
import Evergreen.V363.SecretId
import Evergreen.V363.SessionIdHash
import Evergreen.V363.SheepGame
import Evergreen.V363.Slack
import Evergreen.V363.Sticker
import Evergreen.V363.TextEditor
import Evergreen.V363.ToBackendLog
import Evergreen.V363.Touch
import Evergreen.V363.TwoFactorAuthentication
import Evergreen.V363.Ui.Anim
import Evergreen.V363.Untrusted
import Evergreen.V363.User
import Evergreen.V363.UserAgent
import Evergreen.V363.UserColor
import Evergreen.V363.UserSession
import Evergreen.V363.WordSpellingGame
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
    | LoginFormMsg Evergreen.V363.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V363.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V363.Pages.Admin.Msg
    | PressedLogOut Evergreen.V363.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V363.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V363.Route.Route
    | SelectedFilesToAttach ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V363.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V363.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V363.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V363.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V363.NonemptyDict.NonemptyDict Int Evergreen.V363.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V363.NonemptyDict.NonemptyDict Int Evergreen.V363.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRoute Evergreen.V363.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V363.NonemptySet.NonemptySet (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V363.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V363.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V363.AiChat.Msg
    | GameMsg Evergreen.V363.Game.Msg
    | GoSpectatorMsg Evergreen.V363.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V363.Editable.Msg Evergreen.V363.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V363.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute )
        { fileId : Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute )
        { fileId : Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage Evergreen.V363.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V363.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V363.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V363.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V363.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V363.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V363.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V363.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId
        , otherUserId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V363.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRoute Evergreen.V363.MessageInput.Msg
    | MessageInputMsg Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRoute Evergreen.V363.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V363.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V363.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V363.Range.Range, Evergreen.V363.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V363.Range.Range, Evergreen.V363.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V363.Call.FromJs)
    | VoiceChatMsg Evergreen.V363.Call.Msg
    | PressedChannelHeaderTab Evergreen.V363.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V363.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V363.Audio.LoadError Evergreen.V363.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V363.Id.AnyGuildOrDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V363.Id.AnyGuildOrDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) Evergreen.V363.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V363.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V363.UserSession.UserSession
    , currentlyViewing : Evergreen.V363.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) Evergreen.V363.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.LocalState.DiscordFrontendGuild
    , user : Evergreen.V363.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.User.FrontendUser
    , discordUsers : Evergreen.V363.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V363.SessionIdHash.SessionIdHash Evergreen.V363.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V363.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId) Evergreen.V363.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId) Evergreen.V363.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V363.Call.CallId (Evergreen.V363.NonemptyDict.NonemptyDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V363.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V363.Go.PublicGoMatchData Evergreen.V363.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V363.Route.Route
    , windowSize : Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V363.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V363.Audio.LoadError Evergreen.V363.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V363.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V363.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V363.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileData) (List Evergreen.V363.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V363.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V363.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.ChannelName.ChannelName Evergreen.V363.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.ChannelName.ChannelName Evergreen.V363.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V363.GuildName.GuildName (Evergreen.V363.UserSession.ToBeFilledInByBackend (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V363.Id.Viewing_DiscordDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V363.UserSession.SetViewing
    | Local_SetName Evergreen.V363.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V363.Id.GuildOrDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V363.Id.GuildOrDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V363.Id.DiscordGuildOrDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V363.Id.DiscordGuildOrDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V363.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V363.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V363.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Array.Array Evergreen.V363.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V363.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V363.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V363.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V363.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V363.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V363.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V363.NonemptySet.NonemptySet (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V363.Call.LocalChange
    | Local_Game Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Game.LocalChange
    | Local_Drawing Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Drawing.AnchorType Evergreen.V363.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.User.FrontendUser Effect.Time.Posix Evergreen.V363.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V363.RichText.RichText (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))) Evergreen.V363.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId) Evergreen.V363.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V363.Id.DiscordGuildOrDmId Evergreen.V363.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V363.RichText.RichText (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))) Evergreen.V363.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId) Evergreen.V363.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.ChannelName.ChannelName Evergreen.V363.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.ChannelName.ChannelName Evergreen.V363.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.User.FrontendUser
    | Server_MemberLeft (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V363.LocalState.JoinGuildError
            { guildId : Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId
            , guild : Evergreen.V363.LocalState.FrontendGuild
            , owner : Evergreen.V363.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V363.RichText.RichText (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V363.RichText.RichText (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V363.Id.Viewing_DiscordDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V363.RichText.RichText (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Maybe Evergreen.V363.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Maybe Evergreen.V363.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V363.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V363.SessionIdHash.SessionIdHash Evergreen.V363.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V363.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V363.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V363.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V363.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V363.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Bool Evergreen.V363.ChannelName.ChannelName (Evergreen.V363.Discord.OptionalData (Maybe String)) (List Evergreen.V363.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
        (Evergreen.V363.NonemptyDict.NonemptyDict
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) Evergreen.V363.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Maybe (Evergreen.V363.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V363.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V363.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V363.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V363.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V363.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V363.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (Evergreen.V363.Discord.OptionalData (Maybe String)) (Evergreen.V363.Discord.OptionalData (Maybe String)) (List Evergreen.V363.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId) Evergreen.V363.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
        (Evergreen.V363.MembersAndOwner.MembersAndOwner
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.PersonName.PersonName Evergreen.V363.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId) Evergreen.V363.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId) Evergreen.V363.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V363.Call.ServerChange
    | Server_Game (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Game.LocalChange
    | Server_Drawing (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Drawing.AnchorType Evergreen.V363.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V363.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V363.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V363.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V363.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V363.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V363.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V363.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V363.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V363.Id.AnyGuildOrDmId Evergreen.V363.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V363.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels) (Maybe Evergreen.V363.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V363.SheepGame.Input (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels) (Maybe Evergreen.V363.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V363.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V363.UserColor.Selection
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V363.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V363.Local.Local LocalMsg Evergreen.V363.LocalState.LocalState
    , admin : Evergreen.V363.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V363.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V363.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V363.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V363.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V363.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.ThreadRoute ) (Evergreen.V363.NonemptyDict.NonemptyDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V363.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V363.Scroll.ScrollPosition
    , textEditor : Evergreen.V363.TextEditor.Model
    , profilePictureEditor : Evergreen.V363.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId, Evergreen.V363.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V363.Emoji.Model
    , voiceChat : Evergreen.V363.Call.Model
    , games : SeqDict.SeqDict Evergreen.V363.Id.GuildOrDmId Evergreen.V363.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V363.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V363.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V363.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V363.Range.Range
                , direction : Evergreen.V363.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V363.NonemptyDict.NonemptyDict Int Evergreen.V363.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V363.NonemptyDict.NonemptyDict Int Evergreen.V363.Touch.Touch
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
    | AdminToFrontend Evergreen.V363.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V363.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V363.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V363.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V363.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V363.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V363.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V363.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V363.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V363.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V363.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V363.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V363.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V363.Audio.LoadError Evergreen.V363.Audio.Source
    , startupData : Evergreen.V363.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V363.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V363.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V363.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V363.FileStatus.FileHash
    , metadata : Maybe Evergreen.V363.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId, Evergreen.V363.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId, Evergreen.V363.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V363.DmChannelId.DmChannelId, Evergreen.V363.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId, Evergreen.V363.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId, Evergreen.V363.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId, Evergreen.V363.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V363.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V363.NonemptyDict.NonemptyDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V363.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V363.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V363.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V363.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V363.DmChannelId.DmChannelId Evergreen.V363.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) Evergreen.V363.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.Slack.Id Evergreen.V363.Slack.ChannelId) Evergreen.V363.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V363.OneToOne.OneToOne String (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    , slackUsers : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.Slack.Id Evergreen.V363.Slack.UserId) (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    , slackServers : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.Slack.Id Evergreen.V363.Slack.TeamId) (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    , slackToken : Maybe Evergreen.V363.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V363.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V363.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V363.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V363.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId, Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V363.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V363.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V363.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V363.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.LocalState.LoadingDiscordChannel Evergreen.V363.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V363.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId) Evergreen.V363.Sticker.StickerData
    , discordStickers : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.Discord.Id Evergreen.V363.Discord.StickerId) (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId) Evergreen.V363.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V363.OneToOne.OneToOne Evergreen.V363.RichText.DiscordCustomEmojiIdAndName (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V363.Postmark.ApiKey
    , serverSecret : Evergreen.V363.SecretId.SecretId Evergreen.V363.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V363.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.GamePublicId) ( Evergreen.V363.DmChannelId.GuildOrFullDmId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V363.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V363.WordSpellingGame.WordList
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V363.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.Id.ThreadRoute (Maybe Evergreen.V363.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V363.DmChannelId.DmChannelId Evergreen.V363.Id.ThreadRoute (Maybe Evergreen.V363.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V363.Id.Id Evergreen.V363.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V363.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V363.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V363.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V363.Untrusted.Untrusted Evergreen.V363.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V363.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V363.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V363.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V363.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V363.PersonName.PersonName Evergreen.V363.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V363.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V363.Slack.OAuthCode Evergreen.V363.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V363.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V363.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V363.Id.Id Evergreen.V363.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V363.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V363.EmailAddress.EmailAddress (Result Evergreen.V363.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V363.EmailAddress.EmailAddress (Result Evergreen.V363.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V363.EmailAddress.EmailAddress (Result Evergreen.V363.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V363.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMaybeMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Result Evergreen.V363.Discord.HttpError Evergreen.V363.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V363.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Result Evergreen.V363.Discord.HttpError Evergreen.V363.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) (Result Evergreen.V363.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) (Result Evergreen.V363.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) (Result Evergreen.V363.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) (Result Evergreen.V363.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji (Result Evergreen.V363.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji (Result Evergreen.V363.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji (Result Evergreen.V363.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji (Result Evergreen.V363.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V363.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V363.Discord.HttpError (List ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId, Maybe Evergreen.V363.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Effect.Time.Posix Evergreen.V363.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V363.Slack.CurrentUser
            , team : Evergreen.V363.Slack.Team
            , users : List Evergreen.V363.Slack.User
            , channels : List ( Evergreen.V363.Slack.Channel, List Evergreen.V363.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Result Effect.Http.Error Evergreen.V363.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Discord.UserAuth (Result Evergreen.V363.Discord.HttpError Evergreen.V363.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Result Evergreen.V363.Discord.HttpError Evergreen.V363.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
        (Result
            Evergreen.V363.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId
                , members : List (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
                }
            , List
                ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId
                , { guild : Evergreen.V363.Discord.GatewayGuild
                  , channels : List Evergreen.V363.Discord.Channel
                  , icon : Maybe Evergreen.V363.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Maybe String) Evergreen.V363.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V363.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.AttachmentId, Evergreen.V363.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V363.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.AttachmentId, Evergreen.V363.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V363.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V363.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V363.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V363.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (Result Evergreen.V363.Discord.HttpError Evergreen.V363.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Result Evergreen.V363.Discord.HttpError (List Evergreen.V363.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V363.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V363.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V363.DmChannelId.DmChannelId Evergreen.V363.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V363.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V363.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V363.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
        (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V363.Discord.HttpError
            { guild : Evergreen.V363.Discord.GatewayGuild
            , channels : List Evergreen.V363.Discord.Channel
            , icon : Maybe Evergreen.V363.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Result Evergreen.V363.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V363.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (List ( Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId, Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId, Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (List ( Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V363.Discord.HttpError (List Evergreen.V363.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V363.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V363.SecretId.SecretId Evergreen.V363.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V363.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Result Evergreen.V363.Discord.HttpError ( Evergreen.V363.Discord.Guild, List Evergreen.V363.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V363.FileStatus.FileHash Int (Maybe (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Call.CallId
