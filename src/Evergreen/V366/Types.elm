module Evergreen.V366.Types exposing (..)

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
import Evergreen.V366.AiChat
import Evergreen.V366.Audio
import Evergreen.V366.Call
import Evergreen.V366.ChannelDescription
import Evergreen.V366.ChannelName
import Evergreen.V366.Coord
import Evergreen.V366.CssPixels
import Evergreen.V366.CustomEmoji
import Evergreen.V366.Discord
import Evergreen.V366.DiscordAttachmentId
import Evergreen.V366.DiscordUserData
import Evergreen.V366.DmChannel
import Evergreen.V366.DmChannelId
import Evergreen.V366.Drawing
import Evergreen.V366.Editable
import Evergreen.V366.EmailAddress
import Evergreen.V366.Embed
import Evergreen.V366.Emoji
import Evergreen.V366.FileStatus
import Evergreen.V366.Game
import Evergreen.V366.Go
import Evergreen.V366.GuildName
import Evergreen.V366.Id
import Evergreen.V366.IdArray
import Evergreen.V366.ImageEditor
import Evergreen.V366.ImageViewer
import Evergreen.V366.LinkedAndOtherDiscordUsers
import Evergreen.V366.Local
import Evergreen.V366.LocalState
import Evergreen.V366.Log
import Evergreen.V366.LoginForm
import Evergreen.V366.MembersAndOwner
import Evergreen.V366.Message
import Evergreen.V366.MessageInput
import Evergreen.V366.MessageView
import Evergreen.V366.MuteSettings
import Evergreen.V366.MyUi
import Evergreen.V366.NonemptyDict
import Evergreen.V366.NonemptySet
import Evergreen.V366.OneOrGreater
import Evergreen.V366.OneToOne
import Evergreen.V366.Pages.Admin
import Evergreen.V366.Pagination
import Evergreen.V366.PersonName
import Evergreen.V366.Ports
import Evergreen.V366.Postmark
import Evergreen.V366.Range
import Evergreen.V366.RecoveryLogin
import Evergreen.V366.RichText
import Evergreen.V366.Route
import Evergreen.V366.Scroll
import Evergreen.V366.SecretId
import Evergreen.V366.SessionIdHash
import Evergreen.V366.SheepGame
import Evergreen.V366.Slack
import Evergreen.V366.Sticker
import Evergreen.V366.TextEditor
import Evergreen.V366.ToBackendLog
import Evergreen.V366.Touch
import Evergreen.V366.TwoFactorAuthentication
import Evergreen.V366.Ui.Anim
import Evergreen.V366.Untrusted
import Evergreen.V366.User
import Evergreen.V366.UserAgent
import Evergreen.V366.UserColor
import Evergreen.V366.UserSession
import Evergreen.V366.WordSpellingGame
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
    | LoginFormMsg Evergreen.V366.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V366.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V366.Pages.Admin.Msg
    | PressedLogOut Evergreen.V366.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V366.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V366.Route.Route
    | SelectedFilesToAttach ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | PressedLeaveGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V366.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V366.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V366.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V366.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V366.NonemptyDict.NonemptyDict Int Evergreen.V366.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V366.NonemptyDict.NonemptyDict Int Evergreen.V366.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRoute Evergreen.V366.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V366.NonemptySet.NonemptySet (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer Evergreen.V366.UserSession.UserOptionSection
    | TwoFactorMsg Evergreen.V366.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V366.AiChat.Msg
    | GameMsg Evergreen.V366.Game.Msg
    | GoSpectatorMsg Evergreen.V366.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V366.Editable.Msg Evergreen.V366.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V366.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute )
        { fileId : Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute )
        { fileId : Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage Evergreen.V366.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V366.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V366.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V366.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V366.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V366.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V366.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V366.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId
        , otherUserId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSelectNewColor
    | SelectedUserColor Evergreen.V366.UserColor.Selection
    | PressedSubmitUserColor
    | PressedResetUserColor
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRoute Evergreen.V366.MessageInput.Msg
    | MessageInputMsg Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRoute Evergreen.V366.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V366.Emoji.CachedEmojiData)
    | GotPositionForEmojiSelector_EditMessage (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | GotPositionForEmojiSelector_SheepGameInput Evergreen.V366.SheepGame.Input (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V366.Range.Range, Evergreen.V366.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V366.Range.Range, Evergreen.V366.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V366.Call.FromJs)
    | VoiceChatMsg Evergreen.V366.Call.Msg
    | PressedChannelHeaderTab Evergreen.V366.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V366.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V366.Audio.LoadError Evergreen.V366.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V366.Id.AnyGuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V366.Id.AnyGuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId) Evergreen.V366.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V366.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V366.UserSession.UserSession
    , currentlyViewing : Evergreen.V366.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) Evergreen.V366.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.LocalState.DiscordFrontendGuild
    , user : Evergreen.V366.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.User.FrontendUser
    , discordUsers : Evergreen.V366.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V366.SessionIdHash.SessionIdHash Evergreen.V366.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V366.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId) Evergreen.V366.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId) Evergreen.V366.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V366.Call.CallId (Evergreen.V366.NonemptyDict.NonemptyDict ( Evergreen.V366.Id.Id Evergreen.V366.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V366.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V366.Go.PublicGoMatchData Evergreen.V366.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V366.Route.Route
    , windowSize : Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V366.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V366.Audio.LoadError Evergreen.V366.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V366.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V366.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V366.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData) (List Evergreen.V366.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V366.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V366.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.ChannelName.ChannelName Evergreen.V366.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.ChannelName.ChannelName Evergreen.V366.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | Local_LeaveGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V366.GuildName.GuildName (Evergreen.V366.UserSession.ToBeFilledInByBackend (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V366.Id.Viewing_DiscordDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V366.UserSession.SetViewing
    | Local_SetName Evergreen.V366.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V366.Id.GuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V366.Id.GuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId) (Evergreen.V366.Message.Message Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V366.Id.DiscordGuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V366.Id.DiscordGuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId) (Evergreen.V366.Message.Message Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V366.UserSession.NotificationMode
    | Local_ExpandUserOptionSection Evergreen.V366.UserSession.UserOptionSection
    | Local_CollapseUserOptionSection Evergreen.V366.UserSession.UserOptionSection
    | Local_SetSheepGameQuestions (Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.QuestionId Evergreen.V366.UserSession.SheepGameQuestion)
    | Local_SetEmailNotifications Evergreen.V366.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V366.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V366.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V366.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V366.Emoji.SkinTone)
    | Local_SetUserColor Evergreen.V366.UserColor.UserColor
    | Local_AddCustomEmojisToUser (Evergreen.V366.NonemptySet.NonemptySet (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V366.Call.LocalChange
    | Local_Game Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Game.LocalChange
    | Local_Drawing Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Drawing.AnchorType Evergreen.V366.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.User.FrontendUser Effect.Time.Posix Evergreen.V366.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V366.RichText.RichText (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))) Evergreen.V366.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId) Evergreen.V366.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V366.Id.DiscordGuildOrDmId Evergreen.V366.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V366.RichText.RichText (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))) Evergreen.V366.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId) Evergreen.V366.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.ChannelName.ChannelName Evergreen.V366.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.ChannelName.ChannelName Evergreen.V366.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.User.FrontendUser
    | Server_MemberLeft (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V366.LocalState.JoinGuildError
            { guildId : Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId
            , guild : Evergreen.V366.LocalState.FrontendGuild
            , owner : Evergreen.V366.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V366.RichText.RichText (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))) (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V366.RichText.RichText (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V366.Id.Viewing_DiscordDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V366.RichText.RichText (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.PersonName.PersonName
    | Server_SetUserColor (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.UserColor.UserColor
    | Server_SetUserIcon (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Maybe Evergreen.V366.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Maybe Evergreen.V366.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V366.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V366.SessionIdHash.SessionIdHash Evergreen.V366.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V366.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V366.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V366.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V366.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Effect.Time.Posix
    | Server_TextEditor Evergreen.V366.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Bool Evergreen.V366.ChannelName.ChannelName (Evergreen.V366.Discord.OptionalData (Maybe String)) (List Evergreen.V366.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
        (Evergreen.V366.NonemptyDict.NonemptyDict
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordDmChannelRecipientRemoved (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | Server_DiscordNeedsAuthAgain (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) Evergreen.V366.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.UserSession.DiscordFrontendUser
            , markEverythingAsViewed : Bool
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Maybe (Evergreen.V366.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V366.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V366.Log.Log
    | Server_BackupGenerated Evergreen.V366.LocalState.LastBackup
    | Server_GotGuildMessageEmbed (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V366.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V366.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V366.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V366.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (Evergreen.V366.Discord.OptionalData (Maybe String)) (Evergreen.V366.Discord.OptionalData (Maybe String)) (List Evergreen.V366.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId) Evergreen.V366.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
        (Evergreen.V366.MembersAndOwner.MembersAndOwner
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.PersonName.PersonName Evergreen.V366.UserColor.UserColor
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId) Evergreen.V366.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId) Evergreen.V366.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V366.Call.ServerChange
    | Server_Game (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Game.LocalChange
    | Server_Drawing (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Drawing.AnchorType Evergreen.V366.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.MuteSettings.IsMuted
    | Server_DiscordAvatarsLoaded (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.UserSession.DiscordFrontendUser


type LocalMsg
    = LocalChange (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V366.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V366.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V366.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V366.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V366.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V366.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V366.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V366.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V366.Id.AnyGuildOrDmId Evergreen.V366.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V366.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels) (Maybe Evergreen.V366.Range.Range)
    | EmojiSelectorForSheepGameInput Evergreen.V366.SheepGame.Input (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels) (Maybe Evergreen.V366.Range.Range)
    | EmojiSelectorForSheepGameReaction Evergreen.V366.Id.GuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.SheepGame.ReactionTarget


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId) (Evergreen.V366.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V366.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    , color : Maybe Evergreen.V366.UserColor.Selection
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V366.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V366.Local.Local LocalMsg Evergreen.V366.LocalState.LocalState
    , admin : Evergreen.V366.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId, Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V366.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V366.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V366.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V366.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V366.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.ThreadRoute ) (Evergreen.V366.NonemptyDict.NonemptyDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V366.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V366.Scroll.ScrollPosition
    , textEditor : Evergreen.V366.TextEditor.Model
    , profilePictureEditor : Evergreen.V366.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId, Evergreen.V366.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V366.Emoji.Model
    , voiceChat : Evergreen.V366.Call.Model
    , games : SeqDict.SeqDict Evergreen.V366.Id.GuildOrDmId Evergreen.V366.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V366.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V366.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V366.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V366.Range.Range
                , direction : Evergreen.V366.Range.SelectionDirection
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
    | AdminToFrontend Evergreen.V366.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V366.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V366.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V366.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V366.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V366.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V366.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V366.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V366.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V366.MyUi.LastCopy
    , drag : Evergreen.V366.Touch.Drag
    , dragPrevious : Evergreen.V366.Touch.Drag
    , aiChatModel : Evergreen.V366.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V366.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V366.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V366.Audio.LoadError Evergreen.V366.Audio.Source
    , startupData : Evergreen.V366.Ports.StartupData
    , appBadgeCount : Maybe Int
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V366.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V366.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V366.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V366.FileStatus.FileHash
    , metadata : Maybe Evergreen.V366.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId, Evergreen.V366.LocalState.BackendGuild )
    , remainingGuildChannels : List ( Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId, Evergreen.V366.LocalState.BackendChannel )
    , encodedGuildCount : Int
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V366.DmChannelId.DmChannelId, Evergreen.V366.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId, Evergreen.V366.LocalState.DiscordBackendGuild )
    , remainingDiscordGuildChannels : List ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId, Evergreen.V366.LocalState.DiscordBackendChannel )
    , encodedDiscordGuildCount : Int
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId, Evergreen.V366.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V366.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias LastBackupData =
    { backup : Evergreen.V366.LocalState.LastBackup
    , bytes : Bytes.Bytes
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias PendingGatewayReconnect =
    { delay : Duration.Duration
    , gatewayUrl : String
    }


type alias BackendModel =
    { users : Evergreen.V366.NonemptyDict.NonemptyDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V366.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V366.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V366.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V366.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V366.DmChannelId.DmChannelId Evergreen.V366.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) Evergreen.V366.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.Slack.Id Evergreen.V366.Slack.ChannelId) Evergreen.V366.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V366.OneToOne.OneToOne String (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    , slackUsers : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.Slack.Id Evergreen.V366.Slack.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    , slackServers : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.Slack.Id Evergreen.V366.Slack.TeamId) (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    , slackToken : Maybe Evergreen.V366.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V366.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V366.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V366.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V366.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId, Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V366.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V366.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V366.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V366.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.LocalState.LoadingDiscordChannel Evergreen.V366.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , lastBackup : Maybe LastBackupData
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V366.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId) Evergreen.V366.Sticker.StickerData
    , discordStickers : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.Discord.Id Evergreen.V366.Discord.StickerId) (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId) Evergreen.V366.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V366.OneToOne.OneToOne Evergreen.V366.RichText.DiscordCustomEmojiIdAndName (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V366.Postmark.ApiKey
    , serverSecret : Evergreen.V366.SecretId.SecretId Evergreen.V366.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V366.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.GamePublicId) ( Evergreen.V366.DmChannelId.GuildOrFullDmId, Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V366.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V366.WordSpellingGame.WordList
    , pendingGatewayReconnects : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) PendingGatewayReconnect
    }


type alias FrontendMsg =
    Evergreen.V366.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.Id.ThreadRoute (Maybe Evergreen.V366.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V366.DmChannelId.DmChannelId Evergreen.V366.Id.ThreadRoute (Maybe Evergreen.V366.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V366.Id.Id Evergreen.V366.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V366.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V366.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V366.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V366.Untrusted.Untrusted Evergreen.V366.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V366.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V366.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V366.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V366.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V366.PersonName.PersonName Evergreen.V366.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V366.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V366.Slack.OAuthCode Evergreen.V366.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V366.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V366.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V366.Id.Id Evergreen.V366.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V366.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V366.EmailAddress.EmailAddress (Result Evergreen.V366.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V366.EmailAddress.EmailAddress (Result Evergreen.V366.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V366.EmailAddress.EmailAddress (Result Evergreen.V366.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V366.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMaybeMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Result Evergreen.V366.Discord.HttpError Evergreen.V366.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V366.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Result Evergreen.V366.Discord.HttpError Evergreen.V366.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) (Result Evergreen.V366.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) (Result Evergreen.V366.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) (Result Evergreen.V366.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) (Result Evergreen.V366.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji (Result Evergreen.V366.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji (Result Evergreen.V366.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji (Result Evergreen.V366.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji (Result Evergreen.V366.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V366.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V366.Discord.HttpError (List ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId, Maybe Evergreen.V366.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Effect.Time.Posix Evergreen.V366.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V366.Slack.CurrentUser
            , team : Evergreen.V366.Slack.Team
            , users : List Evergreen.V366.Slack.User
            , channels : List ( Evergreen.V366.Slack.Channel, List Evergreen.V366.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Result Effect.Http.Error Evergreen.V366.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Discord.UserAuth (Result Evergreen.V366.Discord.HttpError Evergreen.V366.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Result Evergreen.V366.Discord.HttpError Evergreen.V366.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
        (Result
            Evergreen.V366.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId
                , members : List (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
                }
            , List
                ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId
                , { guild : Evergreen.V366.Discord.GatewayGuild
                  , channels : List Evergreen.V366.Discord.Channel
                  , icon : Maybe Evergreen.V366.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Maybe PendingGatewayReconnect) Evergreen.V366.LocalState.WebsocketClosedEvent
    | GatewayReconnectTick
    | WebsocketSentDataForUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V366.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.AttachmentId, Evergreen.V366.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V366.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.AttachmentId, Evergreen.V366.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V366.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V366.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V366.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V366.FileStatus.UploadResponse )))
    | ExportBackendStep Effect.Time.Posix
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (Result Evergreen.V366.Discord.HttpError Evergreen.V366.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Result Evergreen.V366.Discord.HttpError (List Evergreen.V366.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V366.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V366.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V366.DmChannelId.DmChannelId Evergreen.V366.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V366.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V366.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V366.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
        (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V366.Discord.HttpError
            { guild : Evergreen.V366.Discord.GatewayGuild
            , channels : List Evergreen.V366.Discord.Channel
            , icon : Maybe Evergreen.V366.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Result Evergreen.V366.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V366.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (List ( Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId, Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId, Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (List ( Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V366.Discord.HttpError (List Evergreen.V366.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V366.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V366.SecretId.SecretId Evergreen.V366.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V366.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Result Evergreen.V366.Discord.HttpError ( Evergreen.V366.Discord.Guild, List Evergreen.V366.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V366.FileStatus.FileHash Int (Maybe (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Call.CallId
