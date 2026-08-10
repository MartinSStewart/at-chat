module Evergreen.V349.Types exposing (..)

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
import Evergreen.V349.AiChat
import Evergreen.V349.Audio
import Evergreen.V349.Call
import Evergreen.V349.ChannelDescription
import Evergreen.V349.ChannelName
import Evergreen.V349.Cloudflare
import Evergreen.V349.Coord
import Evergreen.V349.CssPixels
import Evergreen.V349.CustomEmoji
import Evergreen.V349.Discord
import Evergreen.V349.DiscordAttachmentId
import Evergreen.V349.DiscordUserData
import Evergreen.V349.DmChannel
import Evergreen.V349.DmChannelId
import Evergreen.V349.Drawing
import Evergreen.V349.Editable
import Evergreen.V349.EmailAddress
import Evergreen.V349.Embed
import Evergreen.V349.Emoji
import Evergreen.V349.FileStatus
import Evergreen.V349.Game
import Evergreen.V349.Go
import Evergreen.V349.GuildName
import Evergreen.V349.Id
import Evergreen.V349.ImageEditor
import Evergreen.V349.ImageViewer
import Evergreen.V349.LinkedAndOtherDiscordUsers
import Evergreen.V349.Local
import Evergreen.V349.LocalState
import Evergreen.V349.Log
import Evergreen.V349.LoginForm
import Evergreen.V349.MembersAndOwner
import Evergreen.V349.Message
import Evergreen.V349.MessageInput
import Evergreen.V349.MessageView
import Evergreen.V349.MuteSettings
import Evergreen.V349.MyUi
import Evergreen.V349.NonemptyDict
import Evergreen.V349.NonemptySet
import Evergreen.V349.OneOrGreater
import Evergreen.V349.OneToOne
import Evergreen.V349.Pages.Admin
import Evergreen.V349.Pagination
import Evergreen.V349.PersonName
import Evergreen.V349.Ports
import Evergreen.V349.Postmark
import Evergreen.V349.Range
import Evergreen.V349.RecoveryLogin
import Evergreen.V349.RichText
import Evergreen.V349.Route
import Evergreen.V349.Scroll
import Evergreen.V349.SecretId
import Evergreen.V349.SessionIdHash
import Evergreen.V349.Slack
import Evergreen.V349.Sticker
import Evergreen.V349.TextEditor
import Evergreen.V349.ToBackendLog
import Evergreen.V349.Touch
import Evergreen.V349.TwoFactorAuthentication
import Evergreen.V349.Ui.Anim
import Evergreen.V349.Untrusted
import Evergreen.V349.User
import Evergreen.V349.UserAgent
import Evergreen.V349.UserSession
import Evergreen.V349.WordSpellingGame
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
    | LoginFormMsg Evergreen.V349.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V349.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V349.Pages.Admin.Msg
    | PressedLogOut Evergreen.V349.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V349.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V349.Route.Route
    | SelectedFilesToAttach ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V349.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V349.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V349.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V349.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V349.NonemptyDict.NonemptyDict Int Evergreen.V349.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V349.NonemptyDict.NonemptyDict Int Evergreen.V349.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRoute Evergreen.V349.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V349.NonemptySet.NonemptySet (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V349.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V349.AiChat.Msg
    | GameMsg Evergreen.V349.Game.Msg
    | GoSpectatorMsg Evergreen.V349.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V349.Editable.Msg Evergreen.V349.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V349.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V349.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute )
        { fileId : Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute )
        { fileId : Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V349.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage Evergreen.V349.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V349.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V349.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V349.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V349.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V349.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V349.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V349.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId
        , otherUserId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRoute Evergreen.V349.MessageInput.Msg
    | MessageInputMsg Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRoute Evergreen.V349.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V349.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V349.Range.Range, Evergreen.V349.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V349.Range.Range, Evergreen.V349.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V349.Call.FromJs)
    | VoiceChatMsg Evergreen.V349.Call.Msg
    | PressedChannelHeaderTab Evergreen.V349.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V349.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V349.Audio.LoadError Evergreen.V349.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V349.Id.AnyGuildOrDmId (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V349.Id.AnyGuildOrDmId (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) Evergreen.V349.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V349.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V349.UserSession.UserSession
    , currentlyViewing : Evergreen.V349.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) Evergreen.V349.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.LocalState.DiscordFrontendGuild
    , user : Evergreen.V349.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.User.FrontendUser
    , discordUsers : Evergreen.V349.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V349.SessionIdHash.SessionIdHash Evergreen.V349.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V349.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId) Evergreen.V349.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId) Evergreen.V349.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V349.Call.CallId (Evergreen.V349.NonemptyDict.NonemptyDict ( Evergreen.V349.Id.Id Evergreen.V349.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V349.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V349.Go.PublicGoMatchData Evergreen.V349.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V349.Route.Route
    , windowSize : Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V349.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V349.Audio.LoadError Evergreen.V349.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V349.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V349.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V349.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileData) (List Evergreen.V349.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V349.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V349.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.ChannelName.ChannelName Evergreen.V349.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.ChannelName.ChannelName Evergreen.V349.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V349.GuildName.GuildName (Evergreen.V349.UserSession.ToBeFilledInByBackend (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V349.Id.DiscordGuildOrDmId_DmData (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V349.UserSession.SetViewing
    | Local_SetName Evergreen.V349.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V349.Id.GuildOrDmId (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V349.Id.GuildOrDmId (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V349.Id.DiscordGuildOrDmId (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V349.Id.DiscordGuildOrDmId (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V349.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V349.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V349.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V349.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V349.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V349.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V349.NonemptySet.NonemptySet (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V349.Call.LocalChange
    | Local_Game Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Game.LocalChange
    | Local_Drawing Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Drawing.AnchorType Evergreen.V349.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.User.FrontendUser Effect.Time.Posix Evergreen.V349.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V349.RichText.RichText (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))) Evergreen.V349.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId) Evergreen.V349.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V349.Id.DiscordGuildOrDmId Evergreen.V349.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V349.RichText.RichText (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))) Evergreen.V349.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId) Evergreen.V349.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.ChannelName.ChannelName Evergreen.V349.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.ChannelName.ChannelName Evergreen.V349.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V349.LocalState.JoinGuildError
            { guildId : Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId
            , guild : Evergreen.V349.LocalState.FrontendGuild
            , owner : Evergreen.V349.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V349.RichText.RichText (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V349.RichText.RichText (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V349.Id.DiscordGuildOrDmId_DmData (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V349.RichText.RichText (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Maybe Evergreen.V349.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Maybe Evergreen.V349.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V349.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V349.SessionIdHash.SessionIdHash Evergreen.V349.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V349.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V349.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V349.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V349.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V349.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Evergreen.V349.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Bool Evergreen.V349.ChannelName.ChannelName (Evergreen.V349.Discord.OptionalData (Maybe String)) (List Evergreen.V349.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
        (Evergreen.V349.NonemptyDict.NonemptyDict
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) Evergreen.V349.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Evergreen.V349.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Maybe (Evergreen.V349.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V349.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V349.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V349.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V349.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V349.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V349.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Discord.OptionalData String) (Evergreen.V349.Discord.OptionalData (Maybe String)) (List Evergreen.V349.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId) Evergreen.V349.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
        (Evergreen.V349.MembersAndOwner.MembersAndOwner
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Evergreen.V349.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId) Evergreen.V349.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId) Evergreen.V349.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V349.Call.ServerChange
    | Server_Game (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Game.LocalChange
    | Server_Drawing (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Drawing.AnchorType Evergreen.V349.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V349.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V349.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V349.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V349.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V349.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V349.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V349.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V349.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V349.Id.AnyGuildOrDmId Evergreen.V349.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V349.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels) (Maybe Evergreen.V349.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V349.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V349.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V349.Local.Local LocalMsg Evergreen.V349.LocalState.LocalState
    , admin : Evergreen.V349.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V349.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V349.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V349.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V349.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V349.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.ThreadRoute ) (Evergreen.V349.NonemptyDict.NonemptyDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V349.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V349.Scroll.ScrollPosition
    , textEditor : Evergreen.V349.TextEditor.Model
    , profilePictureEditor : Evergreen.V349.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId, Evergreen.V349.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V349.Emoji.Model
    , voiceChat : Evergreen.V349.Call.Model
    , games : SeqDict.SeqDict Evergreen.V349.Id.GuildOrDmId Evergreen.V349.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V349.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V349.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V349.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V349.Range.Range
                , direction : Evergreen.V349.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V349.NonemptyDict.NonemptyDict Int Evergreen.V349.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V349.NonemptyDict.NonemptyDict Int Evergreen.V349.Touch.Touch
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
    | AdminToFrontend Evergreen.V349.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V349.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V349.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V349.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V349.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V349.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V349.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V349.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V349.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V349.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V349.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V349.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V349.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V349.Audio.LoadError Evergreen.V349.Audio.Source
    , startupData : Evergreen.V349.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V349.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V349.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V349.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V349.FileStatus.FileHash
    , metadata : Maybe Evergreen.V349.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId, Evergreen.V349.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V349.DmChannelId.DmChannelId, Evergreen.V349.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId, Evergreen.V349.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId, Evergreen.V349.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V349.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V349.NonemptyDict.NonemptyDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V349.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V349.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V349.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V349.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V349.DmChannelId.DmChannelId Evergreen.V349.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) Evergreen.V349.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.Slack.Id Evergreen.V349.Slack.ChannelId) Evergreen.V349.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V349.OneToOne.OneToOne String (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    , slackUsers : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.Slack.Id Evergreen.V349.Slack.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    , slackServers : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.Slack.Id Evergreen.V349.Slack.TeamId) (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    , slackToken : Maybe Evergreen.V349.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V349.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V349.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V349.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V349.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V349.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V349.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V349.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V349.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Evergreen.V349.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId, Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V349.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V349.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V349.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V349.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.LocalState.LoadingDiscordChannel Evergreen.V349.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V349.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId) Evergreen.V349.Sticker.StickerData
    , discordStickers : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.Discord.Id Evergreen.V349.Discord.StickerId) (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId) Evergreen.V349.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V349.OneToOne.OneToOne Evergreen.V349.RichText.DiscordCustomEmojiIdAndName (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V349.Postmark.ApiKey
    , serverSecret : Evergreen.V349.SecretId.SecretId Evergreen.V349.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V349.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.GamePublicId) ( Evergreen.V349.DmChannelId.GuildOrFullDmId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V349.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V349.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V349.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.Id.ThreadRoute (Maybe Evergreen.V349.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V349.DmChannelId.DmChannelId Evergreen.V349.Id.ThreadRoute (Maybe Evergreen.V349.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V349.Id.Id Evergreen.V349.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V349.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V349.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V349.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V349.Untrusted.Untrusted Evergreen.V349.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V349.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V349.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V349.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V349.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V349.PersonName.PersonName Evergreen.V349.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V349.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V349.Slack.OAuthCode Evergreen.V349.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V349.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V349.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V349.Id.Id Evergreen.V349.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V349.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V349.EmailAddress.EmailAddress (Result Evergreen.V349.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V349.EmailAddress.EmailAddress (Result Evergreen.V349.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V349.EmailAddress.EmailAddress (Result Evergreen.V349.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V349.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMaybeMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Result Evergreen.V349.Discord.HttpError Evergreen.V349.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V349.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Result Evergreen.V349.Discord.HttpError Evergreen.V349.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) (Result Evergreen.V349.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) (Result Evergreen.V349.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) (Result Evergreen.V349.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) (Result Evergreen.V349.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji (Result Evergreen.V349.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji (Result Evergreen.V349.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji (Result Evergreen.V349.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji (Result Evergreen.V349.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V349.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V349.Discord.HttpError (List ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId, Maybe Evergreen.V349.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Effect.Time.Posix Evergreen.V349.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V349.Slack.CurrentUser
            , team : Evergreen.V349.Slack.Team
            , users : List Evergreen.V349.Slack.User
            , channels : List ( Evergreen.V349.Slack.Channel, List Evergreen.V349.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Result Effect.Http.Error Evergreen.V349.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V349.Local.ChangeId Effect.Time.Posix Evergreen.V349.Call.CallId Evergreen.V349.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V349.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V349.Local.ChangeId Effect.Time.Posix Evergreen.V349.Call.CallId Evergreen.V349.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V349.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V349.Local.ChangeId Evergreen.V349.Call.ConnectionId Evergreen.V349.Cloudflare.RealtimeSessionId (List Evergreen.V349.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V349.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V349.Local.ChangeId Evergreen.V349.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Discord.UserAuth (Result Evergreen.V349.Discord.HttpError Evergreen.V349.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Result Evergreen.V349.Discord.HttpError Evergreen.V349.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
        (Result
            Evergreen.V349.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId
                , members : List (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
                }
            , List
                ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId
                , { guild : Evergreen.V349.Discord.GatewayGuild
                  , channels : List Evergreen.V349.Discord.Channel
                  , icon : Maybe Evergreen.V349.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Bool Evergreen.V349.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V349.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.AttachmentId, Evergreen.V349.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V349.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.AttachmentId, Evergreen.V349.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V349.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V349.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V349.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V349.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Result Evergreen.V349.Discord.HttpError Evergreen.V349.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Result Evergreen.V349.Discord.HttpError (List Evergreen.V349.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V349.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V349.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V349.DmChannelId.DmChannelId Evergreen.V349.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V349.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V349.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V349.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
        (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V349.Discord.HttpError
            { guild : Evergreen.V349.Discord.GatewayGuild
            , channels : List Evergreen.V349.Discord.Channel
            , icon : Maybe Evergreen.V349.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Result Evergreen.V349.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V349.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (List ( Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId, Result Effect.Http.Error Evergreen.V349.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId, Result Effect.Http.Error Evergreen.V349.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (List ( Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V349.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V349.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V349.Discord.HttpError (List Evergreen.V349.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V349.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V349.SecretId.SecretId Evergreen.V349.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V349.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Result Evergreen.V349.Discord.HttpError ( Evergreen.V349.Discord.Guild, List Evergreen.V349.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V349.FileStatus.FileHash Int (Maybe (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
