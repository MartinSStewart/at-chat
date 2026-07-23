module Evergreen.V333.Types exposing (..)

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
import Evergreen.V333.AiChat
import Evergreen.V333.Audio
import Evergreen.V333.Call
import Evergreen.V333.ChannelDescription
import Evergreen.V333.ChannelName
import Evergreen.V333.Cloudflare
import Evergreen.V333.Coord
import Evergreen.V333.CssPixels
import Evergreen.V333.CustomEmoji
import Evergreen.V333.Discord
import Evergreen.V333.DiscordAttachmentId
import Evergreen.V333.DiscordUserData
import Evergreen.V333.DmChannel
import Evergreen.V333.DmChannelId
import Evergreen.V333.Drawing
import Evergreen.V333.Editable
import Evergreen.V333.EmailAddress
import Evergreen.V333.Embed
import Evergreen.V333.Emoji
import Evergreen.V333.FileStatus
import Evergreen.V333.Game
import Evergreen.V333.Go
import Evergreen.V333.GuildName
import Evergreen.V333.Id
import Evergreen.V333.ImageEditor
import Evergreen.V333.ImageViewer
import Evergreen.V333.LinkedAndOtherDiscordUsers
import Evergreen.V333.Local
import Evergreen.V333.LocalState
import Evergreen.V333.Log
import Evergreen.V333.LoginForm
import Evergreen.V333.MembersAndOwner
import Evergreen.V333.Message
import Evergreen.V333.MessageInput
import Evergreen.V333.MessageView
import Evergreen.V333.MyUi
import Evergreen.V333.NonemptyDict
import Evergreen.V333.NonemptySet
import Evergreen.V333.OneOrGreater
import Evergreen.V333.OneToOne
import Evergreen.V333.Pages.Admin
import Evergreen.V333.Pagination
import Evergreen.V333.PersonName
import Evergreen.V333.Ports
import Evergreen.V333.Postmark
import Evergreen.V333.Range
import Evergreen.V333.RichText
import Evergreen.V333.Route
import Evergreen.V333.Scroll
import Evergreen.V333.SecretId
import Evergreen.V333.SessionIdHash
import Evergreen.V333.Slack
import Evergreen.V333.Sticker
import Evergreen.V333.TextEditor
import Evergreen.V333.ToBackendLog
import Evergreen.V333.Touch
import Evergreen.V333.TwoFactorAuthentication
import Evergreen.V333.Ui.Anim
import Evergreen.V333.Untrusted
import Evergreen.V333.User
import Evergreen.V333.UserAgent
import Evergreen.V333.UserSession
import Evergreen.V333.WordSpellingGame
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
    | LoginFormMsg Evergreen.V333.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V333.Pages.Admin.Msg
    | PressedLogOut Evergreen.V333.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V333.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V333.Route.Route
    | SelectedFilesToAttach ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V333.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V333.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V333.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V333.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V333.NonemptyDict.NonemptyDict Int Evergreen.V333.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V333.NonemptyDict.NonemptyDict Int Evergreen.V333.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRoute Evergreen.V333.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V333.NonemptySet.NonemptySet (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V333.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V333.AiChat.Msg
    | GameMsg Evergreen.V333.Game.Msg
    | GoSpectatorMsg Evergreen.V333.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V333.Editable.Msg Evergreen.V333.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V333.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V333.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute )
        { fileId : Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute )
        { fileId : Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V333.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage Evergreen.V333.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V333.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V333.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V333.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V333.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.User.NotificationLevel
    | GotStartupData Evergreen.V333.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V333.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId
        , otherUserId : Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRoute Evergreen.V333.MessageInput.Msg
    | MessageInputMsg Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRoute Evergreen.V333.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V333.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V333.Range.Range, Evergreen.V333.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V333.Range.Range, Evergreen.V333.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V333.Call.FromJs)
    | VoiceChatMsg Evergreen.V333.Call.Msg
    | PressedChannelHeaderTab Evergreen.V333.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V333.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V333.Audio.LoadError Evergreen.V333.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V333.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V333.UserSession.UserSession
    , currentlyViewing : Evergreen.V333.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) Evergreen.V333.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.LocalState.DiscordFrontendGuild
    , user : Evergreen.V333.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.User.FrontendUser
    , discordUsers : Evergreen.V333.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V333.SessionIdHash.SessionIdHash Evergreen.V333.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V333.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId) Evergreen.V333.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId) Evergreen.V333.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V333.Call.CallId (Evergreen.V333.NonemptyDict.NonemptyDict ( Evergreen.V333.Id.Id Evergreen.V333.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V333.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V333.Go.PublicGoMatchData Evergreen.V333.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V333.Route.Route
    , windowSize : Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V333.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V333.Audio.LoadError Evergreen.V333.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V333.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V333.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V333.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V333.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V333.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.ChannelName.ChannelName Evergreen.V333.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.ChannelName.ChannelName Evergreen.V333.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V333.GuildName.GuildName (Evergreen.V333.UserSession.ToBeFilledInByBackend (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V333.Id.DiscordGuildOrDmId_DmData (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V333.UserSession.SetViewing
    | Local_SetName Evergreen.V333.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V333.Id.GuildOrDmId (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V333.Id.GuildOrDmId (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V333.Id.DiscordGuildOrDmId (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V333.Id.DiscordGuildOrDmId (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V333.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V333.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V333.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V333.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V333.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V333.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V333.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V333.NonemptySet.NonemptySet (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V333.Call.LocalChange
    | Local_Game Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Game.LocalChange
    | Local_Drawing Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Drawing.AnchorType Evergreen.V333.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Effect.Time.Posix Evergreen.V333.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V333.RichText.RichText (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))) Evergreen.V333.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId) Evergreen.V333.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V333.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V333.RichText.RichText (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))) Evergreen.V333.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId) Evergreen.V333.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.ChannelName.ChannelName Evergreen.V333.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.ChannelName.ChannelName Evergreen.V333.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V333.LocalState.JoinGuildError
            { guildId : Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId
            , guild : Evergreen.V333.LocalState.FrontendGuild
            , owner : Evergreen.V333.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V333.RichText.RichText (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))) (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V333.RichText.RichText (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V333.Id.DiscordGuildOrDmId_DmData (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V333.RichText.RichText (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Maybe Evergreen.V333.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Maybe Evergreen.V333.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V333.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V333.SessionIdHash.SessionIdHash Evergreen.V333.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V333.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V333.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V333.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V333.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V333.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Evergreen.V333.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.ChannelName.ChannelName (Evergreen.V333.Discord.OptionalData (Maybe String)) (List Evergreen.V333.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
        (Evergreen.V333.NonemptyDict.NonemptyDict
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) Evergreen.V333.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Evergreen.V333.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Maybe (Evergreen.V333.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V333.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V333.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V333.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V333.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V333.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V333.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (Evergreen.V333.Discord.OptionalData String) (Evergreen.V333.Discord.OptionalData (Maybe String)) (List Evergreen.V333.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId) Evergreen.V333.LocalState.DiscordRole
    | Server_UpdateDiscordMembers
        (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
        (Evergreen.V333.MembersAndOwner.MembersAndOwner
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Evergreen.V333.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId) Evergreen.V333.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId) Evergreen.V333.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V333.Call.ServerChange
    | Server_Game (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Game.LocalChange
    | Server_Drawing (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Drawing.AnchorType Evergreen.V333.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V333.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V333.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V333.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V333.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V333.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V333.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V333.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V333.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V333.Id.AnyGuildOrDmId Evergreen.V333.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V333.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels) (Maybe Evergreen.V333.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId) (Evergreen.V333.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V333.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V333.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V333.Local.Local LocalMsg Evergreen.V333.LocalState.LocalState
    , admin : Evergreen.V333.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId, Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V333.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V333.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V333.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V333.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.ThreadRoute ) (Evergreen.V333.NonemptyDict.NonemptyDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V333.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V333.Scroll.ScrollPosition
    , textEditor : Evergreen.V333.TextEditor.Model
    , profilePictureEditor : Evergreen.V333.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId, Evergreen.V333.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V333.Emoji.Model
    , voiceChat : Evergreen.V333.Call.Model
    , games : SeqDict.SeqDict Evergreen.V333.Id.GuildOrDmId Evergreen.V333.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V333.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V333.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V333.Range.Range
                , direction : Evergreen.V333.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V333.NonemptyDict.NonemptyDict Int Evergreen.V333.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V333.NonemptyDict.NonemptyDict Int Evergreen.V333.Touch.Touch
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
    | AdminToFrontend Evergreen.V333.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V333.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V333.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V333.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V333.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V333.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V333.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V333.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V333.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V333.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V333.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V333.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V333.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V333.Audio.LoadError Evergreen.V333.Audio.Source
    , startupData : Evergreen.V333.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V333.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V333.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V333.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V333.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V333.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId, Evergreen.V333.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V333.DmChannelId.DmChannelId, Evergreen.V333.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId, Evergreen.V333.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId, Evergreen.V333.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V333.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V333.NonemptyDict.NonemptyDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V333.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V333.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V333.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V333.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V333.DmChannelId.DmChannelId Evergreen.V333.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) Evergreen.V333.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.Slack.Id Evergreen.V333.Slack.ChannelId) Evergreen.V333.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V333.OneToOne.OneToOne String (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    , slackUsers : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.Slack.Id Evergreen.V333.Slack.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
    , slackServers : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.Slack.Id Evergreen.V333.Slack.TeamId) (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    , slackToken : Maybe Evergreen.V333.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V333.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V333.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V333.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V333.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V333.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V333.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V333.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V333.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Evergreen.V333.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId, Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V333.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V333.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V333.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V333.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.LocalState.LoadingDiscordChannel (List Evergreen.V333.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V333.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId) Evergreen.V333.Sticker.StickerData
    , discordStickers : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.Discord.Id Evergreen.V333.Discord.StickerId) (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId) Evergreen.V333.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V333.OneToOne.OneToOne Evergreen.V333.RichText.DiscordCustomEmojiIdAndName (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V333.Postmark.ApiKey
    , serverSecret : Evergreen.V333.SecretId.SecretId Evergreen.V333.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V333.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.GamePublicId) ( Evergreen.V333.DmChannelId.GuildOrFullDmId, Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V333.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V333.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V333.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.Id.ThreadRoute (Maybe Evergreen.V333.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V333.DmChannelId.DmChannelId Evergreen.V333.Id.ThreadRoute (Maybe Evergreen.V333.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V333.Id.Id Evergreen.V333.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V333.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V333.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V333.Untrusted.Untrusted Evergreen.V333.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V333.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V333.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V333.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V333.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V333.PersonName.PersonName Evergreen.V333.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V333.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V333.Slack.OAuthCode Evergreen.V333.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V333.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V333.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V333.Id.Id Evergreen.V333.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V333.EmailAddress.EmailAddress (Result Evergreen.V333.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V333.EmailAddress.EmailAddress (Result Evergreen.V333.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V333.EmailAddress.EmailAddress (Result Evergreen.V333.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V333.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMaybeMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Result Evergreen.V333.Discord.HttpError Evergreen.V333.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V333.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Result Evergreen.V333.Discord.HttpError Evergreen.V333.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) (Result Evergreen.V333.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) (Result Evergreen.V333.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) (Result Evergreen.V333.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) (Result Evergreen.V333.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji (Result Evergreen.V333.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji (Result Evergreen.V333.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji (Result Evergreen.V333.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji (Result Evergreen.V333.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V333.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V333.Discord.HttpError (List ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId, Maybe Evergreen.V333.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Effect.Time.Posix Evergreen.V333.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V333.Slack.CurrentUser
            , team : Evergreen.V333.Slack.Team
            , users : List Evergreen.V333.Slack.User
            , channels : List ( Evergreen.V333.Slack.Channel, List Evergreen.V333.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Result Effect.Http.Error Evergreen.V333.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V333.Local.ChangeId Effect.Time.Posix Evergreen.V333.Call.CallId Evergreen.V333.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V333.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V333.Local.ChangeId Effect.Time.Posix Evergreen.V333.Call.CallId Evergreen.V333.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V333.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V333.Local.ChangeId Evergreen.V333.Call.ConnectionId Evergreen.V333.Cloudflare.RealtimeSessionId (List Evergreen.V333.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V333.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V333.Local.ChangeId Evergreen.V333.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Discord.UserAuth (Result Evergreen.V333.Discord.HttpError Evergreen.V333.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Result Evergreen.V333.Discord.HttpError Evergreen.V333.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
        (Result
            Evergreen.V333.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId
                , members : List (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
                }
            , List
                ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId
                , { guild : Evergreen.V333.Discord.GatewayGuild
                  , channels : List Evergreen.V333.Discord.Channel
                  , icon : Maybe Evergreen.V333.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Bool Evergreen.V333.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V333.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.AttachmentId, Evergreen.V333.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V333.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.AttachmentId, Evergreen.V333.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V333.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V333.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V333.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V333.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (Result Evergreen.V333.Discord.HttpError (List Evergreen.V333.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Result Evergreen.V333.Discord.HttpError (List Evergreen.V333.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V333.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V333.DmChannelId.DmChannelId Evergreen.V333.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V333.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V333.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V333.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
        (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V333.Discord.HttpError
            { guild : Evergreen.V333.Discord.GatewayGuild
            , channels : List Evergreen.V333.Discord.Channel
            , icon : Maybe Evergreen.V333.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Result Evergreen.V333.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V333.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (List ( Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId, Result Effect.Http.Error Evergreen.V333.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId, Result Effect.Http.Error Evergreen.V333.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (List ( Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V333.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V333.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V333.Discord.HttpError (List Evergreen.V333.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V333.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V333.SecretId.SecretId Evergreen.V333.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V333.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Result Evergreen.V333.Discord.HttpError Evergreen.V333.Discord.Guild)
    | GotTimeForWebsocketListenClose (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V333.FileStatus.FileHash Int (Maybe (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
