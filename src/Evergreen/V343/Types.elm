module Evergreen.V343.Types exposing (..)

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
import Evergreen.V343.AiChat
import Evergreen.V343.Audio
import Evergreen.V343.Call
import Evergreen.V343.ChannelDescription
import Evergreen.V343.ChannelName
import Evergreen.V343.Cloudflare
import Evergreen.V343.Coord
import Evergreen.V343.CssPixels
import Evergreen.V343.CustomEmoji
import Evergreen.V343.Discord
import Evergreen.V343.DiscordAttachmentId
import Evergreen.V343.DiscordUserData
import Evergreen.V343.DmChannel
import Evergreen.V343.DmChannelId
import Evergreen.V343.Drawing
import Evergreen.V343.Editable
import Evergreen.V343.EmailAddress
import Evergreen.V343.Embed
import Evergreen.V343.Emoji
import Evergreen.V343.FileStatus
import Evergreen.V343.Game
import Evergreen.V343.Go
import Evergreen.V343.GuildName
import Evergreen.V343.Id
import Evergreen.V343.ImageEditor
import Evergreen.V343.ImageViewer
import Evergreen.V343.LinkedAndOtherDiscordUsers
import Evergreen.V343.Local
import Evergreen.V343.LocalState
import Evergreen.V343.Log
import Evergreen.V343.LoginForm
import Evergreen.V343.MembersAndOwner
import Evergreen.V343.Message
import Evergreen.V343.MessageInput
import Evergreen.V343.MessageView
import Evergreen.V343.MuteSettings
import Evergreen.V343.MyUi
import Evergreen.V343.NonemptyDict
import Evergreen.V343.NonemptySet
import Evergreen.V343.OneOrGreater
import Evergreen.V343.OneToOne
import Evergreen.V343.Pages.Admin
import Evergreen.V343.Pagination
import Evergreen.V343.PersonName
import Evergreen.V343.Ports
import Evergreen.V343.Postmark
import Evergreen.V343.Range
import Evergreen.V343.RecoveryLogin
import Evergreen.V343.RichText
import Evergreen.V343.Route
import Evergreen.V343.Scroll
import Evergreen.V343.SecretId
import Evergreen.V343.SessionIdHash
import Evergreen.V343.Slack
import Evergreen.V343.Sticker
import Evergreen.V343.TextEditor
import Evergreen.V343.ToBackendLog
import Evergreen.V343.Touch
import Evergreen.V343.TwoFactorAuthentication
import Evergreen.V343.Ui.Anim
import Evergreen.V343.Untrusted
import Evergreen.V343.User
import Evergreen.V343.UserAgent
import Evergreen.V343.UserSession
import Evergreen.V343.WordSpellingGame
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
    | LoginFormMsg Evergreen.V343.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V343.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V343.Pages.Admin.Msg
    | PressedLogOut Evergreen.V343.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V343.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V343.Route.Route
    | SelectedFilesToAttach ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V343.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V343.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V343.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V343.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V343.NonemptyDict.NonemptyDict Int Evergreen.V343.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V343.NonemptyDict.NonemptyDict Int Evergreen.V343.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRoute Evergreen.V343.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V343.NonemptySet.NonemptySet (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V343.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V343.AiChat.Msg
    | GameMsg Evergreen.V343.Game.Msg
    | GoSpectatorMsg Evergreen.V343.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V343.Editable.Msg Evergreen.V343.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V343.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V343.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute )
        { fileId : Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute )
        { fileId : Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V343.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage Evergreen.V343.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V343.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V343.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V343.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V343.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.User.NotificationLevel
    | GotStartupData Evergreen.V343.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V343.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V343.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId
        , otherUserId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRoute Evergreen.V343.MessageInput.Msg
    | MessageInputMsg Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRoute Evergreen.V343.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V343.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V343.Range.Range, Evergreen.V343.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V343.Range.Range, Evergreen.V343.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V343.Call.FromJs)
    | VoiceChatMsg Evergreen.V343.Call.Msg
    | PressedChannelHeaderTab Evergreen.V343.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V343.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V343.Audio.LoadError Evergreen.V343.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V343.Id.AnyGuildOrDmId (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V343.Id.AnyGuildOrDmId (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) Evergreen.V343.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V343.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V343.UserSession.UserSession
    , currentlyViewing : Evergreen.V343.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) Evergreen.V343.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.LocalState.DiscordFrontendGuild
    , user : Evergreen.V343.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.User.FrontendUser
    , discordUsers : Evergreen.V343.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V343.SessionIdHash.SessionIdHash Evergreen.V343.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V343.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId) Evergreen.V343.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId) Evergreen.V343.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V343.Call.CallId (Evergreen.V343.NonemptyDict.NonemptyDict ( Evergreen.V343.Id.Id Evergreen.V343.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V343.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V343.Go.PublicGoMatchData Evergreen.V343.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V343.Route.Route
    , windowSize : Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V343.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V343.Audio.LoadError Evergreen.V343.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V343.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V343.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V343.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V343.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V343.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.ChannelName.ChannelName Evergreen.V343.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.ChannelName.ChannelName Evergreen.V343.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.UserSession.ToBeFilledInByBackend (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V343.GuildName.GuildName (Evergreen.V343.UserSession.ToBeFilledInByBackend (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V343.Id.DiscordGuildOrDmId_DmData (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V343.UserSession.SetViewing
    | Local_SetName Evergreen.V343.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V343.Id.GuildOrDmId (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V343.Id.GuildOrDmId (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V343.Id.DiscordGuildOrDmId (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V343.Id.DiscordGuildOrDmId (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V343.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V343.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V343.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V343.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V343.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V343.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V343.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V343.NonemptySet.NonemptySet (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V343.Call.LocalChange
    | Local_Game Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Game.LocalChange
    | Local_Drawing Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Drawing.AnchorType Evergreen.V343.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.User.FrontendUser Effect.Time.Posix Evergreen.V343.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V343.RichText.RichText (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))) Evergreen.V343.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId) Evergreen.V343.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V343.Id.DiscordGuildOrDmId Evergreen.V343.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V343.RichText.RichText (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))) Evergreen.V343.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId) Evergreen.V343.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.ChannelName.ChannelName Evergreen.V343.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.ChannelName.ChannelName Evergreen.V343.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V343.LocalState.JoinGuildError
            { guildId : Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId
            , guild : Evergreen.V343.LocalState.FrontendGuild
            , owner : Evergreen.V343.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V343.RichText.RichText (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V343.RichText.RichText (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V343.Id.DiscordGuildOrDmId_DmData (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V343.RichText.RichText (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Maybe Evergreen.V343.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Maybe Evergreen.V343.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V343.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V343.SessionIdHash.SessionIdHash Evergreen.V343.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V343.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V343.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V343.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V343.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V343.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Evergreen.V343.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.ChannelName.ChannelName (Evergreen.V343.Discord.OptionalData (Maybe String)) (List Evergreen.V343.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)
        (Evergreen.V343.NonemptyDict.NonemptyDict
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) Evergreen.V343.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Evergreen.V343.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Maybe (Evergreen.V343.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V343.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V343.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V343.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V343.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V343.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V343.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Discord.OptionalData String) (Evergreen.V343.Discord.OptionalData (Maybe String)) (List Evergreen.V343.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId) Evergreen.V343.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId)
        (Evergreen.V343.MembersAndOwner.MembersAndOwner
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Evergreen.V343.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId) Evergreen.V343.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId) Evergreen.V343.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V343.Call.ServerChange
    | Server_Game (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Game.LocalChange
    | Server_Drawing (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Drawing.AnchorType Evergreen.V343.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V343.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V343.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V343.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V343.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V343.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V343.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V343.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V343.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V343.Id.AnyGuildOrDmId Evergreen.V343.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V343.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels) (Maybe Evergreen.V343.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V343.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V343.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V343.Local.Local LocalMsg Evergreen.V343.LocalState.LocalState
    , admin : Evergreen.V343.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V343.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V343.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V343.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V343.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V343.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.ThreadRoute ) (Evergreen.V343.NonemptyDict.NonemptyDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V343.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V343.Scroll.ScrollPosition
    , textEditor : Evergreen.V343.TextEditor.Model
    , profilePictureEditor : Evergreen.V343.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId, Evergreen.V343.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V343.Emoji.Model
    , voiceChat : Evergreen.V343.Call.Model
    , games : SeqDict.SeqDict Evergreen.V343.Id.GuildOrDmId Evergreen.V343.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V343.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V343.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V343.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V343.Range.Range
                , direction : Evergreen.V343.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V343.NonemptyDict.NonemptyDict Int Evergreen.V343.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V343.NonemptyDict.NonemptyDict Int Evergreen.V343.Touch.Touch
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
    | AdminToFrontend Evergreen.V343.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V343.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V343.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V343.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V343.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V343.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V343.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V343.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V343.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V343.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V343.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V343.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V343.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V343.Audio.LoadError Evergreen.V343.Audio.Source
    , startupData : Evergreen.V343.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V343.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V343.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V343.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V343.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V343.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId, Evergreen.V343.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V343.DmChannelId.DmChannelId, Evergreen.V343.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId, Evergreen.V343.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId, Evergreen.V343.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V343.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V343.NonemptyDict.NonemptyDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V343.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V343.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V343.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V343.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) Evergreen.V343.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V343.DmChannelId.DmChannelId Evergreen.V343.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) Evergreen.V343.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.Slack.Id Evergreen.V343.Slack.ChannelId) Evergreen.V343.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V343.OneToOne.OneToOne String (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    , slackUsers : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.Slack.Id Evergreen.V343.Slack.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
    , slackServers : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.Slack.Id Evergreen.V343.Slack.TeamId) (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    , slackToken : Maybe Evergreen.V343.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V343.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V343.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V343.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V343.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V343.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V343.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V343.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V343.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Evergreen.V343.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId, Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V343.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V343.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V343.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V343.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.LocalState.LoadingDiscordChannel Evergreen.V343.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V343.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId) Evergreen.V343.Sticker.StickerData
    , discordStickers : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.Discord.Id Evergreen.V343.Discord.StickerId) (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId) Evergreen.V343.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V343.OneToOne.OneToOne Evergreen.V343.RichText.DiscordCustomEmojiIdAndName (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V343.Postmark.ApiKey
    , serverSecret : Evergreen.V343.SecretId.SecretId Evergreen.V343.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V343.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.GamePublicId) ( Evergreen.V343.DmChannelId.GuildOrFullDmId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V343.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V343.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V343.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.Id.ThreadRoute (Maybe Evergreen.V343.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V343.DmChannelId.DmChannelId Evergreen.V343.Id.ThreadRoute (Maybe Evergreen.V343.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V343.Id.Id Evergreen.V343.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V343.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V343.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V343.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V343.Untrusted.Untrusted Evergreen.V343.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V343.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V343.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V343.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V343.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V343.PersonName.PersonName Evergreen.V343.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V343.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V343.Slack.OAuthCode Evergreen.V343.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V343.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V343.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V343.Id.Id Evergreen.V343.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V343.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V343.EmailAddress.EmailAddress (Result Evergreen.V343.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V343.EmailAddress.EmailAddress (Result Evergreen.V343.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V343.EmailAddress.EmailAddress (Result Evergreen.V343.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V343.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMaybeMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Result Evergreen.V343.Discord.HttpError Evergreen.V343.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V343.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Result Evergreen.V343.Discord.HttpError Evergreen.V343.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) (Result Evergreen.V343.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) (Result Evergreen.V343.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) (Result Evergreen.V343.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) (Result Evergreen.V343.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji (Result Evergreen.V343.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji (Result Evergreen.V343.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji (Result Evergreen.V343.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji (Result Evergreen.V343.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V343.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V343.Discord.HttpError (List ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId, Maybe Evergreen.V343.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Effect.Time.Posix Evergreen.V343.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V343.Slack.CurrentUser
            , team : Evergreen.V343.Slack.Team
            , users : List Evergreen.V343.Slack.User
            , channels : List ( Evergreen.V343.Slack.Channel, List Evergreen.V343.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Result Effect.Http.Error Evergreen.V343.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V343.Local.ChangeId Effect.Time.Posix Evergreen.V343.Call.CallId Evergreen.V343.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V343.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V343.Local.ChangeId Effect.Time.Posix Evergreen.V343.Call.CallId Evergreen.V343.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V343.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V343.Local.ChangeId Evergreen.V343.Call.ConnectionId Evergreen.V343.Cloudflare.RealtimeSessionId (List Evergreen.V343.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V343.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V343.Local.ChangeId Evergreen.V343.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Discord.UserAuth (Result Evergreen.V343.Discord.HttpError Evergreen.V343.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Result Evergreen.V343.Discord.HttpError Evergreen.V343.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
        (Result
            Evergreen.V343.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId
                , members : List (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
                }
            , List
                ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId
                , { guild : Evergreen.V343.Discord.GatewayGuild
                  , channels : List Evergreen.V343.Discord.Channel
                  , icon : Maybe Evergreen.V343.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Bool Evergreen.V343.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V343.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.AttachmentId, Evergreen.V343.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V343.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.AttachmentId, Evergreen.V343.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V343.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V343.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V343.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V343.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Result Evergreen.V343.Discord.HttpError Evergreen.V343.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Result Evergreen.V343.Discord.HttpError (List Evergreen.V343.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V343.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V343.DmChannelId.DmChannelId Evergreen.V343.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V343.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V343.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V343.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
        (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V343.Discord.HttpError
            { guild : Evergreen.V343.Discord.GatewayGuild
            , channels : List Evergreen.V343.Discord.Channel
            , icon : Maybe Evergreen.V343.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Result Evergreen.V343.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V343.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (List ( Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId, Result Effect.Http.Error Evergreen.V343.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId, Result Effect.Http.Error Evergreen.V343.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (List ( Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V343.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V343.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V343.Discord.HttpError (List Evergreen.V343.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V343.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V343.SecretId.SecretId Evergreen.V343.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V343.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Result Evergreen.V343.Discord.HttpError ( Evergreen.V343.Discord.Guild, List Evergreen.V343.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V343.FileStatus.FileHash Int (Maybe (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
