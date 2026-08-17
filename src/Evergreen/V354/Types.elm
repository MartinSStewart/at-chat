module Evergreen.V354.Types exposing (..)

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
import Evergreen.V354.AiChat
import Evergreen.V354.Audio
import Evergreen.V354.Call
import Evergreen.V354.ChannelDescription
import Evergreen.V354.ChannelName
import Evergreen.V354.Coord
import Evergreen.V354.CssPixels
import Evergreen.V354.CustomEmoji
import Evergreen.V354.Discord
import Evergreen.V354.DiscordAttachmentId
import Evergreen.V354.DiscordUserData
import Evergreen.V354.DmChannel
import Evergreen.V354.DmChannelId
import Evergreen.V354.Drawing
import Evergreen.V354.Editable
import Evergreen.V354.EmailAddress
import Evergreen.V354.Embed
import Evergreen.V354.Emoji
import Evergreen.V354.FileStatus
import Evergreen.V354.Game
import Evergreen.V354.Go
import Evergreen.V354.GuildName
import Evergreen.V354.Id
import Evergreen.V354.ImageEditor
import Evergreen.V354.ImageViewer
import Evergreen.V354.LinkedAndOtherDiscordUsers
import Evergreen.V354.Local
import Evergreen.V354.LocalState
import Evergreen.V354.Log
import Evergreen.V354.LoginForm
import Evergreen.V354.MembersAndOwner
import Evergreen.V354.Message
import Evergreen.V354.MessageInput
import Evergreen.V354.MessageView
import Evergreen.V354.MuteSettings
import Evergreen.V354.MyUi
import Evergreen.V354.NonemptyDict
import Evergreen.V354.NonemptySet
import Evergreen.V354.OneOrGreater
import Evergreen.V354.OneToOne
import Evergreen.V354.Pages.Admin
import Evergreen.V354.Pagination
import Evergreen.V354.PersonName
import Evergreen.V354.Ports
import Evergreen.V354.Postmark
import Evergreen.V354.Range
import Evergreen.V354.RecoveryLogin
import Evergreen.V354.RichText
import Evergreen.V354.Route
import Evergreen.V354.Scroll
import Evergreen.V354.SecretId
import Evergreen.V354.SessionIdHash
import Evergreen.V354.Slack
import Evergreen.V354.Sticker
import Evergreen.V354.TextEditor
import Evergreen.V354.ToBackendLog
import Evergreen.V354.Touch
import Evergreen.V354.TwoFactorAuthentication
import Evergreen.V354.Ui.Anim
import Evergreen.V354.Untrusted
import Evergreen.V354.User
import Evergreen.V354.UserAgent
import Evergreen.V354.UserSession
import Evergreen.V354.WordSpellingGame
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
    | LoginFormMsg Evergreen.V354.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V354.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V354.Pages.Admin.Msg
    | PressedLogOut Evergreen.V354.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V354.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V354.Route.Route
    | SelectedFilesToAttach ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V354.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V354.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V354.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V354.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V354.NonemptyDict.NonemptyDict Int Evergreen.V354.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V354.NonemptyDict.NonemptyDict Int Evergreen.V354.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRoute Evergreen.V354.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V354.NonemptySet.NonemptySet (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V354.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V354.AiChat.Msg
    | GameMsg Evergreen.V354.Game.Msg
    | GoSpectatorMsg Evergreen.V354.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V354.Editable.Msg Evergreen.V354.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V354.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V354.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute )
        { fileId : Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute )
        { fileId : Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V354.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage Evergreen.V354.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V354.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V354.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V354.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V354.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V354.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V354.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V354.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId
        , otherUserId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRoute Evergreen.V354.MessageInput.Msg
    | MessageInputMsg Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRoute Evergreen.V354.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V354.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V354.Range.Range, Evergreen.V354.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V354.Range.Range, Evergreen.V354.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V354.Call.FromJs)
    | VoiceChatMsg Evergreen.V354.Call.Msg
    | PressedChannelHeaderTab Evergreen.V354.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V354.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V354.Audio.LoadError Evergreen.V354.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V354.Id.AnyGuildOrDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V354.Id.AnyGuildOrDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) Evergreen.V354.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V354.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V354.UserSession.UserSession
    , currentlyViewing : Evergreen.V354.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) Evergreen.V354.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.LocalState.DiscordFrontendGuild
    , user : Evergreen.V354.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.User.FrontendUser
    , discordUsers : Evergreen.V354.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V354.SessionIdHash.SessionIdHash Evergreen.V354.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V354.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId) Evergreen.V354.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId) Evergreen.V354.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V354.Call.CallId (Evergreen.V354.NonemptyDict.NonemptyDict ( Evergreen.V354.Id.Id Evergreen.V354.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V354.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V354.Go.PublicGoMatchData Evergreen.V354.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V354.Route.Route
    , windowSize : Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V354.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V354.Audio.LoadError Evergreen.V354.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V354.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V354.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V354.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileData) (List Evergreen.V354.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V354.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V354.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.ChannelName.ChannelName Evergreen.V354.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.ChannelName.ChannelName Evergreen.V354.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V354.GuildName.GuildName (Evergreen.V354.UserSession.ToBeFilledInByBackend (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V354.Id.Viewing_DiscordDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { markMessagesAsViewed : Bool
        }
        Evergreen.V354.UserSession.SetViewing
    | Local_SetName Evergreen.V354.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V354.Id.GuildOrDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V354.Id.GuildOrDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V354.Id.DiscordGuildOrDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V354.Id.DiscordGuildOrDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V354.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V354.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V354.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V354.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V354.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V354.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V354.NonemptySet.NonemptySet (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V354.Call.LocalChange
    | Local_Game Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Game.LocalChange
    | Local_Drawing Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Drawing.AnchorType Evergreen.V354.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.User.FrontendUser Effect.Time.Posix Evergreen.V354.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V354.RichText.RichText (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))) Evergreen.V354.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId) Evergreen.V354.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V354.Id.DiscordGuildOrDmId Evergreen.V354.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V354.RichText.RichText (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))) Evergreen.V354.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId) Evergreen.V354.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.ChannelName.ChannelName Evergreen.V354.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.ChannelName.ChannelName Evergreen.V354.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V354.LocalState.JoinGuildError
            { guildId : Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId
            , guild : Evergreen.V354.LocalState.FrontendGuild
            , owner : Evergreen.V354.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V354.RichText.RichText (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V354.RichText.RichText (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V354.Id.Viewing_DiscordDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V354.RichText.RichText (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Maybe Evergreen.V354.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Maybe Evergreen.V354.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V354.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V354.SessionIdHash.SessionIdHash Evergreen.V354.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V354.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V354.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V354.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V354.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V354.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Evergreen.V354.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Bool Evergreen.V354.ChannelName.ChannelName (Evergreen.V354.Discord.OptionalData (Maybe String)) (List Evergreen.V354.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
        (Evergreen.V354.NonemptyDict.NonemptyDict
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) Evergreen.V354.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Evergreen.V354.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Maybe (Evergreen.V354.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V354.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V354.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V354.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V354.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V354.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V354.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (Evergreen.V354.Discord.OptionalData String) (Evergreen.V354.Discord.OptionalData (Maybe String)) (List Evergreen.V354.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId) Evergreen.V354.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
        (Evergreen.V354.MembersAndOwner.MembersAndOwner
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Evergreen.V354.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId) Evergreen.V354.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId) Evergreen.V354.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V354.Call.ServerChange
    | Server_Game (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Game.LocalChange
    | Server_Drawing (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Drawing.AnchorType Evergreen.V354.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V354.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V354.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V354.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V354.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V354.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V354.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V354.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V354.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V354.Id.AnyGuildOrDmId Evergreen.V354.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V354.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels) (Maybe Evergreen.V354.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V354.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V354.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V354.Local.Local LocalMsg Evergreen.V354.LocalState.LocalState
    , admin : Evergreen.V354.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V354.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V354.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V354.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V354.Route.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V354.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.ThreadRoute ) (Evergreen.V354.NonemptyDict.NonemptyDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V354.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V354.Scroll.ScrollPosition
    , textEditor : Evergreen.V354.TextEditor.Model
    , profilePictureEditor : Evergreen.V354.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId, Evergreen.V354.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V354.Emoji.Model
    , voiceChat : Evergreen.V354.Call.Model
    , games : SeqDict.SeqDict Evergreen.V354.Id.GuildOrDmId Evergreen.V354.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V354.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V354.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V354.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V354.Range.Range
                , direction : Evergreen.V354.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V354.NonemptyDict.NonemptyDict Int Evergreen.V354.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V354.NonemptyDict.NonemptyDict Int Evergreen.V354.Touch.Touch
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
    | AdminToFrontend Evergreen.V354.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V354.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V354.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V354.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V354.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V354.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V354.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V354.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V354.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V354.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V354.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V354.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V354.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V354.Audio.LoadError Evergreen.V354.Audio.Source
    , startupData : Evergreen.V354.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V354.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V354.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V354.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V354.FileStatus.FileHash
    , metadata : Maybe Evergreen.V354.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId, Evergreen.V354.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V354.DmChannelId.DmChannelId, Evergreen.V354.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId, Evergreen.V354.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId, Evergreen.V354.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V354.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V354.NonemptyDict.NonemptyDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V354.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V354.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V354.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V354.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V354.DmChannelId.DmChannelId Evergreen.V354.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) Evergreen.V354.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.Slack.Id Evergreen.V354.Slack.ChannelId) Evergreen.V354.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V354.OneToOne.OneToOne String (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    , slackUsers : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.Slack.Id Evergreen.V354.Slack.UserId) (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    , slackServers : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.Slack.Id Evergreen.V354.Slack.TeamId) (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    , slackToken : Maybe Evergreen.V354.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V354.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V354.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V354.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V354.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Evergreen.V354.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId, Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V354.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V354.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V354.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V354.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.LocalState.LoadingDiscordChannel Evergreen.V354.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V354.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId) Evergreen.V354.Sticker.StickerData
    , discordStickers : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.Discord.Id Evergreen.V354.Discord.StickerId) (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId) Evergreen.V354.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V354.OneToOne.OneToOne Evergreen.V354.RichText.DiscordCustomEmojiIdAndName (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V354.Postmark.ApiKey
    , serverSecret : Evergreen.V354.SecretId.SecretId Evergreen.V354.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V354.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.GamePublicId) ( Evergreen.V354.DmChannelId.GuildOrFullDmId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V354.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V354.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V354.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.Id.ThreadRoute (Maybe Evergreen.V354.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V354.DmChannelId.DmChannelId Evergreen.V354.Id.ThreadRoute (Maybe Evergreen.V354.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V354.Id.Id Evergreen.V354.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V354.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V354.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V354.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V354.Untrusted.Untrusted Evergreen.V354.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V354.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V354.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V354.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V354.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V354.PersonName.PersonName Evergreen.V354.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V354.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V354.Slack.OAuthCode Evergreen.V354.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V354.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V354.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V354.Id.Id Evergreen.V354.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V354.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V354.EmailAddress.EmailAddress (Result Evergreen.V354.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V354.EmailAddress.EmailAddress (Result Evergreen.V354.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V354.EmailAddress.EmailAddress (Result Evergreen.V354.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V354.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMaybeMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Result Evergreen.V354.Discord.HttpError Evergreen.V354.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V354.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Result Evergreen.V354.Discord.HttpError Evergreen.V354.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) (Result Evergreen.V354.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) (Result Evergreen.V354.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) (Result Evergreen.V354.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) (Result Evergreen.V354.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji (Result Evergreen.V354.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji (Result Evergreen.V354.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji (Result Evergreen.V354.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji (Result Evergreen.V354.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V354.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V354.Discord.HttpError (List ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId, Maybe Evergreen.V354.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Effect.Time.Posix Evergreen.V354.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V354.Slack.CurrentUser
            , team : Evergreen.V354.Slack.Team
            , users : List Evergreen.V354.Slack.User
            , channels : List ( Evergreen.V354.Slack.Channel, List Evergreen.V354.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Result Effect.Http.Error Evergreen.V354.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Discord.UserAuth (Result Evergreen.V354.Discord.HttpError Evergreen.V354.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Result Evergreen.V354.Discord.HttpError Evergreen.V354.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
        (Result
            Evergreen.V354.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId
                , members : List (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
                }
            , List
                ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId
                , { guild : Evergreen.V354.Discord.GatewayGuild
                  , channels : List Evergreen.V354.Discord.Channel
                  , icon : Maybe Evergreen.V354.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Maybe String) Evergreen.V354.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V354.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.AttachmentId, Evergreen.V354.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V354.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.AttachmentId, Evergreen.V354.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V354.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V354.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V354.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V354.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (Result Evergreen.V354.Discord.HttpError Evergreen.V354.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Result Evergreen.V354.Discord.HttpError (List Evergreen.V354.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V354.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V354.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V354.DmChannelId.DmChannelId Evergreen.V354.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V354.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V354.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V354.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
        (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V354.Discord.HttpError
            { guild : Evergreen.V354.Discord.GatewayGuild
            , channels : List Evergreen.V354.Discord.Channel
            , icon : Maybe Evergreen.V354.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Result Evergreen.V354.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V354.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (List ( Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId, Result Effect.Http.Error Evergreen.V354.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId, Result Effect.Http.Error Evergreen.V354.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (List ( Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V354.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V354.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V354.Discord.HttpError (List Evergreen.V354.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V354.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V354.SecretId.SecretId Evergreen.V354.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V354.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Result Evergreen.V354.Discord.HttpError ( Evergreen.V354.Discord.Guild, List Evergreen.V354.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V354.FileStatus.FileHash Int (Maybe (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Call.CallId
