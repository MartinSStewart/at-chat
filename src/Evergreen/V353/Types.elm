module Evergreen.V353.Types exposing (..)

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
import Evergreen.V353.AiChat
import Evergreen.V353.Audio
import Evergreen.V353.Call
import Evergreen.V353.ChannelDescription
import Evergreen.V353.ChannelName
import Evergreen.V353.Coord
import Evergreen.V353.CssPixels
import Evergreen.V353.CustomEmoji
import Evergreen.V353.Discord
import Evergreen.V353.DiscordAttachmentId
import Evergreen.V353.DiscordUserData
import Evergreen.V353.DmChannel
import Evergreen.V353.DmChannelId
import Evergreen.V353.Drawing
import Evergreen.V353.Editable
import Evergreen.V353.EmailAddress
import Evergreen.V353.Embed
import Evergreen.V353.Emoji
import Evergreen.V353.FileStatus
import Evergreen.V353.Game
import Evergreen.V353.Go
import Evergreen.V353.GuildName
import Evergreen.V353.Id
import Evergreen.V353.ImageEditor
import Evergreen.V353.ImageViewer
import Evergreen.V353.LinkedAndOtherDiscordUsers
import Evergreen.V353.Local
import Evergreen.V353.LocalState
import Evergreen.V353.Log
import Evergreen.V353.LoginForm
import Evergreen.V353.MembersAndOwner
import Evergreen.V353.Message
import Evergreen.V353.MessageInput
import Evergreen.V353.MessageView
import Evergreen.V353.MuteSettings
import Evergreen.V353.MyUi
import Evergreen.V353.NonemptyDict
import Evergreen.V353.NonemptySet
import Evergreen.V353.OneOrGreater
import Evergreen.V353.OneToOne
import Evergreen.V353.Pages.Admin
import Evergreen.V353.Pagination
import Evergreen.V353.PersonName
import Evergreen.V353.Ports
import Evergreen.V353.Postmark
import Evergreen.V353.Range
import Evergreen.V353.RecoveryLogin
import Evergreen.V353.RichText
import Evergreen.V353.Route
import Evergreen.V353.Scroll
import Evergreen.V353.SecretId
import Evergreen.V353.SessionIdHash
import Evergreen.V353.Slack
import Evergreen.V353.Sticker
import Evergreen.V353.TextEditor
import Evergreen.V353.ToBackendLog
import Evergreen.V353.Touch
import Evergreen.V353.TwoFactorAuthentication
import Evergreen.V353.Ui.Anim
import Evergreen.V353.Untrusted
import Evergreen.V353.User
import Evergreen.V353.UserAgent
import Evergreen.V353.UserSession
import Evergreen.V353.WordSpellingGame
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
    | LoginFormMsg Evergreen.V353.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V353.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V353.Pages.Admin.Msg
    | PressedLogOut Evergreen.V353.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V353.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V353.Route.Route
    | SelectedFilesToAttach ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V353.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V353.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V353.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V353.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V353.NonemptyDict.NonemptyDict Int Evergreen.V353.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V353.NonemptyDict.NonemptyDict Int Evergreen.V353.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRoute Evergreen.V353.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | MessageMenu_PressedMarkAsUnread Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V353.NonemptySet.NonemptySet (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V353.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V353.AiChat.Msg
    | GameMsg Evergreen.V353.Game.Msg
    | GoSpectatorMsg Evergreen.V353.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V353.Editable.Msg Evergreen.V353.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V353.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V353.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute )
        { fileId : Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute )
        { fileId : Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V353.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage Evergreen.V353.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V353.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V353.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V353.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V353.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V353.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V353.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V353.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId
        , otherUserId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRoute Evergreen.V353.MessageInput.Msg
    | MessageInputMsg Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRoute Evergreen.V353.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V353.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V353.Range.Range, Evergreen.V353.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V353.Range.Range, Evergreen.V353.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V353.Call.FromJs)
    | VoiceChatMsg Evergreen.V353.Call.Msg
    | PressedChannelHeaderTab Evergreen.V353.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V353.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V353.Audio.LoadError Evergreen.V353.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V353.Id.AnyGuildOrDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V353.Id.AnyGuildOrDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) Evergreen.V353.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V353.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V353.UserSession.UserSession
    , currentlyViewing : Evergreen.V353.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) Evergreen.V353.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.LocalState.DiscordFrontendGuild
    , user : Evergreen.V353.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.User.FrontendUser
    , discordUsers : Evergreen.V353.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V353.SessionIdHash.SessionIdHash Evergreen.V353.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V353.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId) Evergreen.V353.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId) Evergreen.V353.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V353.Call.CallId (Evergreen.V353.NonemptyDict.NonemptyDict ( Evergreen.V353.Id.Id Evergreen.V353.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V353.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V353.Go.PublicGoMatchData Evergreen.V353.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V353.Route.Route
    , windowSize : Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V353.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V353.Audio.LoadError Evergreen.V353.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V353.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V353.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V353.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileData) (List Evergreen.V353.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V353.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V353.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.ChannelName.ChannelName Evergreen.V353.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.ChannelName.ChannelName Evergreen.V353.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V353.GuildName.GuildName (Evergreen.V353.UserSession.ToBeFilledInByBackend (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V353.Id.Viewing_DiscordDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing
        { routeRequestCausedByPressingLink : Bool
        }
        Evergreen.V353.UserSession.SetViewing
    | Local_SetName Evergreen.V353.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V353.Id.GuildOrDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V353.Id.GuildOrDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V353.Id.DiscordGuildOrDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V353.Id.DiscordGuildOrDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V353.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V353.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V353.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V353.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V353.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V353.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V353.NonemptySet.NonemptySet (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V353.Call.LocalChange
    | Local_Game Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Game.LocalChange
    | Local_Drawing Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Drawing.AnchorType Evergreen.V353.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.User.FrontendUser Effect.Time.Posix Evergreen.V353.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V353.RichText.RichText (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))) Evergreen.V353.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId) Evergreen.V353.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V353.Id.DiscordGuildOrDmId Evergreen.V353.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V353.RichText.RichText (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))) Evergreen.V353.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId) Evergreen.V353.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.ChannelName.ChannelName Evergreen.V353.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.ChannelName.ChannelName Evergreen.V353.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V353.LocalState.JoinGuildError
            { guildId : Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId
            , guild : Evergreen.V353.LocalState.FrontendGuild
            , owner : Evergreen.V353.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V353.RichText.RichText (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V353.RichText.RichText (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V353.Id.Viewing_DiscordDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V353.RichText.RichText (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Maybe Evergreen.V353.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Maybe Evergreen.V353.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V353.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V353.SessionIdHash.SessionIdHash Evergreen.V353.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V353.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V353.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V353.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V353.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V353.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Evergreen.V353.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Bool Evergreen.V353.ChannelName.ChannelName (Evergreen.V353.Discord.OptionalData (Maybe String)) (List Evergreen.V353.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
        (Evergreen.V353.NonemptyDict.NonemptyDict
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) Evergreen.V353.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Evergreen.V353.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Maybe (Evergreen.V353.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V353.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V353.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V353.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V353.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V353.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V353.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (Evergreen.V353.Discord.OptionalData String) (Evergreen.V353.Discord.OptionalData (Maybe String)) (List Evergreen.V353.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId) Evergreen.V353.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
        (Evergreen.V353.MembersAndOwner.MembersAndOwner
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Evergreen.V353.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId) Evergreen.V353.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId) Evergreen.V353.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V353.Call.ServerChange
    | Server_Game (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Game.LocalChange
    | Server_Drawing (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Drawing.AnchorType Evergreen.V353.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V353.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V353.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V353.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V353.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V353.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V353.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V353.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V353.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V353.Id.AnyGuildOrDmId Evergreen.V353.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V353.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels) (Maybe Evergreen.V353.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V353.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V353.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V353.Local.Local LocalMsg Evergreen.V353.LocalState.LocalState
    , admin : Evergreen.V353.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V353.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V353.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V353.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V353.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V353.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.ThreadRoute ) (Evergreen.V353.NonemptyDict.NonemptyDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V353.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V353.Scroll.ScrollPosition
    , textEditor : Evergreen.V353.TextEditor.Model
    , profilePictureEditor : Evergreen.V353.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId, Evergreen.V353.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V353.Emoji.Model
    , voiceChat : Evergreen.V353.Call.Model
    , games : SeqDict.SeqDict Evergreen.V353.Id.GuildOrDmId Evergreen.V353.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V353.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V353.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V353.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V353.Range.Range
                , direction : Evergreen.V353.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V353.NonemptyDict.NonemptyDict Int Evergreen.V353.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V353.NonemptyDict.NonemptyDict Int Evergreen.V353.Touch.Touch
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
    | AdminToFrontend Evergreen.V353.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V353.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V353.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V353.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V353.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V353.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V353.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V353.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V353.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V353.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V353.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V353.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V353.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V353.Audio.LoadError Evergreen.V353.Audio.Source
    , startupData : Evergreen.V353.Ports.StartupData
    , routeRequestCausedByPressingLink : Bool
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V353.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V353.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V353.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V353.FileStatus.FileHash
    , metadata : Maybe Evergreen.V353.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId, Evergreen.V353.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V353.DmChannelId.DmChannelId, Evergreen.V353.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId, Evergreen.V353.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId, Evergreen.V353.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V353.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias CountToFrontendState =
    { count : Int
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V353.NonemptyDict.NonemptyDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V353.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V353.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V353.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V353.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V353.DmChannelId.DmChannelId Evergreen.V353.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) Evergreen.V353.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.Slack.Id Evergreen.V353.Slack.ChannelId) Evergreen.V353.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V353.OneToOne.OneToOne String (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    , slackUsers : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.Slack.Id Evergreen.V353.Slack.UserId) (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    , slackServers : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.Slack.Id Evergreen.V353.Slack.TeamId) (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    , slackToken : Maybe Evergreen.V353.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V353.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V353.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V353.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V353.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Evergreen.V353.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId, Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V353.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V353.Id.Viewing_DiscordDmId ( Effect.Lamdera.ClientId, Evergreen.V353.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V353.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.LocalState.LoadingDiscordChannel Evergreen.V353.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , countToFrontendState : Maybe CountToFrontendState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V353.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId) Evergreen.V353.Sticker.StickerData
    , discordStickers : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.Discord.Id Evergreen.V353.Discord.StickerId) (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId) Evergreen.V353.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V353.OneToOne.OneToOne Evergreen.V353.RichText.DiscordCustomEmojiIdAndName (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V353.Postmark.ApiKey
    , serverSecret : Evergreen.V353.SecretId.SecretId Evergreen.V353.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V353.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.GamePublicId) ( Evergreen.V353.DmChannelId.GuildOrFullDmId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V353.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V353.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V353.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.Id.ThreadRoute (Maybe Evergreen.V353.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V353.DmChannelId.DmChannelId Evergreen.V353.Id.ThreadRoute (Maybe Evergreen.V353.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V353.Id.Id Evergreen.V353.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V353.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V353.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V353.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V353.Untrusted.Untrusted Evergreen.V353.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V353.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V353.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V353.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V353.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V353.PersonName.PersonName Evergreen.V353.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V353.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V353.Slack.OAuthCode Evergreen.V353.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V353.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V353.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V353.Id.Id Evergreen.V353.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V353.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V353.EmailAddress.EmailAddress (Result Evergreen.V353.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V353.EmailAddress.EmailAddress (Result Evergreen.V353.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V353.EmailAddress.EmailAddress (Result Evergreen.V353.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V353.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMaybeMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Result Evergreen.V353.Discord.HttpError Evergreen.V353.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V353.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Result Evergreen.V353.Discord.HttpError Evergreen.V353.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) (Result Evergreen.V353.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) (Result Evergreen.V353.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) (Result Evergreen.V353.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) (Result Evergreen.V353.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji (Result Evergreen.V353.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji (Result Evergreen.V353.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji (Result Evergreen.V353.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji (Result Evergreen.V353.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V353.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V353.Discord.HttpError (List ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId, Maybe Evergreen.V353.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Effect.Time.Posix Evergreen.V353.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V353.Slack.CurrentUser
            , team : Evergreen.V353.Slack.Team
            , users : List Evergreen.V353.Slack.User
            , channels : List ( Evergreen.V353.Slack.Channel, List Evergreen.V353.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Result Effect.Http.Error Evergreen.V353.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Discord.UserAuth (Result Evergreen.V353.Discord.HttpError Evergreen.V353.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Result Evergreen.V353.Discord.HttpError Evergreen.V353.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
        (Result
            Evergreen.V353.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId
                , members : List (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
                }
            , List
                ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId
                , { guild : Evergreen.V353.Discord.GatewayGuild
                  , channels : List Evergreen.V353.Discord.Channel
                  , icon : Maybe Evergreen.V353.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Maybe String) Evergreen.V353.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V353.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.AttachmentId, Evergreen.V353.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V353.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.AttachmentId, Evergreen.V353.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V353.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V353.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V353.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V353.FileStatus.UploadResponse )))
    | ExportBackendStep
    | CountToFrontendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (Result Evergreen.V353.Discord.HttpError Evergreen.V353.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Result Evergreen.V353.Discord.HttpError (List Evergreen.V353.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V353.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V353.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V353.DmChannelId.DmChannelId Evergreen.V353.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V353.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V353.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V353.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
        (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V353.Discord.HttpError
            { guild : Evergreen.V353.Discord.GatewayGuild
            , channels : List Evergreen.V353.Discord.Channel
            , icon : Maybe Evergreen.V353.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Result Evergreen.V353.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V353.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (List ( Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId, Result Effect.Http.Error Evergreen.V353.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId, Result Effect.Http.Error Evergreen.V353.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (List ( Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V353.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V353.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V353.Discord.HttpError (List Evergreen.V353.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V353.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V353.SecretId.SecretId Evergreen.V353.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V353.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Result Evergreen.V353.Discord.HttpError ( Evergreen.V353.Discord.Guild, List Evergreen.V353.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V353.FileStatus.FileHash Int (Maybe (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Call.CallId
