module Evergreen.V365.Types exposing (..)

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
import Evergreen.V365.AiChat
import Evergreen.V365.Audio
import Evergreen.V365.Call
import Evergreen.V365.ChannelDescription
import Evergreen.V365.ChannelName
import Evergreen.V365.Coord
import Evergreen.V365.CssPixels
import Evergreen.V365.CustomEmoji
import Evergreen.V365.Discord
import Evergreen.V365.DiscordAttachmentId
import Evergreen.V365.DiscordUserData
import Evergreen.V365.DmChannel
import Evergreen.V365.DmChannelId
import Evergreen.V365.Drawing
import Evergreen.V365.Editable
import Evergreen.V365.EmailAddress
import Evergreen.V365.Embed
import Evergreen.V365.Emoji
import Evergreen.V365.FileStatus
import Evergreen.V365.Game
import Evergreen.V365.Go
import Evergreen.V365.GuildName
import Evergreen.V365.Id
import Evergreen.V365.IdArray
import Evergreen.V365.ImageEditor
import Evergreen.V365.ImageViewer
import Evergreen.V365.LinkedAndOtherDiscordUsers
import Evergreen.V365.Local
import Evergreen.V365.LocalState
import Evergreen.V365.Log
import Evergreen.V365.LoginForm
import Evergreen.V365.MembersAndOwner
import Evergreen.V365.Message
import Evergreen.V365.MessageInput
import Evergreen.V365.MessageView
import Evergreen.V365.MuteSettings
import Evergreen.V365.MyUi
import Evergreen.V365.NonemptyDict
import Evergreen.V365.NonemptySet
import Evergreen.V365.OneOrGreater
import Evergreen.V365.OneToOne
import Evergreen.V365.Pages.Admin
import Evergreen.V365.Pagination
import Evergreen.V365.PersonName
import Evergreen.V365.Ports
import Evergreen.V365.Postmark
import Evergreen.V365.Range
import Evergreen.V365.RecoveryLogin
import Evergreen.V365.RichText
import Evergreen.V365.Route
import Evergreen.V365.Scroll
import Evergreen.V365.SecretId
import Evergreen.V365.SessionIdHash
import Evergreen.V365.SheepGame
import Evergreen.V365.Slack
import Evergreen.V365.Sticker
import Evergreen.V365.TextEditor
import Evergreen.V365.ToBackendLog
import Evergreen.V365.Touch
import Evergreen.V365.TwoFactorAuthentication
import Evergreen.V365.Ui.Anim
import Evergreen.V365.Untrusted
import Evergreen.V365.User
import Evergreen.V365.UserAgent
import Evergreen.V365.UserColor
import Evergreen.V365.UserSession
import Evergreen.V365.WordSpellingGame
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
    | LoginFormMsg Evergreen.V365.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V365.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V365.Pages.Admin.Msg
    | PressedLogOut Evergreen.V365.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V365.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V365.Route.Route
    | SelectedFilesToAttach ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V365.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V365.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V365.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V365.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V365.NonemptyDict.NonemptyDict Int Evergreen.V365.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V365.NonemptyDict.NonemptyDict Int Evergreen.V365.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRoute Evergreen.V365.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V365.NonemptySet.NonemptySet (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V365.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V365.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V365.AiChat.Msg
    | GameMsg Evergreen.V365.Game.Msg
    | GoSpectatorMsg Evergreen.V365.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V365.Editable.Msg Evergreen.V365.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V365.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute )
        { fileId : Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute )
        { fileId : Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage Evergreen.V365.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V365.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V365.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V365.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V365.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V365.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V365.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V365.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId
        , otherUserId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V365.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRoute Evergreen.V365.MessageInput.Msg
    | MessageInputMsg Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRoute Evergreen.V365.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V365.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V365.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V365.Range.Range, Evergreen.V365.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V365.Range.Range, Evergreen.V365.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V365.Call.FromJs)
    | VoiceChatMsg Evergreen.V365.Call.Msg
    | PressedChannelHeaderTab Evergreen.V365.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V365.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V365.Audio.LoadError Evergreen.V365.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V365.Id.AnyGuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V365.Id.AnyGuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId) Evergreen.V365.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V365.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V365.UserSession.UserSession
    , currentlyViewing : Evergreen.V365.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) Evergreen.V365.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.LocalState.DiscordFrontendGuild
    , user : Evergreen.V365.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.User.FrontendUser
    , discordUsers : Evergreen.V365.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V365.SessionIdHash.SessionIdHash Evergreen.V365.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V365.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId) Evergreen.V365.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId) Evergreen.V365.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V365.Call.CallId (Evergreen.V365.NonemptyDict.NonemptyDict ( Evergreen.V365.Id.Id Evergreen.V365.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V365.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V365.Go.PublicGoMatchData Evergreen.V365.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V365.Route.Route
    , windowSize : Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V365.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V365.Audio.LoadError Evergreen.V365.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V365.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V365.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V365.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData) (List Evergreen.V365.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V365.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V365.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.ChannelName.ChannelName Evergreen.V365.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.ChannelName.ChannelName Evergreen.V365.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V365.GuildName.GuildName (Evergreen.V365.UserSession.ToBeFilledInByBackend (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V365.Id.Viewing_DiscordDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V365.UserSession.SetViewing
    | Local_SetName Evergreen.V365.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V365.Id.GuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V365.Id.GuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId) (Evergreen.V365.Message.Message Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V365.Id.DiscordGuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V365.Id.DiscordGuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId) (Evergreen.V365.Message.Message Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V365.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V365.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V365.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.QuestionId Evergreen.V365.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V365.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V365.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V365.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V365.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V365.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V365.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V365.NonemptySet.NonemptySet (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V365.Call.LocalChange
    | Local_Game Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Game.LocalChange
    | Local_Drawing Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Drawing.AnchorType Evergreen.V365.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.User.FrontendUser Effect.Time.Posix Evergreen.V365.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V365.RichText.RichText (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))) Evergreen.V365.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId) Evergreen.V365.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V365.Id.DiscordGuildOrDmId Evergreen.V365.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V365.RichText.RichText (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))) Evergreen.V365.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId) Evergreen.V365.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.ChannelName.ChannelName Evergreen.V365.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.ChannelName.ChannelName Evergreen.V365.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.User.FrontendUser
    | Server_MemberLeft (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V365.LocalState.JoinGuildError
            { guildId : Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId
            , guild : Evergreen.V365.LocalState.FrontendGuild
            , owner : Evergreen.V365.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V365.RichText.RichText (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))) (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V365.RichText.RichText (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V365.Id.Viewing_DiscordDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V365.RichText.RichText (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Maybe Evergreen.V365.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Maybe Evergreen.V365.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V365.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V365.SessionIdHash.SessionIdHash Evergreen.V365.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V365.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V365.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V365.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V365.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V365.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Bool Evergreen.V365.ChannelName.ChannelName (Evergreen.V365.Discord.OptionalData (Maybe String)) (List Evergreen.V365.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
        (Evergreen.V365.NonemptyDict.NonemptyDict
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) Evergreen.V365.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Maybe (Evergreen.V365.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V365.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V365.Log.Log
    | Server_BackupGenerated Evergreen.V365.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V365.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V365.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V365.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V365.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (Evergreen.V365.Discord.OptionalData (Maybe String)) (Evergreen.V365.Discord.OptionalData (Maybe String)) (List Evergreen.V365.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId) Evergreen.V365.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
        (Evergreen.V365.MembersAndOwner.MembersAndOwner
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.PersonName.PersonName Evergreen.V365.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId) Evergreen.V365.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId) Evergreen.V365.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V365.Call.ServerChange
    | Server_Game (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Game.LocalChange
    | Server_Drawing (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Drawing.AnchorType Evergreen.V365.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V365.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V365.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V365.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V365.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V365.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V365.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V365.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V365.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V365.Id.AnyGuildOrDmId Evergreen.V365.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V365.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels) (Maybe Evergreen.V365.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V365.SheepGame.Input (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels) (Maybe Evergreen.V365.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V365.Id.GuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId) (Evergreen.V365.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V365.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V365.UserColor.Selection
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V365.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V365.Local.Local LocalMsg Evergreen.V365.LocalState.LocalState
    , admin : Evergreen.V365.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId, Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V365.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V365.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V365.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V365.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V365.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.ThreadRoute ) (Evergreen.V365.NonemptyDict.NonemptyDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V365.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V365.Scroll.ScrollPosition
    , textEditor : Evergreen.V365.TextEditor.Model
    , profilePictureEditor : Evergreen.V365.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId, Evergreen.V365.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V365.Emoji.Model
    , voiceChat : Evergreen.V365.Call.Model
    , games : SeqDict.SeqDict Evergreen.V365.Id.GuildOrDmId Evergreen.V365.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V365.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V365.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V365.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V365.Range.Range
                , direction : Evergreen.V365.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V365.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V365.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V365.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V365.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V365.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V365.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V365.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V365.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V365.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V365.MyUi.LastCopy
    , drag : Evergreen.V365.Touch.Drag
    , dragPrevious : Evergreen.V365.Touch.Drag
    , aiChatModel : Evergreen.V365.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V365.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V365.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V365.Audio.LoadError Evergreen.V365.Audio.Source
    , startupData : Evergreen.V365.Ports.StartupData
    , appBadgeCount : Maybe Int
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V365.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V365.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V365.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V365.FileStatus.FileHash
    , metadata : Maybe Evergreen.V365.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId, Evergreen.V365.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId, Evergreen.V365.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V365.DmChannelId.DmChannelId, Evergreen.V365.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId, Evergreen.V365.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId, Evergreen.V365.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId, Evergreen.V365.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V365.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V365.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V365.NonemptyDict.NonemptyDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V365.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V365.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V365.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V365.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V365.DmChannelId.DmChannelId Evergreen.V365.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) Evergreen.V365.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.Slack.Id Evergreen.V365.Slack.ChannelId) Evergreen.V365.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V365.OneToOne.OneToOne String (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    , slackUsers : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.Slack.Id Evergreen.V365.Slack.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    , slackServers : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.Slack.Id Evergreen.V365.Slack.TeamId) (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    , slackToken : Maybe Evergreen.V365.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V365.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V365.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V365.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V365.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId, Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V365.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V365.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V365.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V365.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.LocalState.LoadingDiscordChannel Evergreen.V365.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V365.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId) Evergreen.V365.Sticker.StickerData
    , discordStickers : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.Discord.Id Evergreen.V365.Discord.StickerId) (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId) Evergreen.V365.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V365.OneToOne.OneToOne Evergreen.V365.RichText.DiscordCustomEmojiIdAndName (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V365.Postmark.ApiKey
    , serverSecret : Evergreen.V365.SecretId.SecretId Evergreen.V365.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V365.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.GamePublicId) ( Evergreen.V365.DmChannelId.GuildOrFullDmId, Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V365.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V365.WordSpellingGame.WordList
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V365.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.Id.ThreadRoute (Maybe Evergreen.V365.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V365.DmChannelId.DmChannelId Evergreen.V365.Id.ThreadRoute (Maybe Evergreen.V365.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V365.Id.Id Evergreen.V365.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V365.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V365.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V365.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V365.Untrusted.Untrusted Evergreen.V365.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V365.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V365.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V365.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V365.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V365.PersonName.PersonName Evergreen.V365.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V365.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V365.Slack.OAuthCode Evergreen.V365.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V365.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V365.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V365.Id.Id Evergreen.V365.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V365.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V365.EmailAddress.EmailAddress (Result Evergreen.V365.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V365.EmailAddress.EmailAddress (Result Evergreen.V365.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V365.EmailAddress.EmailAddress (Result Evergreen.V365.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V365.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMaybeMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Result Evergreen.V365.Discord.HttpError Evergreen.V365.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V365.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Result Evergreen.V365.Discord.HttpError Evergreen.V365.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) (Result Evergreen.V365.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) (Result Evergreen.V365.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) (Result Evergreen.V365.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) (Result Evergreen.V365.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji (Result Evergreen.V365.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji (Result Evergreen.V365.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji (Result Evergreen.V365.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji (Result Evergreen.V365.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V365.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V365.Discord.HttpError (List ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId, Maybe Evergreen.V365.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Effect.Time.Posix Evergreen.V365.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V365.Slack.CurrentUser
            , team : Evergreen.V365.Slack.Team
            , users : List Evergreen.V365.Slack.User
            , channels : List ( Evergreen.V365.Slack.Channel, List Evergreen.V365.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Result Effect.Http.Error Evergreen.V365.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Discord.UserAuth (Result Evergreen.V365.Discord.HttpError Evergreen.V365.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Result Evergreen.V365.Discord.HttpError Evergreen.V365.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
        (Result
            Evergreen.V365.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId
                , members : List (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
                }
            , List
                ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId
                , { guild : Evergreen.V365.Discord.GatewayGuild
                  , channels : List Evergreen.V365.Discord.Channel
                  , icon : Maybe Evergreen.V365.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Maybe String) Evergreen.V365.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V365.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.AttachmentId, Evergreen.V365.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V365.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.AttachmentId, Evergreen.V365.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V365.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V365.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V365.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V365.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (Result Evergreen.V365.Discord.HttpError Evergreen.V365.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Result Evergreen.V365.Discord.HttpError (List Evergreen.V365.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V365.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V365.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V365.DmChannelId.DmChannelId Evergreen.V365.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V365.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V365.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V365.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
        (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V365.Discord.HttpError
            { guild : Evergreen.V365.Discord.GatewayGuild
            , channels : List Evergreen.V365.Discord.Channel
            , icon : Maybe Evergreen.V365.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Result Evergreen.V365.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V365.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (List ( Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId, Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId, Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (List ( Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V365.Discord.HttpError (List Evergreen.V365.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V365.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V365.SecretId.SecretId Evergreen.V365.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V365.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Result Evergreen.V365.Discord.HttpError ( Evergreen.V365.Discord.Guild, List Evergreen.V365.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V365.FileStatus.FileHash Int (Maybe (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Call.CallId
