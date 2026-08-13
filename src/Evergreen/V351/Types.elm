module Evergreen.V351.Types exposing (..)

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
import Evergreen.V351.AiChat
import Evergreen.V351.Audio
import Evergreen.V351.Call
import Evergreen.V351.ChannelDescription
import Evergreen.V351.ChannelName
import Evergreen.V351.Coord
import Evergreen.V351.CssPixels
import Evergreen.V351.CustomEmoji
import Evergreen.V351.Discord
import Evergreen.V351.DiscordAttachmentId
import Evergreen.V351.DiscordUserData
import Evergreen.V351.DmChannel
import Evergreen.V351.DmChannelId
import Evergreen.V351.Drawing
import Evergreen.V351.Editable
import Evergreen.V351.EmailAddress
import Evergreen.V351.Embed
import Evergreen.V351.Emoji
import Evergreen.V351.FileStatus
import Evergreen.V351.Game
import Evergreen.V351.Go
import Evergreen.V351.GuildName
import Evergreen.V351.Id
import Evergreen.V351.ImageEditor
import Evergreen.V351.ImageViewer
import Evergreen.V351.LinkedAndOtherDiscordUsers
import Evergreen.V351.Local
import Evergreen.V351.LocalState
import Evergreen.V351.Log
import Evergreen.V351.LoginForm
import Evergreen.V351.MembersAndOwner
import Evergreen.V351.Message
import Evergreen.V351.MessageInput
import Evergreen.V351.MessageView
import Evergreen.V351.MuteSettings
import Evergreen.V351.MyUi
import Evergreen.V351.NonemptyDict
import Evergreen.V351.NonemptySet
import Evergreen.V351.OneOrGreater
import Evergreen.V351.OneToOne
import Evergreen.V351.Pages.Admin
import Evergreen.V351.Pagination
import Evergreen.V351.PersonName
import Evergreen.V351.Ports
import Evergreen.V351.Postmark
import Evergreen.V351.Range
import Evergreen.V351.RecoveryLogin
import Evergreen.V351.RichText
import Evergreen.V351.Route
import Evergreen.V351.Scroll
import Evergreen.V351.SecretId
import Evergreen.V351.SessionIdHash
import Evergreen.V351.Slack
import Evergreen.V351.Sticker
import Evergreen.V351.TextEditor
import Evergreen.V351.ToBackendLog
import Evergreen.V351.Touch
import Evergreen.V351.TwoFactorAuthentication
import Evergreen.V351.Ui.Anim
import Evergreen.V351.Untrusted
import Evergreen.V351.User
import Evergreen.V351.UserAgent
import Evergreen.V351.UserSession
import Evergreen.V351.WordSpellingGame
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
    | LoginFormMsg Evergreen.V351.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V351.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V351.Pages.Admin.Msg
    | PressedLogOut Evergreen.V351.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V351.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V351.Route.Route
    | SelectedFilesToAttach ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V351.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V351.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V351.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V351.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V351.NonemptyDict.NonemptyDict Int Evergreen.V351.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V351.NonemptyDict.NonemptyDict Int Evergreen.V351.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRoute Evergreen.V351.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V351.NonemptySet.NonemptySet (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId))
    | MessageMenu_PressedOpenDm (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    | MessageMenu_PressedOpenDiscordDm (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V351.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V351.AiChat.Msg
    | GameMsg Evergreen.V351.Game.Msg
    | GoSpectatorMsg Evergreen.V351.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V351.Editable.Msg Evergreen.V351.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V351.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V351.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute )
        { fileId : Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute )
        { fileId : Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V351.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage Evergreen.V351.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V351.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V351.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V351.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V351.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.User.NotificationLevel
    | GotStartupData (Result String Evergreen.V351.Ports.StartupData)
    | GotDevicePixelRatio Float
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V351.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V351.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId
        , otherUserId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRoute Evergreen.V351.MessageInput.Msg
    | MessageInputMsg Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRoute Evergreen.V351.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V351.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V351.Range.Range, Evergreen.V351.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V351.Range.Range, Evergreen.V351.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V351.Call.FromJs)
    | VoiceChatMsg Evergreen.V351.Call.Msg
    | PressedChannelHeaderTab Evergreen.V351.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V351.Drawing.Msg
    | PressedNewMessagesWarning
    | LoadedPopSound (Result Evergreen.V351.Audio.LoadError Evergreen.V351.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch
    | PressedMuteChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.MuteSettings.IsMuted
    | PressedMuteThread (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.MuteSettings.IsMuted
    | PressedMuteDiscordChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.MuteSettings.IsMuted
    | PressedMuteDiscordThread (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.MuteSettings.IsMuted
    | PressedMarkChannelAsRead Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | PressedMarkAllChannelsAsRead (List ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRouteWithMessage ))
    | PressedMuteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.MuteSettings.IsMuted
    | PressedMuteDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.MuteSettings.IsMuted
    | UnreadOverviewChannelMsg Evergreen.V351.Id.AnyGuildOrDmId (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.MessageView.MessageViewMsg
    | UnreadOverviewThreadMsg Evergreen.V351.Id.AnyGuildOrDmId (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) Evergreen.V351.MessageView.MessageViewMsg


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V351.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V351.UserSession.UserSession
    , currentlyViewing : Evergreen.V351.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) Evergreen.V351.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.LocalState.DiscordFrontendGuild
    , user : Evergreen.V351.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.User.FrontendUser
    , discordUsers : Evergreen.V351.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V351.SessionIdHash.SessionIdHash Evergreen.V351.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V351.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId) Evergreen.V351.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId) Evergreen.V351.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V351.Call.CallId (Evergreen.V351.NonemptyDict.NonemptyDict ( Evergreen.V351.Id.Id Evergreen.V351.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V351.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V351.Go.PublicGoMatchData Evergreen.V351.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V351.Route.Route
    , windowSize : Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , startupData : Maybe Evergreen.V351.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V351.Audio.LoadError Evergreen.V351.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V351.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V351.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V351.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileData) (List Evergreen.V351.Emoji.EmojiOrCustomEmoji)
    | Local_Discord_SendMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V351.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V351.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.ChannelName.ChannelName Evergreen.V351.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.ChannelName.ChannelName Evergreen.V351.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V351.GuildName.GuildName (Evergreen.V351.UserSession.ToBeFilledInByBackend (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix Effect.Time.Zone (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Effect.Time.Zone Evergreen.V351.Id.DiscordGuildOrDmId_DmData (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V351.UserSession.SetViewing
    | Local_SetName Evergreen.V351.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V351.Id.GuildOrDmId (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V351.Id.GuildOrDmId (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V351.Id.DiscordGuildOrDmId (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V351.Id.DiscordGuildOrDmId (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V351.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V351.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V351.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V351.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V351.RichText.Domain
    | Local_SetEmojiSkinTone (Maybe Evergreen.V351.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V351.NonemptySet.NonemptySet (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V351.Call.LocalChange
    | Local_Game Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Game.LocalChange
    | Local_Drawing Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Drawing.AnchorType Evergreen.V351.Drawing.LocalChange
    | Local_SetMuteChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.MuteSettings.IsMuted
    | Local_SetMuteThread (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.MuteSettings.IsMuted
    | Local_SetMuteDiscordChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.MuteSettings.IsMuted
    | Local_SetMuteDiscordThread (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.MuteSettings.IsMuted
    | Local_SetMuteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.MuteSettings.IsMuted
    | Local_SetMuteDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.MuteSettings.IsMuted


type ServerChange
    = Server_SendMessage (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.User.FrontendUser Effect.Time.Posix Evergreen.V351.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V351.RichText.RichText (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))) Evergreen.V351.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId) Evergreen.V351.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V351.Id.DiscordGuildOrDmId Evergreen.V351.UserSession.DiscordFrontendUser (List.Nonempty.Nonempty (Evergreen.V351.RichText.RichText (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))) Evergreen.V351.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId) Evergreen.V351.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.ChannelName.ChannelName Evergreen.V351.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.ChannelName.ChannelName Evergreen.V351.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V351.LocalState.JoinGuildError
            { guildId : Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId
            , guild : Evergreen.V351.LocalState.FrontendGuild
            , owner : Evergreen.V351.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V351.RichText.RichText (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V351.RichText.RichText (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V351.Id.DiscordGuildOrDmId_DmData (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V351.RichText.RichText (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage
    | Server_DiscordForumPostDeleted (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | Server_DiscordDeleteDmMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Maybe Evergreen.V351.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Maybe Evergreen.V351.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V351.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V351.SessionIdHash.SessionIdHash Evergreen.V351.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V351.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V351.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V351.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V351.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V351.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Evergreen.V351.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Bool Evergreen.V351.ChannelName.ChannelName (Evergreen.V351.Discord.OptionalData (Maybe String)) (List Evergreen.V351.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
        (Evergreen.V351.NonemptyDict.NonemptyDict
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) Evergreen.V351.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Evergreen.V351.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Maybe (Evergreen.V351.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V351.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V351.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V351.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V351.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V351.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V351.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Discord.OptionalData String) (Evergreen.V351.Discord.OptionalData (Maybe String)) (List Evergreen.V351.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId) Evergreen.V351.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
        (Evergreen.V351.MembersAndOwner.MembersAndOwner
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Evergreen.V351.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId) Evergreen.V351.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId) Evergreen.V351.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V351.Call.ServerChange
    | Server_Game (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Game.LocalChange
    | Server_Drawing (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Drawing.AnchorType Evergreen.V351.Drawing.LocalChange
    | Server_SetMuteChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.MuteSettings.IsMuted
    | Server_SetMuteThread (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.MuteSettings.IsMuted
    | Server_SetMuteDiscordChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.MuteSettings.IsMuted
    | Server_SetMuteDiscordThread (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.MuteSettings.IsMuted
    | Server_SetMuteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.MuteSettings.IsMuted
    | Server_SetMuteDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.MuteSettings.IsMuted


type LocalMsg
    = LocalChange (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V351.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V351.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V351.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V351.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V351.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V351.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V351.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V351.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V351.Id.AnyGuildOrDmId Evergreen.V351.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V351.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels) (Maybe Evergreen.V351.Range.Range)


type alias RevealedSpoilers =
    { messages : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V351.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V351.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V351.Local.Local LocalMsg Evergreen.V351.LocalState.LocalState
    , admin : Evergreen.V351.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V351.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V351.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    , revealedSpoilers : SeqDict.SeqDict Evergreen.V351.Id.AnyGuildOrDmId RevealedSpoilers
    , sidebarMode : Evergreen.V351.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V351.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.ThreadRoute ) (Evergreen.V351.NonemptyDict.NonemptyDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V351.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V351.Scroll.ScrollPosition
    , textEditor : Evergreen.V351.TextEditor.Model
    , profilePictureEditor : Evergreen.V351.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId, Evergreen.V351.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V351.Emoji.Model
    , voiceChat : Evergreen.V351.Call.Model
    , games : SeqDict.SeqDict Evergreen.V351.Id.GuildOrDmId Evergreen.V351.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V351.Drawing.Model
    , newMessagesWhileNotScrolledToBottom : Int
    , showInviteLinkQrCode : Maybe (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V351.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V351.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V351.Range.Range
                , direction : Evergreen.V351.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V351.NonemptyDict.NonemptyDict Int Evergreen.V351.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V351.NonemptyDict.NonemptyDict Int Evergreen.V351.Touch.Touch
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
    | AdminToFrontend Evergreen.V351.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V351.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V351.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V351.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V351.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V351.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V351.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V351.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V351.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V351.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V351.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V351.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V351.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V351.Audio.LoadError Evergreen.V351.Audio.Source
    , startupData : Evergreen.V351.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V351.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V351.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V351.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V351.FileStatus.FileHash
    , metadata : Maybe Evergreen.V351.FileStatus.FileMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId, Evergreen.V351.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V351.DmChannelId.DmChannelId, Evergreen.V351.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId, Evergreen.V351.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId, Evergreen.V351.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V351.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V351.NonemptyDict.NonemptyDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V351.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V351.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V351.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V351.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V351.DmChannelId.DmChannelId Evergreen.V351.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) Evergreen.V351.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.Slack.Id Evergreen.V351.Slack.ChannelId) Evergreen.V351.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V351.OneToOne.OneToOne String (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    , slackUsers : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.Slack.Id Evergreen.V351.Slack.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    , slackServers : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.Slack.Id Evergreen.V351.Slack.TeamId) (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    , slackToken : Maybe Evergreen.V351.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V351.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V351.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V351.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V351.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Evergreen.V351.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId, Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V351.Local.ChangeId, Effect.Time.Zone )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V351.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V351.Local.ChangeId, Effect.Time.Zone )
    , discordAttachments : SeqDict.SeqDict Evergreen.V351.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.LocalState.LoadingDiscordChannel Evergreen.V351.LocalState.DiscordChannelReload)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V351.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId) Evergreen.V351.Sticker.StickerData
    , discordStickers : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.Discord.Id Evergreen.V351.Discord.StickerId) (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId) Evergreen.V351.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V351.OneToOne.OneToOne Evergreen.V351.RichText.DiscordCustomEmojiIdAndName (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V351.Postmark.ApiKey
    , serverSecret : Evergreen.V351.SecretId.SecretId Evergreen.V351.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V351.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.GamePublicId) ( Evergreen.V351.DmChannelId.GuildOrFullDmId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V351.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V351.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V351.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.Id.ThreadRoute (Maybe Evergreen.V351.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V351.DmChannelId.DmChannelId Evergreen.V351.Id.ThreadRoute (Maybe Evergreen.V351.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V351.Id.Id Evergreen.V351.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V351.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V351.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V351.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V351.Untrusted.Untrusted Evergreen.V351.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V351.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V351.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V351.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V351.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V351.PersonName.PersonName Evergreen.V351.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V351.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V351.Slack.OAuthCode Evergreen.V351.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V351.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V351.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V351.Id.Id Evergreen.V351.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V351.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V351.EmailAddress.EmailAddress (Result Evergreen.V351.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V351.EmailAddress.EmailAddress (Result Evergreen.V351.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V351.EmailAddress.EmailAddress (Result Evergreen.V351.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V351.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMaybeMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Result Evergreen.V351.Discord.HttpError Evergreen.V351.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V351.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Result Evergreen.V351.Discord.HttpError Evergreen.V351.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) (Result Evergreen.V351.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) (Result Evergreen.V351.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) (Result Evergreen.V351.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) (Result Evergreen.V351.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji (Result Evergreen.V351.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji (Result Evergreen.V351.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji (Result Evergreen.V351.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji (Result Evergreen.V351.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V351.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V351.Discord.HttpError (List ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId, Maybe Evergreen.V351.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Effect.Time.Posix Evergreen.V351.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V351.Slack.CurrentUser
            , team : Evergreen.V351.Slack.Team
            , users : List Evergreen.V351.Slack.User
            , channels : List ( Evergreen.V351.Slack.Channel, List Evergreen.V351.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Result Effect.Http.Error Evergreen.V351.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Discord.UserAuth (Result Evergreen.V351.Discord.HttpError Evergreen.V351.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Result Evergreen.V351.Discord.HttpError Evergreen.V351.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
        (Result
            Evergreen.V351.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId
                , members : List (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
                }
            , List
                ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId
                , { guild : Evergreen.V351.Discord.GatewayGuild
                  , channels : List Evergreen.V351.Discord.Channel
                  , icon : Maybe Evergreen.V351.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Maybe String) Evergreen.V351.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V351.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.AttachmentId, Evergreen.V351.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V351.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.AttachmentId, Evergreen.V351.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V351.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V351.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V351.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V351.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Result Evergreen.V351.Discord.HttpError Evergreen.V351.LocalState.DiscordChannelReload)
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Result Evergreen.V351.Discord.HttpError (List Evergreen.V351.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotTimeForDiscordForumPostRenamed Evergreen.V351.Discord.Channel Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V351.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V351.DmChannelId.DmChannelId Evergreen.V351.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V351.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V351.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V351.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
        (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V351.Discord.HttpError
            { guild : Evergreen.V351.Discord.GatewayGuild
            , channels : List Evergreen.V351.Discord.Channel
            , icon : Maybe Evergreen.V351.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Result Evergreen.V351.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V351.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (List ( Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId, Result Effect.Http.Error Evergreen.V351.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId, Result Effect.Http.Error Evergreen.V351.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (List ( Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V351.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V351.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V351.Discord.HttpError (List Evergreen.V351.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V351.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V351.SecretId.SecretId Evergreen.V351.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V351.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Result Evergreen.V351.Discord.HttpError ( Evergreen.V351.Discord.Guild, List Evergreen.V351.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | Rpc_GotFileUpload Evergreen.V351.FileStatus.FileHash Int (Maybe (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
    | Rpc_UserJoinedCall Effect.Time.Posix Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Call.CallId
