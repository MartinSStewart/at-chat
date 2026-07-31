module Evergreen.V341.Types exposing (..)

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
import Evergreen.V341.AiChat
import Evergreen.V341.Audio
import Evergreen.V341.Call
import Evergreen.V341.ChannelDescription
import Evergreen.V341.ChannelName
import Evergreen.V341.Cloudflare
import Evergreen.V341.Coord
import Evergreen.V341.CssPixels
import Evergreen.V341.CustomEmoji
import Evergreen.V341.Discord
import Evergreen.V341.DiscordAttachmentId
import Evergreen.V341.DiscordUserData
import Evergreen.V341.DmChannel
import Evergreen.V341.DmChannelId
import Evergreen.V341.Drawing
import Evergreen.V341.Editable
import Evergreen.V341.EmailAddress
import Evergreen.V341.Embed
import Evergreen.V341.Emoji
import Evergreen.V341.FileStatus
import Evergreen.V341.Game
import Evergreen.V341.Go
import Evergreen.V341.GuildName
import Evergreen.V341.Id
import Evergreen.V341.ImageEditor
import Evergreen.V341.ImageViewer
import Evergreen.V341.LinkedAndOtherDiscordUsers
import Evergreen.V341.Local
import Evergreen.V341.LocalState
import Evergreen.V341.Log
import Evergreen.V341.LoginForm
import Evergreen.V341.MembersAndOwner
import Evergreen.V341.Message
import Evergreen.V341.MessageInput
import Evergreen.V341.MessageView
import Evergreen.V341.MuteSettings
import Evergreen.V341.MyUi
import Evergreen.V341.NonemptyDict
import Evergreen.V341.NonemptySet
import Evergreen.V341.OneOrGreater
import Evergreen.V341.OneToOne
import Evergreen.V341.Pages.Admin
import Evergreen.V341.Pagination
import Evergreen.V341.PersonName
import Evergreen.V341.Ports
import Evergreen.V341.Postmark
import Evergreen.V341.Range
import Evergreen.V341.RecoveryLogin
import Evergreen.V341.RichText
import Evergreen.V341.Route
import Evergreen.V341.Scroll
import Evergreen.V341.SecretId
import Evergreen.V341.SessionIdHash
import Evergreen.V341.Slack
import Evergreen.V341.Sticker
import Evergreen.V341.TextEditor
import Evergreen.V341.ToBackendLog
import Evergreen.V341.Touch
import Evergreen.V341.TwoFactorAuthentication
import Evergreen.V341.Ui.Anim
import Evergreen.V341.Untrusted
import Evergreen.V341.User
import Evergreen.V341.UserAgent
import Evergreen.V341.UserSession
import Evergreen.V341.WordSpellingGame
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
    | LoginFormMsg Evergreen.V341.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V341.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V341.Pages.Admin.Msg
    | PressedLogOut Evergreen.V341.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V341.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V341.Route.Route
    | SelectedFilesToAttach ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V341.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V341.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V341.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V341.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V341.NonemptyDict.NonemptyDict Int Evergreen.V341.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V341.NonemptyDict.NonemptyDict Int Evergreen.V341.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRoute Evergreen.V341.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V341.NonemptySet.NonemptySet (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V341.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V341.AiChat.Msg
    | GameMsg Evergreen.V341.Game.Msg
    | GoSpectatorMsg Evergreen.V341.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V341.Editable.Msg Evergreen.V341.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V341.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V341.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute )
        { fileId : Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute )
        { fileId : Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V341.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage Evergreen.V341.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V341.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V341.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V341.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V341.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.User.NotificationLevel
    | GotStartupData Evergreen.V341.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V341.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V341.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId
        , otherUserId : Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRoute Evergreen.V341.MessageInput.Msg
    | MessageInputMsg Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRoute Evergreen.V341.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V341.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V341.Range.Range, Evergreen.V341.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V341.Range.Range, Evergreen.V341.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V341.Call.FromJs)
    | VoiceChatMsg Evergreen.V341.Call.Msg
    | PressedChannelHeaderTab Evergreen.V341.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V341.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V341.Audio.LoadError Evergreen.V341.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.MuteSettings.IsMuted


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V341.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V341.UserSession.UserSession
    , currentlyViewing : Evergreen.V341.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) Evergreen.V341.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.LocalState.DiscordFrontendGuild
    , user : Evergreen.V341.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.User.FrontendUser
    , discordUsers : Evergreen.V341.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V341.SessionIdHash.SessionIdHash Evergreen.V341.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V341.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId) Evergreen.V341.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId) Evergreen.V341.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V341.Call.CallId (Evergreen.V341.NonemptyDict.NonemptyDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V341.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V341.Go.PublicGoMatchData Evergreen.V341.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V341.Route.Route
    , windowSize : Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V341.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V341.Audio.LoadError Evergreen.V341.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V341.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V341.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V341.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V341.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V341.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.ChannelName.ChannelName Evergreen.V341.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.ChannelName.ChannelName Evergreen.V341.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V341.GuildName.GuildName (Evergreen.V341.UserSession.ToBeFilledInByBackend (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V341.Id.DiscordGuildOrDmId_DmData (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V341.UserSession.SetViewing
    | Local_SetName Evergreen.V341.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V341.Id.GuildOrDmId (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V341.Id.GuildOrDmId (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V341.Id.DiscordGuildOrDmId (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V341.Id.DiscordGuildOrDmId (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V341.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V341.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V341.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V341.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V341.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V341.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V341.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V341.NonemptySet.NonemptySet (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V341.Call.LocalChange
    | Local_Game Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Game.LocalChange
    | Local_Drawing Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Drawing.AnchorType Evergreen.V341.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Effect.Time.Posix Evergreen.V341.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V341.RichText.RichText (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))) Evergreen.V341.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId) Evergreen.V341.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V341.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V341.RichText.RichText (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))) Evergreen.V341.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId) Evergreen.V341.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.ChannelName.ChannelName Evergreen.V341.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.ChannelName.ChannelName Evergreen.V341.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V341.LocalState.JoinGuildError
            { guildId : Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId
            , guild : Evergreen.V341.LocalState.FrontendGuild
            , owner : Evergreen.V341.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V341.RichText.RichText (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V341.RichText.RichText (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V341.Id.DiscordGuildOrDmId_DmData (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V341.RichText.RichText (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Maybe Evergreen.V341.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Maybe Evergreen.V341.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V341.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V341.SessionIdHash.SessionIdHash Evergreen.V341.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V341.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V341.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V341.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V341.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V341.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Evergreen.V341.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.ChannelName.ChannelName (Evergreen.V341.Discord.OptionalData (Maybe String)) (List Evergreen.V341.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
        (Evergreen.V341.NonemptyDict.NonemptyDict
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) Evergreen.V341.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Evergreen.V341.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Maybe (Evergreen.V341.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V341.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V341.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V341.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V341.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V341.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V341.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Discord.OptionalData String) (Evergreen.V341.Discord.OptionalData (Maybe String)) (List Evergreen.V341.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId) Evergreen.V341.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
        (Evergreen.V341.MembersAndOwner.MembersAndOwner
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Evergreen.V341.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId) Evergreen.V341.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId) Evergreen.V341.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V341.Call.ServerChange
    | Server_Game (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Game.LocalChange
    | Server_Drawing (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Drawing.AnchorType Evergreen.V341.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V341.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V341.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V341.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V341.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V341.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V341.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V341.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V341.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V341.Id.AnyGuildOrDmId Evergreen.V341.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V341.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels) (Maybe Evergreen.V341.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V341.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V341.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V341.Local.Local LocalMsg Evergreen.V341.LocalState.LocalState
    , admin : Evergreen.V341.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V341.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V341.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V341.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V341.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.ThreadRoute ) (Evergreen.V341.NonemptyDict.NonemptyDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V341.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V341.Scroll.ScrollPosition
    , textEditor : Evergreen.V341.TextEditor.Model
    , profilePictureEditor : Evergreen.V341.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId, Evergreen.V341.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V341.Emoji.Model
    , voiceChat : Evergreen.V341.Call.Model
    , games : SeqDict.SeqDict Evergreen.V341.Id.GuildOrDmId Evergreen.V341.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V341.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V341.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V341.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V341.Range.Range
                , direction : Evergreen.V341.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V341.NonemptyDict.NonemptyDict Int Evergreen.V341.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V341.NonemptyDict.NonemptyDict Int Evergreen.V341.Touch.Touch
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
    | AdminToFrontend Evergreen.V341.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V341.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V341.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V341.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V341.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V341.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V341.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V341.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V341.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V341.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V341.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V341.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V341.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V341.Audio.LoadError Evergreen.V341.Audio.Source
    , startupData : Evergreen.V341.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V341.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V341.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V341.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V341.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V341.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId, Evergreen.V341.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V341.DmChannelId.DmChannelId, Evergreen.V341.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId, Evergreen.V341.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId, Evergreen.V341.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V341.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V341.NonemptyDict.NonemptyDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V341.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V341.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V341.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V341.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V341.DmChannelId.DmChannelId Evergreen.V341.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) Evergreen.V341.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.Slack.Id Evergreen.V341.Slack.ChannelId) Evergreen.V341.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V341.OneToOne.OneToOne String (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    , slackUsers : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.Slack.Id Evergreen.V341.Slack.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    , slackServers : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.Slack.Id Evergreen.V341.Slack.TeamId) (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    , slackToken : Maybe Evergreen.V341.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V341.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V341.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V341.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V341.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V341.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V341.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V341.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V341.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Evergreen.V341.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId, Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V341.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V341.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V341.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V341.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.LocalState.LoadingDiscordChannel (List Evergreen.V341.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V341.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId) Evergreen.V341.Sticker.StickerData
    , discordStickers : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.Discord.Id Evergreen.V341.Discord.StickerId) (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId) Evergreen.V341.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V341.OneToOne.OneToOne Evergreen.V341.RichText.DiscordCustomEmojiIdAndName (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V341.Postmark.ApiKey
    , serverSecret : Evergreen.V341.SecretId.SecretId Evergreen.V341.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V341.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.GamePublicId) ( Evergreen.V341.DmChannelId.GuildOrFullDmId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V341.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V341.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V341.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.Id.ThreadRoute (Maybe Evergreen.V341.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V341.DmChannelId.DmChannelId Evergreen.V341.Id.ThreadRoute (Maybe Evergreen.V341.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V341.Id.Id Evergreen.V341.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V341.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V341.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V341.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V341.Untrusted.Untrusted Evergreen.V341.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V341.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V341.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V341.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V341.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V341.PersonName.PersonName Evergreen.V341.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V341.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V341.Slack.OAuthCode Evergreen.V341.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V341.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V341.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V341.Id.Id Evergreen.V341.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V341.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V341.EmailAddress.EmailAddress (Result Evergreen.V341.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V341.EmailAddress.EmailAddress (Result Evergreen.V341.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V341.EmailAddress.EmailAddress (Result Evergreen.V341.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V341.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMaybeMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Result Evergreen.V341.Discord.HttpError Evergreen.V341.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V341.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Result Evergreen.V341.Discord.HttpError Evergreen.V341.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) (Result Evergreen.V341.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) (Result Evergreen.V341.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) (Result Evergreen.V341.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) (Result Evergreen.V341.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji (Result Evergreen.V341.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji (Result Evergreen.V341.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji (Result Evergreen.V341.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji (Result Evergreen.V341.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V341.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V341.Discord.HttpError (List ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId, Maybe Evergreen.V341.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Effect.Time.Posix Evergreen.V341.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V341.Slack.CurrentUser
            , team : Evergreen.V341.Slack.Team
            , users : List Evergreen.V341.Slack.User
            , channels : List ( Evergreen.V341.Slack.Channel, List Evergreen.V341.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Result Effect.Http.Error Evergreen.V341.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V341.Local.ChangeId Effect.Time.Posix Evergreen.V341.Call.CallId Evergreen.V341.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V341.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V341.Local.ChangeId Effect.Time.Posix Evergreen.V341.Call.CallId Evergreen.V341.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V341.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V341.Local.ChangeId Evergreen.V341.Call.ConnectionId Evergreen.V341.Cloudflare.RealtimeSessionId (List Evergreen.V341.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V341.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V341.Local.ChangeId Evergreen.V341.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Discord.UserAuth (Result Evergreen.V341.Discord.HttpError Evergreen.V341.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Result Evergreen.V341.Discord.HttpError Evergreen.V341.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
        (Result
            Evergreen.V341.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId
                , members : List (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
                }
            , List
                ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId
                , { guild : Evergreen.V341.Discord.GatewayGuild
                  , channels : List Evergreen.V341.Discord.Channel
                  , icon : Maybe Evergreen.V341.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Bool Evergreen.V341.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V341.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.AttachmentId, Evergreen.V341.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V341.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.AttachmentId, Evergreen.V341.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V341.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V341.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V341.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V341.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Result Evergreen.V341.Discord.HttpError (List Evergreen.V341.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Result Evergreen.V341.Discord.HttpError (List Evergreen.V341.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V341.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V341.DmChannelId.DmChannelId Evergreen.V341.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V341.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V341.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V341.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
        (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V341.Discord.HttpError
            { guild : Evergreen.V341.Discord.GatewayGuild
            , channels : List Evergreen.V341.Discord.Channel
            , icon : Maybe Evergreen.V341.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Result Evergreen.V341.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V341.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (List ( Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId, Result Effect.Http.Error Evergreen.V341.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId, Result Effect.Http.Error Evergreen.V341.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (List ( Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V341.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V341.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V341.Discord.HttpError (List Evergreen.V341.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V341.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V341.SecretId.SecretId Evergreen.V341.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V341.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Result Evergreen.V341.Discord.HttpError ( Evergreen.V341.Discord.Guild, List Evergreen.V341.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V341.FileStatus.FileHash Int (Maybe (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
