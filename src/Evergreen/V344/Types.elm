module Evergreen.V344.Types exposing (..)

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
import Evergreen.V344.AiChat
import Evergreen.V344.Audio
import Evergreen.V344.Call
import Evergreen.V344.ChannelDescription
import Evergreen.V344.ChannelName
import Evergreen.V344.Cloudflare
import Evergreen.V344.Coord
import Evergreen.V344.CssPixels
import Evergreen.V344.CustomEmoji
import Evergreen.V344.Discord
import Evergreen.V344.DiscordAttachmentId
import Evergreen.V344.DiscordUserData
import Evergreen.V344.DmChannel
import Evergreen.V344.DmChannelId
import Evergreen.V344.Drawing
import Evergreen.V344.Editable
import Evergreen.V344.EmailAddress
import Evergreen.V344.Embed
import Evergreen.V344.Emoji
import Evergreen.V344.FileStatus
import Evergreen.V344.Game
import Evergreen.V344.Go
import Evergreen.V344.GuildName
import Evergreen.V344.Id
import Evergreen.V344.ImageEditor
import Evergreen.V344.ImageViewer
import Evergreen.V344.LinkedAndOtherDiscordUsers
import Evergreen.V344.Local
import Evergreen.V344.LocalState
import Evergreen.V344.Log
import Evergreen.V344.LoginForm
import Evergreen.V344.MembersAndOwner
import Evergreen.V344.Message
import Evergreen.V344.MessageInput
import Evergreen.V344.MessageView
import Evergreen.V344.MuteSettings
import Evergreen.V344.MyUi
import Evergreen.V344.NonemptyDict
import Evergreen.V344.NonemptySet
import Evergreen.V344.OneOrGreater
import Evergreen.V344.OneToOne
import Evergreen.V344.Pages.Admin
import Evergreen.V344.Pagination
import Evergreen.V344.PersonName
import Evergreen.V344.Ports
import Evergreen.V344.Postmark
import Evergreen.V344.Range
import Evergreen.V344.RecoveryLogin
import Evergreen.V344.RichText
import Evergreen.V344.Route
import Evergreen.V344.Scroll
import Evergreen.V344.SecretId
import Evergreen.V344.SessionIdHash
import Evergreen.V344.Slack
import Evergreen.V344.Sticker
import Evergreen.V344.TextEditor
import Evergreen.V344.ToBackendLog
import Evergreen.V344.Touch
import Evergreen.V344.TwoFactorAuthentication
import Evergreen.V344.Ui.Anim
import Evergreen.V344.Untrusted
import Evergreen.V344.User
import Evergreen.V344.UserAgent
import Evergreen.V344.UserSession
import Evergreen.V344.WordSpellingGame
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
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V344.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V344.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V344.Pages.Admin.Msg
    | PressedLogOut Evergreen.V344.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V344.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V344.Route.Route
    | SelectedFilesToAttach ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V344.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V344.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V344.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V344.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V344.NonemptyDict.NonemptyDict Int Evergreen.V344.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V344.NonemptyDict.NonemptyDict Int Evergreen.V344.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRoute Evergreen.V344.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V344.NonemptySet.NonemptySet (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V344.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V344.AiChat.Msg
    | GameMsg Evergreen.V344.Game.Msg
    | GoSpectatorMsg Evergreen.V344.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V344.Editable.Msg Evergreen.V344.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V344.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V344.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute )
        { fileId : Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute )
        { fileId : Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V344.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage Evergreen.V344.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V344.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V344.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V344.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V344.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.User.NotificationLevel
    | GotStartupData Evergreen.V344.Ports.StartupData
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V344.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V344.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId
        , otherUserId : Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRoute Evergreen.V344.MessageInput.Msg
    | MessageInputMsg Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRoute Evergreen.V344.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V344.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V344.Range.Range, Evergreen.V344.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V344.Range.Range, Evergreen.V344.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V344.Call.FromJs)
    | VoiceChatMsg Evergreen.V344.Call.Msg
    | PressedChannelHeaderTab Evergreen.V344.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V344.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V344.Audio.LoadError Evergreen.V344.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V344.Id.AnyGuildOrDmId (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V344.Id.AnyGuildOrDmId (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) Evergreen.V344.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V344.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V344.UserSession.UserSession
    , currentlyViewing : Evergreen.V344.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) Evergreen.V344.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.LocalState.DiscordFrontendGuild
    , user : Evergreen.V344.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.User.FrontendUser
    , discordUsers : Evergreen.V344.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V344.SessionIdHash.SessionIdHash Evergreen.V344.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V344.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId) Evergreen.V344.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId) Evergreen.V344.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V344.Call.CallId (Evergreen.V344.NonemptyDict.NonemptyDict ( Evergreen.V344.Id.Id Evergreen.V344.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V344.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V344.Go.PublicGoMatchData Evergreen.V344.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V344.Route.Route
    , windowSize : Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V344.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V344.Audio.LoadError Evergreen.V344.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V344.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V344.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V344.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V344.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V344.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.ChannelName.ChannelName Evergreen.V344.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.ChannelName.ChannelName Evergreen.V344.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V344.GuildName.GuildName (Evergreen.V344.UserSession.ToBeFilledInByBackend (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V344.Id.DiscordGuildOrDmId_DmData (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V344.UserSession.SetViewing
    | Local_SetName Evergreen.V344.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V344.Id.GuildOrDmId (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V344.Id.GuildOrDmId (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V344.Id.DiscordGuildOrDmId (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V344.Id.DiscordGuildOrDmId (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V344.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V344.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V344.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V344.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V344.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V344.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V344.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V344.NonemptySet.NonemptySet (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V344.Call.LocalChange
    | Local_Game Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Game.LocalChange
    | Local_Drawing Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Drawing.AnchorType Evergreen.V344.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.User.FrontendUser Effect.Time.Posix Evergreen.V344.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V344.RichText.RichText (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))) Evergreen.V344.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId) Evergreen.V344.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V344.Id.DiscordGuildOrDmId Evergreen.V344.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V344.RichText.RichText (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))) Evergreen.V344.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId) Evergreen.V344.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.ChannelName.ChannelName Evergreen.V344.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.ChannelName.ChannelName Evergreen.V344.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V344.LocalState.JoinGuildError
            { guildId : Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId
            , guild : Evergreen.V344.LocalState.FrontendGuild
            , owner : Evergreen.V344.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V344.RichText.RichText (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V344.RichText.RichText (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V344.Id.DiscordGuildOrDmId_DmData (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V344.RichText.RichText (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Maybe Evergreen.V344.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Maybe Evergreen.V344.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V344.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V344.SessionIdHash.SessionIdHash Evergreen.V344.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V344.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V344.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V344.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V344.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V344.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Evergreen.V344.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.ChannelName.ChannelName (Evergreen.V344.Discord.OptionalData (Maybe String)) (List Evergreen.V344.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
        (Evergreen.V344.NonemptyDict.NonemptyDict
            (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) Evergreen.V344.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Evergreen.V344.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Maybe (Evergreen.V344.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V344.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V344.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V344.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V344.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V344.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V344.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Discord.OptionalData String) (Evergreen.V344.Discord.OptionalData (Maybe String)) (List Evergreen.V344.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.RoleId) Evergreen.V344.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
        (Evergreen.V344.MembersAndOwner.MembersAndOwner
            (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V344.Discord.Id Evergreen.V344.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Evergreen.V344.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId) Evergreen.V344.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId) Evergreen.V344.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V344.Call.ServerChange
    | Server_Game (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Game.LocalChange
    | Server_Drawing (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Drawing.AnchorType Evergreen.V344.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V344.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V344.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V344.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V344.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V344.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V344.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V344.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V344.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V344.Id.AnyGuildOrDmId Evergreen.V344.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V344.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels) (Maybe Evergreen.V344.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V344.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V344.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V344.Local.Local LocalMsg Evergreen.V344.LocalState.LocalState
    , admin : Evergreen.V344.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V344.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V344.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V344.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V344.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V344.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.ThreadRoute ) (Evergreen.V344.NonemptyDict.NonemptyDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V344.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V344.Scroll.ScrollPosition
    , textEditor : Evergreen.V344.TextEditor.Model
    , profilePictureEditor : Evergreen.V344.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId, Evergreen.V344.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V344.Emoji.Model
    , voiceChat : Evergreen.V344.Call.Model
    , games : SeqDict.SeqDict Evergreen.V344.Id.GuildOrDmId Evergreen.V344.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V344.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V344.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V344.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V344.Range.Range
                , direction : Evergreen.V344.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V344.NonemptyDict.NonemptyDict Int Evergreen.V344.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V344.NonemptyDict.NonemptyDict Int Evergreen.V344.Touch.Touch
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
    | AdminToFrontend Evergreen.V344.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V344.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V344.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V344.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V344.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V344.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V344.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V344.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V344.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V344.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V344.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V344.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V344.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V344.Audio.LoadError Evergreen.V344.Audio.Source
    , startupData : Evergreen.V344.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V344.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V344.Id.Id Evergreen.V344.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V344.Id.Id Evergreen.V344.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V344.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V344.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V344.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V344.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId, Evergreen.V344.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V344.DmChannelId.DmChannelId, Evergreen.V344.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId, Evergreen.V344.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId, Evergreen.V344.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V344.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V344.NonemptyDict.NonemptyDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V344.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V344.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V344.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V344.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V344.DmChannelId.DmChannelId Evergreen.V344.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) Evergreen.V344.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V344.OneToOne.OneToOne (Evergreen.V344.Slack.Id Evergreen.V344.Slack.ChannelId) Evergreen.V344.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V344.OneToOne.OneToOne String (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    , slackUsers : Evergreen.V344.OneToOne.OneToOne (Evergreen.V344.Slack.Id Evergreen.V344.Slack.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    , slackServers : Evergreen.V344.OneToOne.OneToOne (Evergreen.V344.Slack.Id Evergreen.V344.Slack.TeamId) (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    , slackToken : Maybe Evergreen.V344.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V344.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V344.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V344.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V344.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V344.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V344.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V344.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V344.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Evergreen.V344.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId, Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V344.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V344.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V344.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V344.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.LocalState.LoadingDiscordChannel Evergreen.V344.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V344.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId) Evergreen.V344.Sticker.StickerData
    , discordStickers : Evergreen.V344.OneToOne.OneToOne (Evergreen.V344.Discord.Id Evergreen.V344.Discord.StickerId) (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId) Evergreen.V344.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V344.OneToOne.OneToOne Evergreen.V344.RichText.DiscordCustomEmojiIdAndName (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V344.Postmark.ApiKey
    , serverSecret : Evergreen.V344.SecretId.SecretId Evergreen.V344.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V344.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V344.OneToOne.OneToOne (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.GamePublicId) ( Evergreen.V344.DmChannelId.GuildOrFullDmId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V344.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V344.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V344.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.Id.ThreadRoute (Maybe Evergreen.V344.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V344.DmChannelId.DmChannelId Evergreen.V344.Id.ThreadRoute (Maybe Evergreen.V344.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V344.Id.Id Evergreen.V344.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V344.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V344.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V344.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V344.Untrusted.Untrusted Evergreen.V344.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V344.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V344.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V344.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V344.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V344.PersonName.PersonName Evergreen.V344.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V344.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V344.Slack.OAuthCode Evergreen.V344.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V344.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V344.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V344.Id.Id Evergreen.V344.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V344.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V344.EmailAddress.EmailAddress (Result Evergreen.V344.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V344.EmailAddress.EmailAddress (Result Evergreen.V344.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V344.EmailAddress.EmailAddress (Result Evergreen.V344.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V344.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMaybeMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Result Evergreen.V344.Discord.HttpError Evergreen.V344.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V344.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Result Evergreen.V344.Discord.HttpError Evergreen.V344.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) (Result Evergreen.V344.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) (Result Evergreen.V344.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) (Result Evergreen.V344.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) (Result Evergreen.V344.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji (Result Evergreen.V344.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji (Result Evergreen.V344.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji (Result Evergreen.V344.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji (Result Evergreen.V344.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V344.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V344.Discord.HttpError (List ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId, Maybe Evergreen.V344.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Effect.Time.Posix Evergreen.V344.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V344.Slack.CurrentUser
            , team : Evergreen.V344.Slack.Team
            , users : List Evergreen.V344.Slack.User
            , channels : List ( Evergreen.V344.Slack.Channel, List Evergreen.V344.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Result Effect.Http.Error Evergreen.V344.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V344.Local.ChangeId Effect.Time.Posix Evergreen.V344.Call.CallId Evergreen.V344.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V344.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V344.Local.ChangeId Effect.Time.Posix Evergreen.V344.Call.CallId Evergreen.V344.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V344.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V344.Local.ChangeId Evergreen.V344.Call.ConnectionId Evergreen.V344.Cloudflare.RealtimeSessionId (List Evergreen.V344.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V344.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V344.Local.ChangeId Evergreen.V344.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Discord.UserAuth (Result Evergreen.V344.Discord.HttpError Evergreen.V344.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Result Evergreen.V344.Discord.HttpError Evergreen.V344.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
        (Result
            Evergreen.V344.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId
                , members : List (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
                }
            , List
                ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId
                , { guild : Evergreen.V344.Discord.GatewayGuild
                  , channels : List Evergreen.V344.Discord.Channel
                  , icon : Maybe Evergreen.V344.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Bool Evergreen.V344.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V344.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.AttachmentId, Evergreen.V344.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V344.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.AttachmentId, Evergreen.V344.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V344.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V344.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V344.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V344.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Result Evergreen.V344.Discord.HttpError Evergreen.V344.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Result Evergreen.V344.Discord.HttpError (List Evergreen.V344.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V344.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V344.DmChannelId.DmChannelId Evergreen.V344.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V344.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V344.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V344.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
        (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V344.Discord.HttpError
            { guild : Evergreen.V344.Discord.GatewayGuild
            , channels : List Evergreen.V344.Discord.Channel
            , icon : Maybe Evergreen.V344.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Result Evergreen.V344.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V344.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (List ( Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId, Result Effect.Http.Error Evergreen.V344.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId, Result Effect.Http.Error Evergreen.V344.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (List ( Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V344.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V344.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V344.Discord.HttpError (List Evergreen.V344.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V344.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V344.SecretId.SecretId Evergreen.V344.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V344.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Result Evergreen.V344.Discord.HttpError ( Evergreen.V344.Discord.Guild, List Evergreen.V344.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V344.FileStatus.FileHash Int (Maybe (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
