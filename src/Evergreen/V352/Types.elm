module Evergreen.V352.Types exposing (..)

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
import Evergreen.V352.AiChat
import Evergreen.V352.Audio
import Evergreen.V352.Call
import Evergreen.V352.ChannelDescription
import Evergreen.V352.ChannelName
import Evergreen.V352.Coord
import Evergreen.V352.CssPixels
import Evergreen.V352.CustomEmoji
import Evergreen.V352.Discord
import Evergreen.V352.DiscordAttachmentId
import Evergreen.V352.DiscordUserData
import Evergreen.V352.DmChannel
import Evergreen.V352.DmChannelId
import Evergreen.V352.Drawing
import Evergreen.V352.Editable
import Evergreen.V352.EmailAddress
import Evergreen.V352.Embed
import Evergreen.V352.Emoji
import Evergreen.V352.FileStatus
import Evergreen.V352.Game
import Evergreen.V352.Go
import Evergreen.V352.GuildName
import Evergreen.V352.Id
import Evergreen.V352.ImageEditor
import Evergreen.V352.ImageViewer
import Evergreen.V352.LinkedAndOtherDiscordUsers
import Evergreen.V352.Local
import Evergreen.V352.LocalState
import Evergreen.V352.Log
import Evergreen.V352.LoginForm
import Evergreen.V352.MembersAndOwner
import Evergreen.V352.Message
import Evergreen.V352.MessageInput
import Evergreen.V352.MessageView
import Evergreen.V352.MuteSettings
import Evergreen.V352.MyUi
import Evergreen.V352.NonemptyDict
import Evergreen.V352.NonemptySet
import Evergreen.V352.OneOrGreater
import Evergreen.V352.OneToOne
import Evergreen.V352.Pages.Admin
import Evergreen.V352.Pagination
import Evergreen.V352.PersonName
import Evergreen.V352.Ports
import Evergreen.V352.Postmark
import Evergreen.V352.Range
import Evergreen.V352.RecoveryLogin
import Evergreen.V352.RichText
import Evergreen.V352.Route
import Evergreen.V352.Scroll
import Evergreen.V352.SecretId
import Evergreen.V352.SessionIdHash
import Evergreen.V352.Slack
import Evergreen.V352.Sticker
import Evergreen.V352.TextEditor
import Evergreen.V352.ToBackendLog
import Evergreen.V352.Touch
import Evergreen.V352.TwoFactorAuthentication
import Evergreen.V352.Ui.Anim
import Evergreen.V352.Untrusted
import Evergreen.V352.User
import Evergreen.V352.UserAgent
import Evergreen.V352.UserSession
import Evergreen.V352.WordSpellingGame
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
    | LoginFormMsg Evergreen.V352.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V352.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V352.Pages.Admin.Msg
    | PressedLogOut Evergreen.V352.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V352.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V352.Route.Route
    | SelectedFilesToAttach ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V352.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V352.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V352.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V352.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V352.NonemptyDict.NonemptyDict Int Evergreen.V352.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V352.NonemptyDict.NonemptyDict Int Evergreen.V352.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRoute Evergreen.V352.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V352.NonemptySet.NonemptySet (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V352.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V352.AiChat.Msg
    | GameMsg Evergreen.V352.Game.Msg
    | GoSpectatorMsg Evergreen.V352.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V352.Editable.Msg Evergreen.V352.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V352.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V352.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute )
        { fileId : Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute )
        { fileId : Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V352.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage Evergreen.V352.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V352.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V352.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V352.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V352.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V352.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V352.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V352.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId
        , otherUserId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRoute Evergreen.V352.MessageInput.Msg
    | MessageInputMsg Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRoute Evergreen.V352.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V352.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V352.Range.Range, Evergreen.V352.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V352.Range.Range, Evergreen.V352.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V352.Call.FromJs)
    | VoiceChatMsg Evergreen.V352.Call.Msg
    | PressedChannelHeaderTab Evergreen.V352.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V352.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V352.Audio.LoadError Evergreen.V352.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V352.Id.AnyGuildOrDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V352.Id.AnyGuildOrDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) Evergreen.V352.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V352.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V352.UserSession.UserSession
    , currentlyViewing : Evergreen.V352.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) Evergreen.V352.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.LocalState.DiscordFrontendGuild
    , user : Evergreen.V352.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.User.FrontendUser
    , discordUsers : Evergreen.V352.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V352.SessionIdHash.SessionIdHash Evergreen.V352.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V352.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId) Evergreen.V352.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId) Evergreen.V352.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V352.Call.CallId (Evergreen.V352.NonemptyDict.NonemptyDict ( Evergreen.V352.Id.Id Evergreen.V352.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V352.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V352.Go.PublicGoMatchData Evergreen.V352.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V352.Route.Route
    , windowSize : Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V352.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V352.Audio.LoadError Evergreen.V352.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V352.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V352.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V352.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileData) (List Evergreen.V352.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V352.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V352.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.ChannelName.ChannelName Evergreen.V352.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.ChannelName.ChannelName Evergreen.V352.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V352.GuildName.GuildName (Evergreen.V352.UserSession.ToBeFilledInByBackend (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V352.Id.Viewing_DiscordDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { routeRequestCausedByPressingLink : Bool
        }
        Evergreen.V352.UserSession.SetViewing
    | Local_SetName Evergreen.V352.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V352.Id.GuildOrDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V352.Id.GuildOrDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V352.Id.DiscordGuildOrDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V352.Id.DiscordGuildOrDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V352.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V352.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V352.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V352.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V352.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V352.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V352.NonemptySet.NonemptySet (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V352.Call.LocalChange
    | Local_Game Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Game.LocalChange
    | Local_Drawing Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Drawing.AnchorType Evergreen.V352.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.User.FrontendUser Effect.Time.Posix Evergreen.V352.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V352.RichText.RichText (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))) Evergreen.V352.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId) Evergreen.V352.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V352.Id.DiscordGuildOrDmId Evergreen.V352.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V352.RichText.RichText (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))) Evergreen.V352.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId) Evergreen.V352.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.ChannelName.ChannelName Evergreen.V352.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.ChannelName.ChannelName Evergreen.V352.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V352.LocalState.JoinGuildError
            { guildId : Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId
            , guild : Evergreen.V352.LocalState.FrontendGuild
            , owner : Evergreen.V352.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V352.RichText.RichText (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V352.RichText.RichText (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V352.Id.Viewing_DiscordDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V352.RichText.RichText (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Maybe Evergreen.V352.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Maybe Evergreen.V352.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V352.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V352.SessionIdHash.SessionIdHash Evergreen.V352.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V352.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V352.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V352.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V352.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V352.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Evergreen.V352.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Bool Evergreen.V352.ChannelName.ChannelName (Evergreen.V352.Discord.OptionalData (Maybe String)) (List Evergreen.V352.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
        (Evergreen.V352.NonemptyDict.NonemptyDict
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) Evergreen.V352.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Evergreen.V352.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Maybe (Evergreen.V352.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V352.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V352.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V352.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V352.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V352.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V352.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (Evergreen.V352.Discord.OptionalData String) (Evergreen.V352.Discord.OptionalData (Maybe String)) (List Evergreen.V352.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId) Evergreen.V352.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
        (Evergreen.V352.MembersAndOwner.MembersAndOwner
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Evergreen.V352.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId) Evergreen.V352.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId) Evergreen.V352.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V352.Call.ServerChange
    | Server_Game (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Game.LocalChange
    | Server_Drawing (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Drawing.AnchorType Evergreen.V352.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V352.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V352.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V352.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V352.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V352.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V352.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V352.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V352.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V352.Id.AnyGuildOrDmId Evergreen.V352.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V352.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels) (Maybe Evergreen.V352.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V352.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V352.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V352.Local.Local LocalMsg Evergreen.V352.LocalState.LocalState
    , admin : Evergreen.V352.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V352.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V352.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V352.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V352.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V352.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.ThreadRoute ) (Evergreen.V352.NonemptyDict.NonemptyDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V352.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V352.Scroll.ScrollPosition
    , textEditor : Evergreen.V352.TextEditor.Model
    , profilePictureEditor : Evergreen.V352.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId, Evergreen.V352.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V352.Emoji.Model
    , voiceChat : Evergreen.V352.Call.Model
    , games : SeqDict.SeqDict Evergreen.V352.Id.GuildOrDmId Evergreen.V352.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V352.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V352.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V352.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V352.Range.Range
                , direction : Evergreen.V352.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V352.NonemptyDict.NonemptyDict Int Evergreen.V352.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V352.NonemptyDict.NonemptyDict Int Evergreen.V352.Touch.Touch
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
    | AdminToFrontend Evergreen.V352.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V352.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V352.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V352.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V352.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V352.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V352.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V352.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V352.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V352.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V352.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V352.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V352.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V352.Audio.LoadError Evergreen.V352.Audio.Source
    , startupData : Evergreen.V352.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V352.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V352.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V352.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V352.FileStatus.FileHash
    , metadata : Maybe Evergreen.V352.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId, Evergreen.V352.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V352.DmChannelId.DmChannelId, Evergreen.V352.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId, Evergreen.V352.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId, Evergreen.V352.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V352.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V352.NonemptyDict.NonemptyDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V352.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V352.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V352.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V352.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V352.DmChannelId.DmChannelId Evergreen.V352.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) Evergreen.V352.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.Slack.Id Evergreen.V352.Slack.ChannelId) Evergreen.V352.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V352.OneToOne.OneToOne String (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    , slackUsers : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.Slack.Id Evergreen.V352.Slack.UserId) (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    , slackServers : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.Slack.Id Evergreen.V352.Slack.TeamId) (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    , slackToken : Maybe Evergreen.V352.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V352.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V352.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V352.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V352.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Evergreen.V352.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId, Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V352.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V352.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V352.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V352.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.LocalState.LoadingDiscordChannel Evergreen.V352.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V352.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId) Evergreen.V352.Sticker.StickerData
    , discordStickers : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.Discord.Id Evergreen.V352.Discord.StickerId) (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId) Evergreen.V352.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V352.OneToOne.OneToOne Evergreen.V352.RichText.DiscordCustomEmojiIdAndName (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V352.Postmark.ApiKey
    , serverSecret : Evergreen.V352.SecretId.SecretId Evergreen.V352.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V352.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.GamePublicId) ( Evergreen.V352.DmChannelId.GuildOrFullDmId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V352.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V352.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V352.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.Id.ThreadRoute (Maybe Evergreen.V352.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V352.DmChannelId.DmChannelId Evergreen.V352.Id.ThreadRoute (Maybe Evergreen.V352.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V352.Id.Id Evergreen.V352.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V352.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V352.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V352.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V352.Untrusted.Untrusted Evergreen.V352.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V352.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V352.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V352.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V352.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V352.PersonName.PersonName Evergreen.V352.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V352.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V352.Slack.OAuthCode Evergreen.V352.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V352.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V352.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V352.Id.Id Evergreen.V352.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V352.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V352.EmailAddress.EmailAddress (Result Evergreen.V352.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V352.EmailAddress.EmailAddress (Result Evergreen.V352.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V352.EmailAddress.EmailAddress (Result Evergreen.V352.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V352.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMaybeMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Result Evergreen.V352.Discord.HttpError Evergreen.V352.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V352.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Result Evergreen.V352.Discord.HttpError Evergreen.V352.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) (Result Evergreen.V352.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) (Result Evergreen.V352.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) (Result Evergreen.V352.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) (Result Evergreen.V352.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji (Result Evergreen.V352.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji (Result Evergreen.V352.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji (Result Evergreen.V352.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji (Result Evergreen.V352.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V352.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V352.Discord.HttpError (List ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId, Maybe Evergreen.V352.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Effect.Time.Posix Evergreen.V352.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V352.Slack.CurrentUser
            , team : Evergreen.V352.Slack.Team
            , users : List Evergreen.V352.Slack.User
            , channels : List ( Evergreen.V352.Slack.Channel, List Evergreen.V352.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Result Effect.Http.Error Evergreen.V352.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Discord.UserAuth (Result Evergreen.V352.Discord.HttpError Evergreen.V352.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Result Evergreen.V352.Discord.HttpError Evergreen.V352.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
        (Result
            Evergreen.V352.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId
                , members : List (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
                }
            , List
                ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId
                , { guild : Evergreen.V352.Discord.GatewayGuild
                  , channels : List Evergreen.V352.Discord.Channel
                  , icon : Maybe Evergreen.V352.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Maybe String) Evergreen.V352.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V352.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.AttachmentId, Evergreen.V352.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V352.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.AttachmentId, Evergreen.V352.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V352.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V352.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V352.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V352.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (Result Evergreen.V352.Discord.HttpError Evergreen.V352.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Result Evergreen.V352.Discord.HttpError (List Evergreen.V352.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V352.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V352.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V352.DmChannelId.DmChannelId Evergreen.V352.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V352.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V352.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V352.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
        (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V352.Discord.HttpError
            { guild : Evergreen.V352.Discord.GatewayGuild
            , channels : List Evergreen.V352.Discord.Channel
            , icon : Maybe Evergreen.V352.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Result Evergreen.V352.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V352.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (List ( Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId, Result Effect.Http.Error Evergreen.V352.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId, Result Effect.Http.Error Evergreen.V352.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (List ( Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V352.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V352.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V352.Discord.HttpError (List Evergreen.V352.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V352.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V352.SecretId.SecretId Evergreen.V352.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V352.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Result Evergreen.V352.Discord.HttpError ( Evergreen.V352.Discord.Guild, List Evergreen.V352.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V352.FileStatus.FileHash Int (Maybe (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Call.CallId
