module Evergreen.V338.Types exposing (..)

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
import Evergreen.V338.AiChat
import Evergreen.V338.Audio
import Evergreen.V338.Call
import Evergreen.V338.ChannelDescription
import Evergreen.V338.ChannelName
import Evergreen.V338.Cloudflare
import Evergreen.V338.Coord
import Evergreen.V338.CssPixels
import Evergreen.V338.CustomEmoji
import Evergreen.V338.Discord
import Evergreen.V338.DiscordAttachmentId
import Evergreen.V338.DiscordUserData
import Evergreen.V338.DmChannel
import Evergreen.V338.DmChannelId
import Evergreen.V338.Drawing
import Evergreen.V338.Editable
import Evergreen.V338.EmailAddress
import Evergreen.V338.Embed
import Evergreen.V338.Emoji
import Evergreen.V338.FileStatus
import Evergreen.V338.Game
import Evergreen.V338.Go
import Evergreen.V338.GuildName
import Evergreen.V338.Id
import Evergreen.V338.ImageEditor
import Evergreen.V338.ImageViewer
import Evergreen.V338.LinkedAndOtherDiscordUsers
import Evergreen.V338.Local
import Evergreen.V338.LocalState
import Evergreen.V338.Log
import Evergreen.V338.LoginForm
import Evergreen.V338.MembersAndOwner
import Evergreen.V338.Message
import Evergreen.V338.MessageInput
import Evergreen.V338.MessageView
import Evergreen.V338.MyUi
import Evergreen.V338.NonemptyDict
import Evergreen.V338.NonemptySet
import Evergreen.V338.OneOrGreater
import Evergreen.V338.OneToOne
import Evergreen.V338.Pages.Admin
import Evergreen.V338.Pagination
import Evergreen.V338.PersonName
import Evergreen.V338.Ports
import Evergreen.V338.Postmark
import Evergreen.V338.Range
import Evergreen.V338.RichText
import Evergreen.V338.Route
import Evergreen.V338.Scroll
import Evergreen.V338.SecretId
import Evergreen.V338.SessionIdHash
import Evergreen.V338.Slack
import Evergreen.V338.Sticker
import Evergreen.V338.TextEditor
import Evergreen.V338.ToBackendLog
import Evergreen.V338.Touch
import Evergreen.V338.TwoFactorAuthentication
import Evergreen.V338.Ui.Anim
import Evergreen.V338.Untrusted
import Evergreen.V338.User
import Evergreen.V338.UserAgent
import Evergreen.V338.UserSession
import Evergreen.V338.WordSpellingGame
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
    | LoginFormMsg Evergreen.V338.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V338.Pages.Admin.Msg
    | PressedLogOut Evergreen.V338.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V338.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V338.Route.Route
    | SelectedFilesToAttach ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V338.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V338.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V338.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V338.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V338.NonemptyDict.NonemptyDict Int Evergreen.V338.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V338.NonemptyDict.NonemptyDict Int Evergreen.V338.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | PressedHideMembers
    | UserScrolled Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRoute Evergreen.V338.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V338.NonemptySet.NonemptySet (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V338.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V338.AiChat.Msg
    | GameMsg Evergreen.V338.Game.Msg
    | GoSpectatorMsg Evergreen.V338.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V338.Editable.Msg Evergreen.V338.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V338.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V338.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute )
        { fileId : Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute )
        { fileId : Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V338.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage Evergreen.V338.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V338.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V338.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V338.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V338.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.User.NotificationLevel
    | GotStartupData Evergreen.V338.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V338.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V338.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId
        , otherUserId : Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRoute Evergreen.V338.MessageInput.Msg
    | MessageInputMsg Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRoute Evergreen.V338.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V338.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V338.Range.Range, Evergreen.V338.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V338.Range.Range, Evergreen.V338.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V338.Call.FromJs)
    | VoiceChatMsg Evergreen.V338.Call.Msg
    | PressedChannelHeaderTab Evergreen.V338.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V338.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V338.Audio.LoadError Evergreen.V338.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V338.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V338.UserSession.UserSession
    , currentlyViewing : Evergreen.V338.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) Evergreen.V338.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.LocalState.DiscordFrontendGuild
    , user : Evergreen.V338.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.User.FrontendUser
    , discordUsers : Evergreen.V338.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V338.SessionIdHash.SessionIdHash Evergreen.V338.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V338.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId) Evergreen.V338.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId) Evergreen.V338.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V338.Call.CallId (Evergreen.V338.NonemptyDict.NonemptyDict ( Evergreen.V338.Id.Id Evergreen.V338.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V338.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V338.Go.PublicGoMatchData Evergreen.V338.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V338.Route.Route
    , windowSize : Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V338.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V338.Audio.LoadError Evergreen.V338.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V338.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V338.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V338.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V338.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V338.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.ChannelName.ChannelName Evergreen.V338.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.ChannelName.ChannelName Evergreen.V338.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V338.GuildName.GuildName (Evergreen.V338.UserSession.ToBeFilledInByBackend (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V338.Id.DiscordGuildOrDmId_DmData (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V338.UserSession.SetViewing
    | Local_SetName Evergreen.V338.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V338.Id.GuildOrDmId (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V338.Id.GuildOrDmId (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V338.Id.DiscordGuildOrDmId (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V338.Id.DiscordGuildOrDmId (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V338.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V338.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V338.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V338.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V338.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V338.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V338.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V338.NonemptySet.NonemptySet (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V338.Call.LocalChange
    | Local_Game Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Game.LocalChange
    | Local_Drawing Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Drawing.AnchorType Evergreen.V338.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Effect.Time.Posix Evergreen.V338.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V338.RichText.RichText (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))) Evergreen.V338.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId) Evergreen.V338.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V338.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V338.RichText.RichText (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))) Evergreen.V338.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId) Evergreen.V338.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.ChannelName.ChannelName Evergreen.V338.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.ChannelName.ChannelName Evergreen.V338.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V338.LocalState.JoinGuildError
            { guildId : Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId
            , guild : Evergreen.V338.LocalState.FrontendGuild
            , owner : Evergreen.V338.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V338.RichText.RichText (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))) (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V338.RichText.RichText (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V338.Id.DiscordGuildOrDmId_DmData (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V338.RichText.RichText (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Maybe Evergreen.V338.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Maybe Evergreen.V338.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V338.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V338.SessionIdHash.SessionIdHash Evergreen.V338.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V338.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V338.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V338.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V338.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V338.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Evergreen.V338.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.ChannelName.ChannelName (Evergreen.V338.Discord.OptionalData (Maybe String)) (List Evergreen.V338.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
        (Evergreen.V338.NonemptyDict.NonemptyDict
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) Evergreen.V338.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Evergreen.V338.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Maybe (Evergreen.V338.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V338.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V338.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V338.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V338.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V338.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V338.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (Evergreen.V338.Discord.OptionalData String) (Evergreen.V338.Discord.OptionalData (Maybe String)) (List Evergreen.V338.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId) Evergreen.V338.LocalState.DiscordRole
    | Server_UpdateDiscordMembers
        (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
        (Evergreen.V338.MembersAndOwner.MembersAndOwner
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Evergreen.V338.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId) Evergreen.V338.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId) Evergreen.V338.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V338.Call.ServerChange
    | Server_Game (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Game.LocalChange
    | Server_Drawing (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Drawing.AnchorType Evergreen.V338.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V338.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V338.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V338.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V338.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V338.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V338.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V338.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V338.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V338.Id.AnyGuildOrDmId Evergreen.V338.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V338.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels) (Maybe Evergreen.V338.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId) (Evergreen.V338.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V338.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V338.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V338.Local.Local LocalMsg Evergreen.V338.LocalState.LocalState
    , admin : Evergreen.V338.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId, Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V338.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V338.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V338.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V338.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.ThreadRoute ) (Evergreen.V338.NonemptyDict.NonemptyDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V338.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V338.Scroll.ScrollPosition
    , textEditor : Evergreen.V338.TextEditor.Model
    , profilePictureEditor : Evergreen.V338.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId, Evergreen.V338.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V338.Emoji.Model
    , voiceChat : Evergreen.V338.Call.Model
    , games : SeqDict.SeqDict Evergreen.V338.Id.GuildOrDmId Evergreen.V338.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V338.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V338.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V338.Range.Range
                , direction : Evergreen.V338.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V338.NonemptyDict.NonemptyDict Int Evergreen.V338.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V338.NonemptyDict.NonemptyDict Int Evergreen.V338.Touch.Touch
        , target : DragTarget
        }


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup


type ToFrontend
    = CheckLoginResponse (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V338.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V338.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V338.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V338.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V338.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V338.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V338.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V338.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V338.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V338.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V338.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V338.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V338.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V338.Audio.LoadError Evergreen.V338.Audio.Source
    , startupData : Evergreen.V338.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V338.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V338.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V338.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V338.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V338.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId, Evergreen.V338.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V338.DmChannelId.DmChannelId, Evergreen.V338.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId, Evergreen.V338.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId, Evergreen.V338.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V338.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V338.NonemptyDict.NonemptyDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V338.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V338.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V338.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V338.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V338.DmChannelId.DmChannelId Evergreen.V338.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) Evergreen.V338.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.Slack.Id Evergreen.V338.Slack.ChannelId) Evergreen.V338.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V338.OneToOne.OneToOne String (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    , slackUsers : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.Slack.Id Evergreen.V338.Slack.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
    , slackServers : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.Slack.Id Evergreen.V338.Slack.TeamId) (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    , slackToken : Maybe Evergreen.V338.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V338.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V338.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V338.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V338.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V338.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V338.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V338.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V338.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Evergreen.V338.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId, Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V338.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V338.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V338.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V338.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.LocalState.LoadingDiscordChannel (List Evergreen.V338.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V338.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId) Evergreen.V338.Sticker.StickerData
    , discordStickers : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.Discord.Id Evergreen.V338.Discord.StickerId) (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId) Evergreen.V338.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V338.OneToOne.OneToOne Evergreen.V338.RichText.DiscordCustomEmojiIdAndName (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V338.Postmark.ApiKey
    , serverSecret : Evergreen.V338.SecretId.SecretId Evergreen.V338.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V338.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.GamePublicId) ( Evergreen.V338.DmChannelId.GuildOrFullDmId, Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V338.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V338.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V338.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.Id.ThreadRoute (Maybe Evergreen.V338.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V338.DmChannelId.DmChannelId Evergreen.V338.Id.ThreadRoute (Maybe Evergreen.V338.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V338.Id.Id Evergreen.V338.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V338.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V338.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V338.Untrusted.Untrusted Evergreen.V338.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V338.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V338.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V338.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V338.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V338.PersonName.PersonName Evergreen.V338.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V338.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V338.Slack.OAuthCode Evergreen.V338.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V338.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V338.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V338.Id.Id Evergreen.V338.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V338.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V338.EmailAddress.EmailAddress (Result Evergreen.V338.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V338.EmailAddress.EmailAddress (Result Evergreen.V338.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V338.EmailAddress.EmailAddress (Result Evergreen.V338.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V338.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMaybeMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Result Evergreen.V338.Discord.HttpError Evergreen.V338.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V338.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Result Evergreen.V338.Discord.HttpError Evergreen.V338.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) (Result Evergreen.V338.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) (Result Evergreen.V338.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) (Result Evergreen.V338.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) (Result Evergreen.V338.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji (Result Evergreen.V338.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji (Result Evergreen.V338.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji (Result Evergreen.V338.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji (Result Evergreen.V338.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V338.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V338.Discord.HttpError (List ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId, Maybe Evergreen.V338.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Effect.Time.Posix Evergreen.V338.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V338.Slack.CurrentUser
            , team : Evergreen.V338.Slack.Team
            , users : List Evergreen.V338.Slack.User
            , channels : List ( Evergreen.V338.Slack.Channel, List Evergreen.V338.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Result Effect.Http.Error Evergreen.V338.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V338.Local.ChangeId Effect.Time.Posix Evergreen.V338.Call.CallId Evergreen.V338.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V338.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V338.Local.ChangeId Effect.Time.Posix Evergreen.V338.Call.CallId Evergreen.V338.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V338.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V338.Local.ChangeId Evergreen.V338.Call.ConnectionId Evergreen.V338.Cloudflare.RealtimeSessionId (List Evergreen.V338.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V338.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V338.Local.ChangeId Evergreen.V338.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Discord.UserAuth (Result Evergreen.V338.Discord.HttpError Evergreen.V338.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Result Evergreen.V338.Discord.HttpError Evergreen.V338.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
        (Result
            Evergreen.V338.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId
                , members : List (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
                }
            , List
                ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId
                , { guild : Evergreen.V338.Discord.GatewayGuild
                  , channels : List Evergreen.V338.Discord.Channel
                  , icon : Maybe Evergreen.V338.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Bool Evergreen.V338.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V338.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.AttachmentId, Evergreen.V338.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V338.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.AttachmentId, Evergreen.V338.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V338.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V338.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V338.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V338.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (Result Evergreen.V338.Discord.HttpError (List Evergreen.V338.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Result Evergreen.V338.Discord.HttpError (List Evergreen.V338.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V338.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V338.DmChannelId.DmChannelId Evergreen.V338.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V338.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V338.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V338.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
        (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V338.Discord.HttpError
            { guild : Evergreen.V338.Discord.GatewayGuild
            , channels : List Evergreen.V338.Discord.Channel
            , icon : Maybe Evergreen.V338.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Result Evergreen.V338.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V338.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (List ( Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId, Result Effect.Http.Error Evergreen.V338.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId, Result Effect.Http.Error Evergreen.V338.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (List ( Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V338.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V338.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V338.Discord.HttpError (List Evergreen.V338.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V338.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V338.SecretId.SecretId Evergreen.V338.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V338.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Result Evergreen.V338.Discord.HttpError ( Evergreen.V338.Discord.Guild, List Evergreen.V338.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V338.FileStatus.FileHash Int (Maybe (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
