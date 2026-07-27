module Evergreen.V336.Types exposing (..)

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
import Evergreen.V336.AiChat
import Evergreen.V336.Audio
import Evergreen.V336.Call
import Evergreen.V336.ChannelDescription
import Evergreen.V336.ChannelName
import Evergreen.V336.Cloudflare
import Evergreen.V336.Coord
import Evergreen.V336.CssPixels
import Evergreen.V336.CustomEmoji
import Evergreen.V336.Discord
import Evergreen.V336.DiscordAttachmentId
import Evergreen.V336.DiscordUserData
import Evergreen.V336.DmChannel
import Evergreen.V336.DmChannelId
import Evergreen.V336.Drawing
import Evergreen.V336.Editable
import Evergreen.V336.EmailAddress
import Evergreen.V336.Embed
import Evergreen.V336.Emoji
import Evergreen.V336.FileStatus
import Evergreen.V336.Game
import Evergreen.V336.Go
import Evergreen.V336.GuildName
import Evergreen.V336.Id
import Evergreen.V336.ImageEditor
import Evergreen.V336.ImageViewer
import Evergreen.V336.LinkedAndOtherDiscordUsers
import Evergreen.V336.Local
import Evergreen.V336.LocalState
import Evergreen.V336.Log
import Evergreen.V336.LoginForm
import Evergreen.V336.MembersAndOwner
import Evergreen.V336.Message
import Evergreen.V336.MessageInput
import Evergreen.V336.MessageView
import Evergreen.V336.MyUi
import Evergreen.V336.NonemptyDict
import Evergreen.V336.NonemptySet
import Evergreen.V336.OneOrGreater
import Evergreen.V336.OneToOne
import Evergreen.V336.Pages.Admin
import Evergreen.V336.Pagination
import Evergreen.V336.PersonName
import Evergreen.V336.Ports
import Evergreen.V336.Postmark
import Evergreen.V336.Range
import Evergreen.V336.RichText
import Evergreen.V336.Route
import Evergreen.V336.Scroll
import Evergreen.V336.SecretId
import Evergreen.V336.SessionIdHash
import Evergreen.V336.Slack
import Evergreen.V336.Sticker
import Evergreen.V336.TextEditor
import Evergreen.V336.ToBackendLog
import Evergreen.V336.Touch
import Evergreen.V336.TwoFactorAuthentication
import Evergreen.V336.Ui.Anim
import Evergreen.V336.Untrusted
import Evergreen.V336.User
import Evergreen.V336.UserAgent
import Evergreen.V336.UserSession
import Evergreen.V336.WordSpellingGame
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
    | LoginFormMsg Evergreen.V336.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V336.Pages.Admin.Msg
    | PressedLogOut Evergreen.V336.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V336.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V336.Route.Route
    | SelectedFilesToAttach ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V336.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V336.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V336.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V336.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V336.NonemptyDict.NonemptyDict Int Evergreen.V336.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V336.NonemptyDict.NonemptyDict Int Evergreen.V336.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRoute Evergreen.V336.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V336.NonemptySet.NonemptySet (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V336.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V336.AiChat.Msg
    | GameMsg Evergreen.V336.Game.Msg
    | GoSpectatorMsg Evergreen.V336.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V336.Editable.Msg Evergreen.V336.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V336.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V336.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute )
        { fileId : Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute )
        { fileId : Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V336.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage Evergreen.V336.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V336.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V336.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V336.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V336.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.User.NotificationLevel
    | GotStartupData Evergreen.V336.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PressedExportChannel Evergreen.V336.Id.ExportChannelId
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V336.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId
        , otherUserId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRoute Evergreen.V336.MessageInput.Msg
    | MessageInputMsg Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRoute Evergreen.V336.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V336.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V336.Range.Range, Evergreen.V336.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V336.Range.Range, Evergreen.V336.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V336.Call.FromJs)
    | VoiceChatMsg Evergreen.V336.Call.Msg
    | PressedChannelHeaderTab Evergreen.V336.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V336.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V336.Audio.LoadError Evergreen.V336.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V336.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V336.UserSession.UserSession
    , currentlyViewing : Evergreen.V336.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) Evergreen.V336.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.LocalState.DiscordFrontendGuild
    , user : Evergreen.V336.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.User.FrontendUser
    , discordUsers : Evergreen.V336.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V336.SessionIdHash.SessionIdHash Evergreen.V336.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V336.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId) Evergreen.V336.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId) Evergreen.V336.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V336.Call.CallId (Evergreen.V336.NonemptyDict.NonemptyDict ( Evergreen.V336.Id.Id Evergreen.V336.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V336.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V336.Go.PublicGoMatchData Evergreen.V336.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V336.Route.Route
    , windowSize : Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V336.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V336.Audio.LoadError Evergreen.V336.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V336.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V336.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V336.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V336.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V336.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.ChannelName.ChannelName Evergreen.V336.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.ChannelName.ChannelName Evergreen.V336.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V336.GuildName.GuildName (Evergreen.V336.UserSession.ToBeFilledInByBackend (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V336.Id.DiscordGuildOrDmId_DmData (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V336.UserSession.SetViewing
    | Local_SetName Evergreen.V336.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V336.Id.GuildOrDmId (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V336.Id.GuildOrDmId (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V336.Id.DiscordGuildOrDmId (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V336.Id.DiscordGuildOrDmId (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V336.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V336.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V336.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V336.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V336.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V336.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V336.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V336.NonemptySet.NonemptySet (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V336.Call.LocalChange
    | Local_Game Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Game.LocalChange
    | Local_Drawing Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Drawing.AnchorType Evergreen.V336.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Effect.Time.Posix Evergreen.V336.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V336.RichText.RichText (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))) Evergreen.V336.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId) Evergreen.V336.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V336.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V336.RichText.RichText (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))) Evergreen.V336.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId) Evergreen.V336.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.ChannelName.ChannelName Evergreen.V336.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.ChannelName.ChannelName Evergreen.V336.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V336.LocalState.JoinGuildError
            { guildId : Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId
            , guild : Evergreen.V336.LocalState.FrontendGuild
            , owner : Evergreen.V336.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V336.RichText.RichText (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))) (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V336.RichText.RichText (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V336.Id.DiscordGuildOrDmId_DmData (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V336.RichText.RichText (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Maybe Evergreen.V336.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Maybe Evergreen.V336.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V336.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V336.SessionIdHash.SessionIdHash Evergreen.V336.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V336.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V336.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V336.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V336.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V336.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Evergreen.V336.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.ChannelName.ChannelName (Evergreen.V336.Discord.OptionalData (Maybe String)) (List Evergreen.V336.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
        (Evergreen.V336.NonemptyDict.NonemptyDict
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) Evergreen.V336.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Evergreen.V336.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Maybe (Evergreen.V336.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V336.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V336.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V336.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V336.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V336.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V336.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (Evergreen.V336.Discord.OptionalData String) (Evergreen.V336.Discord.OptionalData (Maybe String)) (List Evergreen.V336.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId) Evergreen.V336.LocalState.DiscordRole
    | Server_UpdateDiscordMembers
        (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
        (Evergreen.V336.MembersAndOwner.MembersAndOwner
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Evergreen.V336.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId) Evergreen.V336.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId) Evergreen.V336.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V336.Call.ServerChange
    | Server_Game (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Game.LocalChange
    | Server_Drawing (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Drawing.AnchorType Evergreen.V336.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V336.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V336.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V336.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V336.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V336.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V336.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V336.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V336.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V336.Id.AnyGuildOrDmId Evergreen.V336.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V336.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels) (Maybe Evergreen.V336.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId) (Evergreen.V336.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V336.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V336.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V336.Local.Local LocalMsg Evergreen.V336.LocalState.LocalState
    , admin : Evergreen.V336.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId, Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V336.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V336.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V336.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V336.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.ThreadRoute ) (Evergreen.V336.NonemptyDict.NonemptyDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V336.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V336.Scroll.ScrollPosition
    , textEditor : Evergreen.V336.TextEditor.Model
    , profilePictureEditor : Evergreen.V336.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId, Evergreen.V336.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V336.Emoji.Model
    , voiceChat : Evergreen.V336.Call.Model
    , games : SeqDict.SeqDict Evergreen.V336.Id.GuildOrDmId Evergreen.V336.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V336.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V336.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V336.Range.Range
                , direction : Evergreen.V336.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V336.NonemptyDict.NonemptyDict Int Evergreen.V336.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V336.NonemptyDict.NonemptyDict Int Evergreen.V336.Touch.Touch
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
    | AdminToFrontend Evergreen.V336.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V336.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V336.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V336.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V336.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V336.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V336.Go.PublicGoMatchResponse)
    | ExportChannelResponse
        { fileName : String
        , json : String
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V336.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V336.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V336.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V336.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V336.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V336.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V336.Audio.LoadError Evergreen.V336.Audio.Source
    , startupData : Evergreen.V336.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V336.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V336.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V336.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V336.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V336.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId, Evergreen.V336.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V336.DmChannelId.DmChannelId, Evergreen.V336.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId, Evergreen.V336.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId, Evergreen.V336.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V336.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V336.NonemptyDict.NonemptyDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V336.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V336.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V336.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V336.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V336.DmChannelId.DmChannelId Evergreen.V336.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) Evergreen.V336.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.Slack.Id Evergreen.V336.Slack.ChannelId) Evergreen.V336.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V336.OneToOne.OneToOne String (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    , slackUsers : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.Slack.Id Evergreen.V336.Slack.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
    , slackServers : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.Slack.Id Evergreen.V336.Slack.TeamId) (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    , slackToken : Maybe Evergreen.V336.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V336.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V336.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V336.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V336.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V336.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V336.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V336.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V336.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Evergreen.V336.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId, Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V336.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V336.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V336.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V336.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.LocalState.LoadingDiscordChannel (List Evergreen.V336.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V336.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId) Evergreen.V336.Sticker.StickerData
    , discordStickers : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.Discord.Id Evergreen.V336.Discord.StickerId) (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId) Evergreen.V336.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V336.OneToOne.OneToOne Evergreen.V336.RichText.DiscordCustomEmojiIdAndName (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V336.Postmark.ApiKey
    , serverSecret : Evergreen.V336.SecretId.SecretId Evergreen.V336.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V336.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.GamePublicId) ( Evergreen.V336.DmChannelId.GuildOrFullDmId, Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V336.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V336.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V336.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.Id.ThreadRoute (Maybe Evergreen.V336.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V336.DmChannelId.DmChannelId Evergreen.V336.Id.ThreadRoute (Maybe Evergreen.V336.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V336.Id.Id Evergreen.V336.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V336.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V336.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V336.Untrusted.Untrusted Evergreen.V336.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V336.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V336.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V336.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V336.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V336.PersonName.PersonName Evergreen.V336.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V336.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V336.Slack.OAuthCode Evergreen.V336.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V336.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V336.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V336.Id.Id Evergreen.V336.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.GamePublicId)
    | ExportChannelRequest Evergreen.V336.Id.ExportChannelId


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V336.EmailAddress.EmailAddress (Result Evergreen.V336.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V336.EmailAddress.EmailAddress (Result Evergreen.V336.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V336.EmailAddress.EmailAddress (Result Evergreen.V336.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V336.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMaybeMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Result Evergreen.V336.Discord.HttpError Evergreen.V336.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V336.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Result Evergreen.V336.Discord.HttpError Evergreen.V336.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) (Result Evergreen.V336.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) (Result Evergreen.V336.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) (Result Evergreen.V336.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) (Result Evergreen.V336.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji (Result Evergreen.V336.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji (Result Evergreen.V336.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji (Result Evergreen.V336.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji (Result Evergreen.V336.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V336.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V336.Discord.HttpError (List ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId, Maybe Evergreen.V336.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Effect.Time.Posix Evergreen.V336.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V336.Slack.CurrentUser
            , team : Evergreen.V336.Slack.Team
            , users : List Evergreen.V336.Slack.User
            , channels : List ( Evergreen.V336.Slack.Channel, List Evergreen.V336.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Result Effect.Http.Error Evergreen.V336.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V336.Local.ChangeId Effect.Time.Posix Evergreen.V336.Call.CallId Evergreen.V336.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V336.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V336.Local.ChangeId Effect.Time.Posix Evergreen.V336.Call.CallId Evergreen.V336.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V336.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V336.Local.ChangeId Evergreen.V336.Call.ConnectionId Evergreen.V336.Cloudflare.RealtimeSessionId (List Evergreen.V336.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V336.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V336.Local.ChangeId Evergreen.V336.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Discord.UserAuth (Result Evergreen.V336.Discord.HttpError Evergreen.V336.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Result Evergreen.V336.Discord.HttpError Evergreen.V336.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
        (Result
            Evergreen.V336.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId
                , members : List (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
                }
            , List
                ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId
                , { guild : Evergreen.V336.Discord.GatewayGuild
                  , channels : List Evergreen.V336.Discord.Channel
                  , icon : Maybe Evergreen.V336.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Bool Evergreen.V336.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V336.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.AttachmentId, Evergreen.V336.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V336.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.AttachmentId, Evergreen.V336.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V336.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V336.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V336.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V336.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (Result Evergreen.V336.Discord.HttpError (List Evergreen.V336.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Result Evergreen.V336.Discord.HttpError (List Evergreen.V336.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V336.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V336.DmChannelId.DmChannelId Evergreen.V336.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V336.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V336.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V336.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
        (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V336.Discord.HttpError
            { guild : Evergreen.V336.Discord.GatewayGuild
            , channels : List Evergreen.V336.Discord.Channel
            , icon : Maybe Evergreen.V336.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Result Evergreen.V336.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V336.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (List ( Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId, Result Effect.Http.Error Evergreen.V336.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId, Result Effect.Http.Error Evergreen.V336.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (List ( Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V336.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V336.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V336.Discord.HttpError (List Evergreen.V336.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V336.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V336.SecretId.SecretId Evergreen.V336.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V336.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Result Evergreen.V336.Discord.HttpError ( Evergreen.V336.Discord.Guild, List Evergreen.V336.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V336.FileStatus.FileHash Int (Maybe (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
