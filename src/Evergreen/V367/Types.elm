module Evergreen.V367.Types exposing (..)

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
import Evergreen.V367.AiChat
import Evergreen.V367.Audio
import Evergreen.V367.Call
import Evergreen.V367.ChannelDescription
import Evergreen.V367.ChannelName
import Evergreen.V367.Coord
import Evergreen.V367.CssPixels
import Evergreen.V367.CustomEmoji
import Evergreen.V367.Discord
import Evergreen.V367.DiscordAttachmentId
import Evergreen.V367.DiscordUserData
import Evergreen.V367.DmChannel
import Evergreen.V367.DmChannelId
import Evergreen.V367.Drawing
import Evergreen.V367.Editable
import Evergreen.V367.EmailAddress
import Evergreen.V367.Embed
import Evergreen.V367.Emoji
import Evergreen.V367.FileStatus
import Evergreen.V367.Game
import Evergreen.V367.Go
import Evergreen.V367.GuildName
import Evergreen.V367.Id
import Evergreen.V367.IdArray
import Evergreen.V367.ImageEditor
import Evergreen.V367.ImageViewer
import Evergreen.V367.LinkedAndOtherDiscordUsers
import Evergreen.V367.Local
import Evergreen.V367.LocalState
import Evergreen.V367.Log
import Evergreen.V367.LoginForm
import Evergreen.V367.MembersAndOwner
import Evergreen.V367.Message
import Evergreen.V367.MessageInput
import Evergreen.V367.MessageView
import Evergreen.V367.MuteSettings
import Evergreen.V367.MyUi
import Evergreen.V367.NonemptyDict
import Evergreen.V367.NonemptySet
import Evergreen.V367.OneOrGreater
import Evergreen.V367.OneToOne
import Evergreen.V367.Pages.Admin
import Evergreen.V367.Pagination
import Evergreen.V367.PersonName
import Evergreen.V367.Ports
import Evergreen.V367.Postmark
import Evergreen.V367.Range
import Evergreen.V367.RecoveryLogin
import Evergreen.V367.RichText
import Evergreen.V367.Route
import Evergreen.V367.Scroll
import Evergreen.V367.SecretId
import Evergreen.V367.SessionIdHash
import Evergreen.V367.SheepGame
import Evergreen.V367.Slack
import Evergreen.V367.Sticker
import Evergreen.V367.TextEditor
import Evergreen.V367.ToBackendLog
import Evergreen.V367.Touch
import Evergreen.V367.TwoFactorAuthentication
import Evergreen.V367.Ui.Anim
import Evergreen.V367.Untrusted
import Evergreen.V367.User
import Evergreen.V367.UserAgent
import Evergreen.V367.UserColor
import Evergreen.V367.UserSession
import Evergreen.V367.WordSpellingGame
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
    | LoginFormMsg Evergreen.V367.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V367.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V367.Pages.Admin.Msg
    | PressedLogOut Evergreen.V367.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V367.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V367.Route.Route
    | SelectedFilesToAttach ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V367.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V367.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V367.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V367.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V367.NonemptyDict.NonemptyDict Int Evergreen.V367.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V367.NonemptyDict.NonemptyDict Int Evergreen.V367.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRoute Evergreen.V367.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V367.NonemptySet.NonemptySet (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V367.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V367.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V367.AiChat.Msg
    | GameMsg Evergreen.V367.Game.Msg
    | GoSpectatorMsg Evergreen.V367.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V367.Editable.Msg Evergreen.V367.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V367.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute )
        { fileId : Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute )
        { fileId : Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage Evergreen.V367.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V367.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V367.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V367.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V367.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V367.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V367.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V367.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId
        , otherUserId : Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V367.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRoute Evergreen.V367.MessageInput.Msg
    | MessageInputMsg Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRoute Evergreen.V367.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V367.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V367.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V367.Range.Range, Evergreen.V367.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V367.Range.Range, Evergreen.V367.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V367.Call.FromJs)
    | VoiceChatMsg Evergreen.V367.Call.Msg
    | PressedChannelHeaderTab Evergreen.V367.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V367.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V367.Audio.LoadError Evergreen.V367.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V367.Id.AnyGuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V367.Id.AnyGuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId) Evergreen.V367.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V367.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V367.UserSession.UserSession
    , currentlyViewing : Evergreen.V367.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) Evergreen.V367.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.LocalState.DiscordFrontendGuild
    , user : Evergreen.V367.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.User.FrontendUser
    , discordUsers : Evergreen.V367.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V367.SessionIdHash.SessionIdHash Evergreen.V367.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V367.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId) Evergreen.V367.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId) Evergreen.V367.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V367.Call.CallId (Evergreen.V367.NonemptyDict.NonemptyDict ( Evergreen.V367.Id.Id Evergreen.V367.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V367.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V367.Go.PublicGoMatchData Evergreen.V367.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V367.Route.Route
    , windowSize : Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V367.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V367.Audio.LoadError Evergreen.V367.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V367.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V367.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V367.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData) (List Evergreen.V367.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V367.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V367.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.ChannelName.ChannelName Evergreen.V367.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.ChannelName.ChannelName Evergreen.V367.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.UserSession.ToBeFilledInByBackend (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V367.GuildName.GuildName (Evergreen.V367.UserSession.ToBeFilledInByBackend (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V367.Id.Viewing_DiscordDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V367.UserSession.SetViewing
    | Local_SetName Evergreen.V367.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V367.Id.GuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Message.Message Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V367.Id.GuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId) (Evergreen.V367.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId) (Evergreen.V367.Message.Message Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V367.Id.DiscordGuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Message.Message Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V367.Id.DiscordGuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId) (Evergreen.V367.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId) (Evergreen.V367.Message.Message Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V367.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V367.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V367.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.QuestionId Evergreen.V367.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V367.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V367.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V367.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V367.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V367.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V367.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V367.NonemptySet.NonemptySet (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V367.Call.LocalChange
    | Local_Game Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Game.LocalChange
    | Local_Drawing Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Drawing.AnchorType Evergreen.V367.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.User.FrontendUser Effect.Time.Posix Evergreen.V367.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V367.RichText.RichText (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))) Evergreen.V367.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId) Evergreen.V367.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V367.Id.DiscordGuildOrDmId Evergreen.V367.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V367.RichText.RichText (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))) Evergreen.V367.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId) Evergreen.V367.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.ChannelName.ChannelName Evergreen.V367.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.ChannelName.ChannelName Evergreen.V367.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.User.FrontendUser
    | Server_MemberLeft (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V367.LocalState.JoinGuildError
            { guildId : Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId
            , guild : Evergreen.V367.LocalState.FrontendGuild
            , owner : Evergreen.V367.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V367.RichText.RichText (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))) (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V367.RichText.RichText (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V367.Id.Viewing_DiscordDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V367.RichText.RichText (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Maybe Evergreen.V367.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Maybe Evergreen.V367.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V367.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V367.SessionIdHash.SessionIdHash Evergreen.V367.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V367.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V367.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V367.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V367.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V367.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Evergreen.V367.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Bool Evergreen.V367.ChannelName.ChannelName (Evergreen.V367.Discord.OptionalData (Maybe String)) (List Evergreen.V367.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId)
        (Evergreen.V367.NonemptyDict.NonemptyDict
            (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) Evergreen.V367.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Evergreen.V367.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Maybe (Evergreen.V367.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V367.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V367.Log.Log
    | Server_BackupGenerated Evergreen.V367.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V367.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V367.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V367.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V367.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (Evergreen.V367.Discord.OptionalData (Maybe String)) (Evergreen.V367.Discord.OptionalData (Maybe String)) (List Evergreen.V367.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.RoleId) Evergreen.V367.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId)
        (Evergreen.V367.MembersAndOwner.MembersAndOwner
            (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V367.Discord.Id Evergreen.V367.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Evergreen.V367.PersonName.PersonName Evergreen.V367.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId) Evergreen.V367.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId) Evergreen.V367.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V367.Call.ServerChange
    | Server_Game (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Game.LocalChange
    | Server_Drawing (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Drawing.AnchorType Evergreen.V367.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Evergreen.V367.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V367.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V367.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V367.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V367.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V367.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V367.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V367.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V367.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V367.Id.AnyGuildOrDmId Evergreen.V367.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V367.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels) (Maybe Evergreen.V367.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V367.SheepGame.Input (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels) (Maybe Evergreen.V367.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V367.Id.GuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId) (Evergreen.V367.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V367.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V367.UserColor.Selection
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V367.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V367.Local.Local LocalMsg Evergreen.V367.LocalState.LocalState
    , admin : Evergreen.V367.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId, Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V367.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V367.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V367.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V367.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V367.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.ThreadRoute ) (Evergreen.V367.NonemptyDict.NonemptyDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V367.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V367.Scroll.ScrollPosition
    , textEditor : Evergreen.V367.TextEditor.Model
    , profilePictureEditor : Evergreen.V367.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId, Evergreen.V367.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V367.Emoji.Model
    , voiceChat : Evergreen.V367.Call.Model
    , games : SeqDict.SeqDict Evergreen.V367.Id.GuildOrDmId Evergreen.V367.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V367.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V367.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V367.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V367.Range.Range
                , direction : Evergreen.V367.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V367.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V367.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V367.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V367.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V367.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V367.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V367.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V367.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V367.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V367.MyUi.LastCopy
    , drag : Evergreen.V367.Touch.Drag
    , dragPrevious : Evergreen.V367.Touch.Drag
    , aiChatModel : Evergreen.V367.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V367.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V367.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V367.Audio.LoadError Evergreen.V367.Audio.Source
    , startupData : Evergreen.V367.Ports.StartupData
    , appBadgeCount : Maybe Int
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V367.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V367.Id.Id Evergreen.V367.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V367.Id.Id Evergreen.V367.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V367.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V367.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V367.FileStatus.FileHash
    , metadata : Maybe Evergreen.V367.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId, Evergreen.V367.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId, Evergreen.V367.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V367.DmChannelId.DmChannelId, Evergreen.V367.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId, Evergreen.V367.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId, Evergreen.V367.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId, Evergreen.V367.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V367.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V367.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias DownloadBackupState =
    { contents : Evergreen.V367.LocalState.BackupContents
    , remainingBytes : Bytes.Bytes
    , totalBytes : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V367.NonemptyDict.NonemptyDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V367.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V367.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V367.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V367.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) Evergreen.V367.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V367.DmChannelId.DmChannelId Evergreen.V367.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) Evergreen.V367.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V367.OneToOne.OneToOne (Evergreen.V367.Slack.Id Evergreen.V367.Slack.ChannelId) Evergreen.V367.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V367.OneToOne.OneToOne String (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    , slackUsers : Evergreen.V367.OneToOne.OneToOne (Evergreen.V367.Slack.Id Evergreen.V367.Slack.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)
    , slackServers : Evergreen.V367.OneToOne.OneToOne (Evergreen.V367.Slack.Id Evergreen.V367.Slack.TeamId) (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    , slackToken : Maybe Evergreen.V367.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V367.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V367.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V367.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V367.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Evergreen.V367.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId, Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V367.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V367.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V367.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V367.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.LocalState.LoadingDiscordChannel Evergreen.V367.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , downloadBackupState : Maybe DownloadBackupState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V367.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId) Evergreen.V367.Sticker.StickerData
    , discordStickers : Evergreen.V367.OneToOne.OneToOne (Evergreen.V367.Discord.Id Evergreen.V367.Discord.StickerId) (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId) Evergreen.V367.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V367.OneToOne.OneToOne Evergreen.V367.RichText.DiscordCustomEmojiIdAndName (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V367.Postmark.ApiKey
    , serverSecret : Evergreen.V367.SecretId.SecretId Evergreen.V367.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V367.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V367.OneToOne.OneToOne (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.GamePublicId) ( Evergreen.V367.DmChannelId.GuildOrFullDmId, Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V367.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V367.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V367.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.Id.ThreadRoute (Maybe Evergreen.V367.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V367.DmChannelId.DmChannelId Evergreen.V367.Id.ThreadRoute (Maybe Evergreen.V367.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V367.Id.Id Evergreen.V367.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V367.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V367.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V367.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V367.Untrusted.Untrusted Evergreen.V367.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V367.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V367.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V367.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V367.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V367.PersonName.PersonName Evergreen.V367.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V367.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V367.Slack.OAuthCode Evergreen.V367.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V367.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V367.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V367.Id.Id Evergreen.V367.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V367.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V367.EmailAddress.EmailAddress (Result Evergreen.V367.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V367.EmailAddress.EmailAddress (Result Evergreen.V367.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V367.EmailAddress.EmailAddress (Result Evergreen.V367.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V367.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMaybeMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Result Evergreen.V367.Discord.HttpError Evergreen.V367.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V367.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Result Evergreen.V367.Discord.HttpError Evergreen.V367.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) (Result Evergreen.V367.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) (Result Evergreen.V367.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) (Result Evergreen.V367.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) (Result Evergreen.V367.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji (Result Evergreen.V367.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji (Result Evergreen.V367.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji (Result Evergreen.V367.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji (Result Evergreen.V367.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V367.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V367.Discord.HttpError (List ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId, Maybe Evergreen.V367.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Effect.Time.Posix Evergreen.V367.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V367.Slack.CurrentUser
            , team : Evergreen.V367.Slack.Team
            , users : List Evergreen.V367.Slack.User
            , channels : List ( Evergreen.V367.Slack.Channel, List Evergreen.V367.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Result Effect.Http.Error Evergreen.V367.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Discord.UserAuth (Result Evergreen.V367.Discord.HttpError Evergreen.V367.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Result Evergreen.V367.Discord.HttpError Evergreen.V367.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
        (Result
            Evergreen.V367.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId
                , members : List (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
                }
            , List
                ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId
                , { guild : Evergreen.V367.Discord.GatewayGuild
                  , channels : List Evergreen.V367.Discord.Channel
                  , icon : Maybe Evergreen.V367.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V367.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V367.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.AttachmentId, Evergreen.V367.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V367.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.AttachmentId, Evergreen.V367.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V367.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V367.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V367.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V367.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | DownloadBackupChunkStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) (Result Evergreen.V367.Discord.HttpError Evergreen.V367.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Result Evergreen.V367.Discord.HttpError (List Evergreen.V367.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V367.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V367.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V367.DmChannelId.DmChannelId Evergreen.V367.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V367.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V367.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V367.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
        (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V367.Discord.HttpError
            { guild : Evergreen.V367.Discord.GatewayGuild
            , channels : List Evergreen.V367.Discord.Channel
            , icon : Maybe Evergreen.V367.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Result Evergreen.V367.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V367.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (List ( Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId, Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId, Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (List ( Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V367.Discord.HttpError (List Evergreen.V367.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V367.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V367.SecretId.SecretId Evergreen.V367.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V367.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Result Evergreen.V367.Discord.HttpError ( Evergreen.V367.Discord.Guild, List Evergreen.V367.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V367.FileStatus.FileHash Int (Maybe (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Call.CallId
