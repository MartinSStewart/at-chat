module Evergreen.V339.Types exposing (..)

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
import Evergreen.V339.AiChat
import Evergreen.V339.Audio
import Evergreen.V339.Call
import Evergreen.V339.ChannelDescription
import Evergreen.V339.ChannelName
import Evergreen.V339.Cloudflare
import Evergreen.V339.Coord
import Evergreen.V339.CssPixels
import Evergreen.V339.CustomEmoji
import Evergreen.V339.Discord
import Evergreen.V339.DiscordAttachmentId
import Evergreen.V339.DiscordUserData
import Evergreen.V339.DmChannel
import Evergreen.V339.DmChannelId
import Evergreen.V339.Drawing
import Evergreen.V339.Editable
import Evergreen.V339.EmailAddress
import Evergreen.V339.Embed
import Evergreen.V339.Emoji
import Evergreen.V339.FileStatus
import Evergreen.V339.Game
import Evergreen.V339.Go
import Evergreen.V339.GuildName
import Evergreen.V339.Id
import Evergreen.V339.ImageEditor
import Evergreen.V339.ImageViewer
import Evergreen.V339.LinkedAndOtherDiscordUsers
import Evergreen.V339.Local
import Evergreen.V339.LocalState
import Evergreen.V339.Log
import Evergreen.V339.LoginForm
import Evergreen.V339.MembersAndOwner
import Evergreen.V339.Message
import Evergreen.V339.MessageInput
import Evergreen.V339.MessageView
import Evergreen.V339.MyUi
import Evergreen.V339.NonemptyDict
import Evergreen.V339.NonemptySet
import Evergreen.V339.OneOrGreater
import Evergreen.V339.OneToOne
import Evergreen.V339.Pages.Admin
import Evergreen.V339.Pagination
import Evergreen.V339.PersonName
import Evergreen.V339.Ports
import Evergreen.V339.Postmark
import Evergreen.V339.Range
import Evergreen.V339.RecoveryLogin
import Evergreen.V339.RichText
import Evergreen.V339.Route
import Evergreen.V339.Scroll
import Evergreen.V339.SecretId
import Evergreen.V339.SessionIdHash
import Evergreen.V339.Slack
import Evergreen.V339.Sticker
import Evergreen.V339.TextEditor
import Evergreen.V339.ToBackendLog
import Evergreen.V339.Touch
import Evergreen.V339.TwoFactorAuthentication
import Evergreen.V339.Ui.Anim
import Evergreen.V339.Untrusted
import Evergreen.V339.User
import Evergreen.V339.UserAgent
import Evergreen.V339.UserSession
import Evergreen.V339.WordSpellingGame
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
    | LoginFormMsg Evergreen.V339.LoginForm.Msg
    | RecoveryLoginMsg Evergreen.V339.RecoveryLogin.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V339.Pages.Admin.Msg
    | PressedLogOut Evergreen.V339.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V339.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V339.Route.Route
    | SelectedFilesToAttach ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) NewChannelForm
    | EditChannelFormChanged (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V339.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V339.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V339.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V339.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V339.NonemptyDict.NonemptyDict Int Evergreen.V339.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V339.NonemptyDict.NonemptyDict Int Evergreen.V339.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRoute Evergreen.V339.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V339.NonemptySet.NonemptySet (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V339.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V339.AiChat.Msg
    | GameMsg Evergreen.V339.Game.Msg
    | GoSpectatorMsg Evergreen.V339.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V339.Editable.Msg Evergreen.V339.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V339.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V339.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute )
        { fileId : Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute )
        { fileId : Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V339.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage Evergreen.V339.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V339.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V339.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V339.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V339.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.User.NotificationLevel
    | GotStartupData Evergreen.V339.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V339.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V339.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId
        , otherUserId : Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRoute Evergreen.V339.MessageInput.Msg
    | MessageInputMsg Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRoute Evergreen.V339.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V339.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V339.Range.Range, Evergreen.V339.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V339.Range.Range, Evergreen.V339.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V339.Call.FromJs)
    | VoiceChatMsg Evergreen.V339.Call.Msg
    | PressedChannelHeaderTab Evergreen.V339.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V339.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V339.Audio.LoadError Evergreen.V339.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V339.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V339.UserSession.UserSession
    , currentlyViewing : Evergreen.V339.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) Evergreen.V339.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.LocalState.DiscordFrontendGuild
    , user : Evergreen.V339.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.User.FrontendUser
    , discordUsers : Evergreen.V339.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V339.SessionIdHash.SessionIdHash Evergreen.V339.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V339.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId) Evergreen.V339.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId) Evergreen.V339.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V339.Call.CallId (Evergreen.V339.NonemptyDict.NonemptyDict ( Evergreen.V339.Id.Id Evergreen.V339.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V339.Call.RemoteCallData)
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
    | PublicGoMatch_Loaded Evergreen.V339.Go.PublicGoMatchData Evergreen.V339.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V339.Route.Route
    , windowSize : Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , loginType : LoginType
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V339.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V339.Audio.LoadError Evergreen.V339.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V339.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V339.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V339.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V339.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V339.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.ChannelName.ChannelName Evergreen.V339.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) Evergreen.V339.ChannelName.ChannelName Evergreen.V339.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V339.GuildName.GuildName (Evergreen.V339.UserSession.ToBeFilledInByBackend (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V339.Id.DiscordGuildOrDmId_DmData (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V339.UserSession.SetViewing
    | Local_SetName Evergreen.V339.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V339.Id.GuildOrDmId (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V339.Id.GuildOrDmId (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V339.Id.DiscordGuildOrDmId (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V339.Id.DiscordGuildOrDmId (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V339.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V339.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V339.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V339.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V339.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V339.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V339.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V339.NonemptySet.NonemptySet (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V339.Call.LocalChange
    | Local_Game Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Game.LocalChange
    | Local_Drawing Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Drawing.AnchorType Evergreen.V339.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Effect.Time.Posix Evergreen.V339.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V339.RichText.RichText (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))) Evergreen.V339.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId) Evergreen.V339.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V339.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V339.RichText.RichText (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))) Evergreen.V339.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId) Evergreen.V339.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.ChannelName.ChannelName Evergreen.V339.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) Evergreen.V339.ChannelName.ChannelName Evergreen.V339.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V339.LocalState.JoinGuildError
            { guildId : Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId
            , guild : Evergreen.V339.LocalState.FrontendGuild
            , owner : Evergreen.V339.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V339.RichText.RichText (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))) (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V339.RichText.RichText (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V339.Id.DiscordGuildOrDmId_DmData (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V339.RichText.RichText (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Maybe Evergreen.V339.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Maybe Evergreen.V339.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V339.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V339.SessionIdHash.SessionIdHash Evergreen.V339.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V339.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V339.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V339.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V339.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V339.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Evergreen.V339.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.ChannelName.ChannelName (Evergreen.V339.Discord.OptionalData (Maybe String)) (List Evergreen.V339.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
        (Evergreen.V339.NonemptyDict.NonemptyDict
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) Evergreen.V339.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Evergreen.V339.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Maybe (Evergreen.V339.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V339.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V339.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V339.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V339.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V339.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V339.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (Evergreen.V339.Discord.OptionalData String) (Evergreen.V339.Discord.OptionalData (Maybe String)) (List Evergreen.V339.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId) Evergreen.V339.LocalState.DiscordRole
    | Server_DiscordUpdateGuildCustomEmojis (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId))
    | Server_UpdateDiscordMembers
        (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
        (Evergreen.V339.MembersAndOwner.MembersAndOwner
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Evergreen.V339.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId) Evergreen.V339.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId) Evergreen.V339.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V339.Call.ServerChange
    | Server_Game (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Game.LocalChange
    | Server_Drawing (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Drawing.AnchorType Evergreen.V339.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias EditMessage =
    { messageIndex : Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V339.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V339.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V339.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V339.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V339.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V339.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V339.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V339.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V339.Id.AnyGuildOrDmId Evergreen.V339.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V339.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels) (Maybe Evergreen.V339.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId) (Evergreen.V339.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V339.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V339.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V339.Local.Local LocalMsg Evergreen.V339.LocalState.LocalState
    , admin : Evergreen.V339.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId, Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V339.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V339.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V339.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V339.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.ThreadRoute ) (Evergreen.V339.NonemptyDict.NonemptyDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V339.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V339.Scroll.ScrollPosition
    , textEditor : Evergreen.V339.TextEditor.Model
    , profilePictureEditor : Evergreen.V339.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId, Evergreen.V339.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V339.Emoji.Model
    , voiceChat : Evergreen.V339.Call.Model
    , games : SeqDict.SeqDict Evergreen.V339.Id.GuildOrDmId Evergreen.V339.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V339.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V339.LoginForm.LoginForm
        , recoveryLogin : Evergreen.V339.RecoveryLogin.Model
        , useInviteAfterLoggedIn : Maybe (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V339.Range.Range
                , direction : Evergreen.V339.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V339.NonemptyDict.NonemptyDict Int Evergreen.V339.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V339.NonemptyDict.NonemptyDict Int Evergreen.V339.Touch.Touch
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
    | AdminToFrontend Evergreen.V339.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V339.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V339.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V339.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V339.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V339.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V339.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V339.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , loginType : LoginType
    , elmUiState : Evergreen.V339.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V339.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V339.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V339.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V339.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V339.Audio.LoadError Evergreen.V339.Audio.Source
    , startupData : Evergreen.V339.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V339.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V339.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V339.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V339.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V339.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId, Evergreen.V339.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V339.DmChannelId.DmChannelId, Evergreen.V339.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId, Evergreen.V339.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId, Evergreen.V339.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V339.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V339.NonemptyDict.NonemptyDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V339.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V339.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V339.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V339.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V339.DmChannelId.DmChannelId Evergreen.V339.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) Evergreen.V339.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.Slack.Id Evergreen.V339.Slack.ChannelId) Evergreen.V339.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V339.OneToOne.OneToOne String (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    , slackUsers : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.Slack.Id Evergreen.V339.Slack.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
    , slackServers : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.Slack.Id Evergreen.V339.Slack.TeamId) (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    , slackToken : Maybe Evergreen.V339.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V339.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V339.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V339.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V339.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V339.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V339.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V339.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V339.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Evergreen.V339.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId, Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V339.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V339.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V339.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V339.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.LocalState.LoadingDiscordChannel (List Evergreen.V339.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V339.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId) Evergreen.V339.Sticker.StickerData
    , discordStickers : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.Discord.Id Evergreen.V339.Discord.StickerId) (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId) Evergreen.V339.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V339.OneToOne.OneToOne Evergreen.V339.RichText.DiscordCustomEmojiIdAndName (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V339.Postmark.ApiKey
    , serverSecret : Evergreen.V339.SecretId.SecretId Evergreen.V339.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V339.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.GamePublicId) ( Evergreen.V339.DmChannelId.GuildOrFullDmId, Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V339.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V339.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V339.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) Evergreen.V339.Id.ThreadRoute (Maybe Evergreen.V339.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V339.DmChannelId.DmChannelId Evergreen.V339.Id.ThreadRoute (Maybe Evergreen.V339.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V339.Id.Id Evergreen.V339.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V339.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V339.UserAgent.UserAgent
    | LoginWithRecoveryPasswordRequest InitialLoadRequest String Evergreen.V339.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V339.Untrusted.Untrusted Evergreen.V339.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V339.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V339.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V339.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V339.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V339.PersonName.PersonName Evergreen.V339.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V339.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V339.Slack.OAuthCode Evergreen.V339.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V339.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V339.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V339.Id.Id Evergreen.V339.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V339.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V339.EmailAddress.EmailAddress (Result Evergreen.V339.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V339.EmailAddress.EmailAddress (Result Evergreen.V339.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V339.EmailAddress.EmailAddress (Result Evergreen.V339.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V339.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMaybeMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Result Evergreen.V339.Discord.HttpError Evergreen.V339.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V339.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Result Evergreen.V339.Discord.HttpError Evergreen.V339.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) (Result Evergreen.V339.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) (Result Evergreen.V339.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) (Result Evergreen.V339.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) (Result Evergreen.V339.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji (Result Evergreen.V339.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji (Result Evergreen.V339.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji (Result Evergreen.V339.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji (Result Evergreen.V339.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V339.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V339.Discord.HttpError (List ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId, Maybe Evergreen.V339.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Effect.Time.Posix Evergreen.V339.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V339.Slack.CurrentUser
            , team : Evergreen.V339.Slack.Team
            , users : List Evergreen.V339.Slack.User
            , channels : List ( Evergreen.V339.Slack.Channel, List Evergreen.V339.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Result Effect.Http.Error Evergreen.V339.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V339.Local.ChangeId Effect.Time.Posix Evergreen.V339.Call.CallId Evergreen.V339.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V339.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V339.Local.ChangeId Effect.Time.Posix Evergreen.V339.Call.CallId Evergreen.V339.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V339.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V339.Local.ChangeId Evergreen.V339.Call.ConnectionId Evergreen.V339.Cloudflare.RealtimeSessionId (List Evergreen.V339.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V339.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V339.Local.ChangeId Evergreen.V339.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Discord.UserAuth (Result Evergreen.V339.Discord.HttpError Evergreen.V339.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Result Evergreen.V339.Discord.HttpError Evergreen.V339.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
        (Result
            Evergreen.V339.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId
                , members : List (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
                }
            , List
                ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId
                , { guild : Evergreen.V339.Discord.GatewayGuild
                  , channels : List Evergreen.V339.Discord.Channel
                  , icon : Maybe Evergreen.V339.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Bool Evergreen.V339.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V339.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.AttachmentId, Evergreen.V339.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V339.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.AttachmentId, Evergreen.V339.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V339.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V339.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V339.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V339.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (Result Evergreen.V339.Discord.HttpError (List Evergreen.V339.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Result Evergreen.V339.Discord.HttpError (List Evergreen.V339.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V339.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V339.DmChannelId.DmChannelId Evergreen.V339.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V339.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V339.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V339.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
        (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V339.Discord.HttpError
            { guild : Evergreen.V339.Discord.GatewayGuild
            , channels : List Evergreen.V339.Discord.Channel
            , icon : Maybe Evergreen.V339.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Result Evergreen.V339.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V339.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (List ( Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId, Result Effect.Http.Error Evergreen.V339.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId, Result Effect.Http.Error Evergreen.V339.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (List ( Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V339.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V339.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V339.Discord.HttpError (List Evergreen.V339.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V339.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V339.SecretId.SecretId Evergreen.V339.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V339.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Result Evergreen.V339.Discord.HttpError ( Evergreen.V339.Discord.Guild, List Evergreen.V339.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V339.FileStatus.FileHash Int (Maybe (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
