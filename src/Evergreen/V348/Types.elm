module Evergreen.V348.Types exposing (..)

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
import Evergreen.V348.AiChat
import Evergreen.V348.Audio
import Evergreen.V348.Call
import Evergreen.V348.ChannelDescription
import Evergreen.V348.ChannelName
import Evergreen.V348.Cloudflare
import Evergreen.V348.Coord
import Evergreen.V348.CssPixels
import Evergreen.V348.CustomEmoji
import Evergreen.V348.Discord
import Evergreen.V348.DiscordAttachmentId
import Evergreen.V348.DiscordUserData
import Evergreen.V348.DmChannel
import Evergreen.V348.DmChannelId
import Evergreen.V348.Drawing
import Evergreen.V348.Editable
import Evergreen.V348.EmailAddress
import Evergreen.V348.Embed
import Evergreen.V348.Emoji
import Evergreen.V348.FileStatus
import Evergreen.V348.Game
import Evergreen.V348.Go
import Evergreen.V348.GuildName
import Evergreen.V348.Id
import Evergreen.V348.ImageEditor
import Evergreen.V348.ImageViewer
import Evergreen.V348.LinkedAndOtherDiscordUsers
import Evergreen.V348.Local
import Evergreen.V348.LocalState
import Evergreen.V348.Log
import Evergreen.V348.LoginForm
import Evergreen.V348.MembersAndOwner
import Evergreen.V348.Message
import Evergreen.V348.MessageInput
import Evergreen.V348.MessageView
import Evergreen.V348.MuteSettings
import Evergreen.V348.MyUi
import Evergreen.V348.NonemptyDict
import Evergreen.V348.NonemptySet
import Evergreen.V348.OneOrGreater
import Evergreen.V348.OneToOne
import Evergreen.V348.Pages.Admin
import Evergreen.V348.Pagination
import Evergreen.V348.PersonName
import Evergreen.V348.Ports
import Evergreen.V348.Postmark
import Evergreen.V348.Range
import Evergreen.V348.RecoveryLogin
import Evergreen.V348.RichText
import Evergreen.V348.Route
import Evergreen.V348.Scroll
import Evergreen.V348.SecretId
import Evergreen.V348.SessionIdHash
import Evergreen.V348.Slack
import Evergreen.V348.Sticker
import Evergreen.V348.TextEditor
import Evergreen.V348.ToBackendLog
import Evergreen.V348.Touch
import Evergreen.V348.TwoFactorAuthentication
import Evergreen.V348.Ui.Anim
import Evergreen.V348.Untrusted
import Evergreen.V348.User
import Evergreen.V348.UserAgent
import Evergreen.V348.UserSession
import Evergreen.V348.WordSpellingGame
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
    | LoginFormMsg Evergreen.V348.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V348.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V348.Pages.Admin.Msg
    | PressedLogOut Evergreen.V348.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V348.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V348.Route.Route
    | SelectedFilesToAttach ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V348.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V348.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V348.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V348.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V348.NonemptyDict.NonemptyDict Int Evergreen.V348.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V348.NonemptyDict.NonemptyDict Int Evergreen.V348.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRoute Evergreen.V348.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V348.NonemptySet.NonemptySet (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V348.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V348.AiChat.Msg
    | GameMsg Evergreen.V348.Game.Msg
    | GoSpectatorMsg Evergreen.V348.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V348.Editable.Msg Evergreen.V348.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V348.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V348.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute )
        { fileId : Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute )
        { fileId : Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V348.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage Evergreen.V348.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V348.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V348.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V348.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V348.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V348.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V348.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V348.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId
        , otherUserId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRoute Evergreen.V348.MessageInput.Msg
    | MessageInputMsg Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRoute Evergreen.V348.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V348.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V348.Range.Range, Evergreen.V348.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V348.Range.Range, Evergreen.V348.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V348.Call.FromJs)
    | VoiceChatMsg Evergreen.V348.Call.Msg
    | PressedChannelHeaderTab Evergreen.V348.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V348.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V348.Audio.LoadError Evergreen.V348.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V348.Id.AnyGuildOrDmId (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V348.Id.AnyGuildOrDmId (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) Evergreen.V348.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V348.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V348.UserSession.UserSession
    , currentlyViewing : Evergreen.V348.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) Evergreen.V348.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.LocalState.DiscordFrontendGuild
    , user : Evergreen.V348.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.User.FrontendUser
    , discordUsers : Evergreen.V348.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V348.SessionIdHash.SessionIdHash Evergreen.V348.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V348.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId) Evergreen.V348.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId) Evergreen.V348.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V348.Call.CallId (Evergreen.V348.NonemptyDict.NonemptyDict ( Evergreen.V348.Id.Id Evergreen.V348.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V348.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V348.Go.PublicGoMatchData Evergreen.V348.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V348.Route.Route
    , windowSize : Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V348.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V348.Audio.LoadError Evergreen.V348.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V348.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V348.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V348.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileData) (List Evergreen.V348.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V348.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V348.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.ChannelName.ChannelName Evergreen.V348.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.ChannelName.ChannelName Evergreen.V348.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V348.GuildName.GuildName (Evergreen.V348.UserSession.ToBeFilledInByBackend (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V348.Id.DiscordGuildOrDmId_DmData (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V348.UserSession.SetViewing
    | Local_SetName Evergreen.V348.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V348.Id.GuildOrDmId (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V348.Id.GuildOrDmId (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V348.Id.DiscordGuildOrDmId (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V348.Id.DiscordGuildOrDmId (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V348.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V348.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V348.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V348.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V348.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V348.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V348.NonemptySet.NonemptySet (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V348.Call.LocalChange
    | Local_Game Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Game.LocalChange
    | Local_Drawing Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Drawing.AnchorType Evergreen.V348.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.User.FrontendUser Effect.Time.Posix Evergreen.V348.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V348.RichText.RichText (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))) Evergreen.V348.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId) Evergreen.V348.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V348.Id.DiscordGuildOrDmId Evergreen.V348.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V348.RichText.RichText (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))) Evergreen.V348.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId) Evergreen.V348.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.ChannelName.ChannelName Evergreen.V348.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.ChannelName.ChannelName Evergreen.V348.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V348.LocalState.JoinGuildError
            { guildId : Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId
            , guild : Evergreen.V348.LocalState.FrontendGuild
            , owner : Evergreen.V348.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V348.RichText.RichText (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V348.RichText.RichText (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V348.Id.DiscordGuildOrDmId_DmData (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V348.RichText.RichText (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Maybe Evergreen.V348.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Maybe Evergreen.V348.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V348.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V348.SessionIdHash.SessionIdHash Evergreen.V348.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V348.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V348.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V348.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V348.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V348.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Evergreen.V348.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Bool Evergreen.V348.ChannelName.ChannelName (Evergreen.V348.Discord.OptionalData (Maybe String)) (List Evergreen.V348.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
        (Evergreen.V348.NonemptyDict.NonemptyDict
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) Evergreen.V348.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Evergreen.V348.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Maybe (Evergreen.V348.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V348.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V348.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V348.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V348.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V348.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V348.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Discord.OptionalData String) (Evergreen.V348.Discord.OptionalData (Maybe String)) (List Evergreen.V348.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId) Evergreen.V348.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
        (Evergreen.V348.MembersAndOwner.MembersAndOwner
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Evergreen.V348.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId) Evergreen.V348.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId) Evergreen.V348.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V348.Call.ServerChange
    | Server_Game (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Game.LocalChange
    | Server_Drawing (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Drawing.AnchorType Evergreen.V348.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V348.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V348.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V348.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V348.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V348.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V348.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V348.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V348.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V348.Id.AnyGuildOrDmId Evergreen.V348.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V348.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels) (Maybe Evergreen.V348.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V348.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V348.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V348.Local.Local LocalMsg Evergreen.V348.LocalState.LocalState
    , admin : Evergreen.V348.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V348.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V348.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V348.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V348.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V348.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.ThreadRoute ) (Evergreen.V348.NonemptyDict.NonemptyDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V348.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V348.Scroll.ScrollPosition
    , textEditor : Evergreen.V348.TextEditor.Model
    , profilePictureEditor : Evergreen.V348.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId, Evergreen.V348.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V348.Emoji.Model
    , voiceChat : Evergreen.V348.Call.Model
    , games : SeqDict.SeqDict Evergreen.V348.Id.GuildOrDmId Evergreen.V348.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V348.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V348.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V348.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V348.Range.Range
                , direction : Evergreen.V348.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V348.NonemptyDict.NonemptyDict Int Evergreen.V348.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V348.NonemptyDict.NonemptyDict Int Evergreen.V348.Touch.Touch
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
    | AdminToFrontend Evergreen.V348.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V348.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V348.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V348.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V348.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V348.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V348.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V348.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V348.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V348.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V348.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V348.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V348.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V348.Audio.LoadError Evergreen.V348.Audio.Source
    , startupData : Evergreen.V348.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V348.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V348.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V348.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V348.FileStatus.FileHash
    , metadata : Maybe Evergreen.V348.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId, Evergreen.V348.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V348.DmChannelId.DmChannelId, Evergreen.V348.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId, Evergreen.V348.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId, Evergreen.V348.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V348.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V348.NonemptyDict.NonemptyDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V348.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V348.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V348.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V348.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V348.DmChannelId.DmChannelId Evergreen.V348.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) Evergreen.V348.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.Slack.Id Evergreen.V348.Slack.ChannelId) Evergreen.V348.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V348.OneToOne.OneToOne String (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    , slackUsers : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.Slack.Id Evergreen.V348.Slack.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    , slackServers : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.Slack.Id Evergreen.V348.Slack.TeamId) (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    , slackToken : Maybe Evergreen.V348.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V348.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V348.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V348.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V348.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V348.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V348.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V348.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V348.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Evergreen.V348.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId, Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V348.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V348.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V348.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V348.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.LocalState.LoadingDiscordChannel Evergreen.V348.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V348.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId) Evergreen.V348.Sticker.StickerData
    , discordStickers : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.Discord.Id Evergreen.V348.Discord.StickerId) (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId) Evergreen.V348.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V348.OneToOne.OneToOne Evergreen.V348.RichText.DiscordCustomEmojiIdAndName (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V348.Postmark.ApiKey
    , serverSecret : Evergreen.V348.SecretId.SecretId Evergreen.V348.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V348.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.GamePublicId) ( Evergreen.V348.DmChannelId.GuildOrFullDmId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V348.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V348.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V348.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.Id.ThreadRoute (Maybe Evergreen.V348.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V348.DmChannelId.DmChannelId Evergreen.V348.Id.ThreadRoute (Maybe Evergreen.V348.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V348.Id.Id Evergreen.V348.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V348.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V348.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V348.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V348.Untrusted.Untrusted Evergreen.V348.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V348.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V348.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V348.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V348.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V348.PersonName.PersonName Evergreen.V348.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V348.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V348.Slack.OAuthCode Evergreen.V348.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V348.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V348.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V348.Id.Id Evergreen.V348.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V348.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V348.EmailAddress.EmailAddress (Result Evergreen.V348.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V348.EmailAddress.EmailAddress (Result Evergreen.V348.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V348.EmailAddress.EmailAddress (Result Evergreen.V348.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V348.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMaybeMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Result Evergreen.V348.Discord.HttpError Evergreen.V348.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V348.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Result Evergreen.V348.Discord.HttpError Evergreen.V348.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) (Result Evergreen.V348.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) (Result Evergreen.V348.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) (Result Evergreen.V348.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) (Result Evergreen.V348.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji (Result Evergreen.V348.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji (Result Evergreen.V348.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji (Result Evergreen.V348.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji (Result Evergreen.V348.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V348.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V348.Discord.HttpError (List ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId, Maybe Evergreen.V348.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Effect.Time.Posix Evergreen.V348.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V348.Slack.CurrentUser
            , team : Evergreen.V348.Slack.Team
            , users : List Evergreen.V348.Slack.User
            , channels : List ( Evergreen.V348.Slack.Channel, List Evergreen.V348.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Result Effect.Http.Error Evergreen.V348.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V348.Local.ChangeId Effect.Time.Posix Evergreen.V348.Call.CallId Evergreen.V348.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V348.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V348.Local.ChangeId Effect.Time.Posix Evergreen.V348.Call.CallId Evergreen.V348.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V348.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V348.Local.ChangeId Evergreen.V348.Call.ConnectionId Evergreen.V348.Cloudflare.RealtimeSessionId (List Evergreen.V348.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V348.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V348.Local.ChangeId Evergreen.V348.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Discord.UserAuth (Result Evergreen.V348.Discord.HttpError Evergreen.V348.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Result Evergreen.V348.Discord.HttpError Evergreen.V348.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
        (Result
            Evergreen.V348.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId
                , members : List (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
                }
            , List
                ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId
                , { guild : Evergreen.V348.Discord.GatewayGuild
                  , channels : List Evergreen.V348.Discord.Channel
                  , icon : Maybe Evergreen.V348.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Bool Evergreen.V348.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V348.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.AttachmentId, Evergreen.V348.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V348.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.AttachmentId, Evergreen.V348.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V348.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V348.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V348.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V348.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Result Evergreen.V348.Discord.HttpError Evergreen.V348.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Result Evergreen.V348.Discord.HttpError (List Evergreen.V348.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V348.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V348.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V348.DmChannelId.DmChannelId Evergreen.V348.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V348.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V348.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V348.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
        (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V348.Discord.HttpError
            { guild : Evergreen.V348.Discord.GatewayGuild
            , channels : List Evergreen.V348.Discord.Channel
            , icon : Maybe Evergreen.V348.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Result Evergreen.V348.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V348.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (List ( Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId, Result Effect.Http.Error Evergreen.V348.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId, Result Effect.Http.Error Evergreen.V348.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (List ( Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V348.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V348.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V348.Discord.HttpError (List Evergreen.V348.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V348.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V348.SecretId.SecretId Evergreen.V348.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V348.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Result Evergreen.V348.Discord.HttpError ( Evergreen.V348.Discord.Guild, List Evergreen.V348.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V348.FileStatus.FileHash Int (Maybe (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
