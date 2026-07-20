module Evergreen.V332.Types exposing (..)

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
import Evergreen.V332.AiChat
import Evergreen.V332.Audio
import Evergreen.V332.Call
import Evergreen.V332.ChannelDescription
import Evergreen.V332.ChannelName
import Evergreen.V332.Cloudflare
import Evergreen.V332.Coord
import Evergreen.V332.CssPixels
import Evergreen.V332.CustomEmoji
import Evergreen.V332.Discord
import Evergreen.V332.DiscordAttachmentId
import Evergreen.V332.DiscordUserData
import Evergreen.V332.DmChannel
import Evergreen.V332.DmChannelId
import Evergreen.V332.Drawing
import Evergreen.V332.Editable
import Evergreen.V332.EmailAddress
import Evergreen.V332.Embed
import Evergreen.V332.Emoji
import Evergreen.V332.FileStatus
import Evergreen.V332.Game
import Evergreen.V332.Go
import Evergreen.V332.GuildName
import Evergreen.V332.Id
import Evergreen.V332.ImageEditor
import Evergreen.V332.ImageViewer
import Evergreen.V332.LinkedAndOtherDiscordUsers
import Evergreen.V332.Local
import Evergreen.V332.LocalState
import Evergreen.V332.Log
import Evergreen.V332.LoginForm
import Evergreen.V332.MembersAndOwner
import Evergreen.V332.Message
import Evergreen.V332.MessageInput
import Evergreen.V332.MessageView
import Evergreen.V332.MyUi
import Evergreen.V332.NonemptyDict
import Evergreen.V332.NonemptySet
import Evergreen.V332.OneOrGreater
import Evergreen.V332.OneToOne
import Evergreen.V332.Pages.Admin
import Evergreen.V332.Pagination
import Evergreen.V332.PersonName
import Evergreen.V332.Ports
import Evergreen.V332.Postmark
import Evergreen.V332.Range
import Evergreen.V332.RichText
import Evergreen.V332.Route
import Evergreen.V332.Scroll
import Evergreen.V332.SecretId
import Evergreen.V332.SessionIdHash
import Evergreen.V332.Slack
import Evergreen.V332.Sticker
import Evergreen.V332.TextEditor
import Evergreen.V332.ToBackendLog
import Evergreen.V332.Touch
import Evergreen.V332.TwoFactorAuthentication
import Evergreen.V332.Ui.Anim
import Evergreen.V332.Untrusted
import Evergreen.V332.User
import Evergreen.V332.UserAgent
import Evergreen.V332.UserSession
import Evergreen.V332.WordSpellingGame
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
    | LoginFormMsg Evergreen.V332.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V332.Pages.Admin.Msg
    | PressedLogOut Evergreen.V332.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V332.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V332.Route.Route
    | SelectedFilesToAttach ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V332.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V332.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V332.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V332.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V332.NonemptyDict.NonemptyDict Int Evergreen.V332.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V332.NonemptyDict.NonemptyDict Int Evergreen.V332.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRoute Evergreen.V332.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V332.NonemptySet.NonemptySet (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V332.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V332.AiChat.Msg
    | GameMsg Evergreen.V332.Game.Msg
    | GoSpectatorMsg Evergreen.V332.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V332.Editable.Msg Evergreen.V332.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V332.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V332.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute )
        { fileId : Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute )
        { fileId : Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V332.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage Evergreen.V332.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V332.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V332.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V332.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V332.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.User.NotificationLevel
    | GotStartupData Evergreen.V332.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V332.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId
        , otherUserId : Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRoute Evergreen.V332.MessageInput.Msg
    | MessageInputMsg Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRoute Evergreen.V332.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V332.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V332.Range.Range, Evergreen.V332.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V332.Range.Range, Evergreen.V332.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V332.Call.FromJs)
    | VoiceChatMsg Evergreen.V332.Call.Msg
    | PressedChannelHeaderTab Evergreen.V332.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V332.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V332.Audio.LoadError Evergreen.V332.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V332.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V332.UserSession.UserSession
    , currentlyViewing : Evergreen.V332.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) Evergreen.V332.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.LocalState.DiscordFrontendGuild
    , user : Evergreen.V332.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.User.FrontendUser
    , discordUsers : Evergreen.V332.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V332.SessionIdHash.SessionIdHash Evergreen.V332.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V332.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId) Evergreen.V332.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId) Evergreen.V332.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V332.Call.CallId (Evergreen.V332.NonemptyDict.NonemptyDict ( Evergreen.V332.Id.Id Evergreen.V332.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V332.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V332.Go.PublicGoMatchData Evergreen.V332.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V332.Route.Route
    , windowSize : Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V332.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V332.Audio.LoadError Evergreen.V332.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V332.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V332.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V332.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V332.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V332.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.ChannelName.ChannelName Evergreen.V332.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.ChannelName.ChannelName Evergreen.V332.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.UserSession.ToBeFilledInByBackend (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V332.GuildName.GuildName (Evergreen.V332.UserSession.ToBeFilledInByBackend (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V332.Id.DiscordGuildOrDmId_DmData (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V332.UserSession.SetViewing
    | Local_SetName Evergreen.V332.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V332.Id.GuildOrDmId (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V332.Id.GuildOrDmId (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId) (Evergreen.V332.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V332.Id.DiscordGuildOrDmId (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V332.Id.DiscordGuildOrDmId (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId) (Evergreen.V332.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V332.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V332.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V332.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V332.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V332.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V332.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V332.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V332.NonemptySet.NonemptySet (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V332.Call.LocalChange
    | Local_Game Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Game.LocalChange
    | Local_Drawing Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Drawing.AnchorType Evergreen.V332.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Effect.Time.Posix Evergreen.V332.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V332.RichText.RichText (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))) Evergreen.V332.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId) Evergreen.V332.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V332.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V332.RichText.RichText (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))) Evergreen.V332.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId) Evergreen.V332.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.ChannelName.ChannelName Evergreen.V332.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.ChannelName.ChannelName Evergreen.V332.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V332.LocalState.JoinGuildError
            { guildId : Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId
            , guild : Evergreen.V332.LocalState.FrontendGuild
            , owner : Evergreen.V332.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V332.RichText.RichText (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))) (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V332.RichText.RichText (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V332.Id.DiscordGuildOrDmId_DmData (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V332.RichText.RichText (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Maybe Evergreen.V332.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Maybe Evergreen.V332.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V332.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V332.SessionIdHash.SessionIdHash Evergreen.V332.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V332.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V332.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V332.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V332.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V332.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Evergreen.V332.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.ChannelName.ChannelName (Evergreen.V332.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
        (Evergreen.V332.NonemptyDict.NonemptyDict
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) Evergreen.V332.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Evergreen.V332.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Maybe (Evergreen.V332.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V332.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V332.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V332.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V332.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V332.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V332.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (Evergreen.V332.Discord.OptionalData String) (Evergreen.V332.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
        (Evergreen.V332.MembersAndOwner.MembersAndOwner
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Evergreen.V332.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId) Evergreen.V332.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId) Evergreen.V332.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V332.Call.ServerChange
    | Server_Game (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Game.LocalChange
    | Server_Drawing (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Drawing.AnchorType Evergreen.V332.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V332.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V332.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V332.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V332.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V332.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V332.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V332.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V332.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V332.Id.AnyGuildOrDmId Evergreen.V332.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V332.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels) (Maybe Evergreen.V332.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId) (Evergreen.V332.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V332.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V332.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V332.Local.Local LocalMsg Evergreen.V332.LocalState.LocalState
    , admin : Evergreen.V332.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId, Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V332.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V332.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V332.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V332.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.ThreadRoute ) (Evergreen.V332.NonemptyDict.NonemptyDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V332.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V332.Scroll.ScrollPosition
    , textEditor : Evergreen.V332.TextEditor.Model
    , profilePictureEditor : Evergreen.V332.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId, Evergreen.V332.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V332.Emoji.Model
    , voiceChat : Evergreen.V332.Call.Model
    , games : SeqDict.SeqDict Evergreen.V332.Id.GuildOrDmId Evergreen.V332.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V332.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V332.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V332.Range.Range
                , direction : Evergreen.V332.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V332.NonemptyDict.NonemptyDict Int Evergreen.V332.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V332.NonemptyDict.NonemptyDict Int Evergreen.V332.Touch.Touch
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
    | AdminToFrontend Evergreen.V332.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V332.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V332.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V332.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V332.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V332.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V332.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V332.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V332.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V332.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V332.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V332.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V332.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V332.Audio.LoadError Evergreen.V332.Audio.Source
    , startupData : Evergreen.V332.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V332.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V332.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V332.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V332.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V332.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId, Evergreen.V332.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V332.DmChannelId.DmChannelId, Evergreen.V332.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId, Evergreen.V332.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId, Evergreen.V332.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V332.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V332.NonemptyDict.NonemptyDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V332.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V332.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V332.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V332.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V332.DmChannelId.DmChannelId Evergreen.V332.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) Evergreen.V332.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.Slack.Id Evergreen.V332.Slack.ChannelId) Evergreen.V332.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V332.OneToOne.OneToOne String (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    , slackUsers : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.Slack.Id Evergreen.V332.Slack.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
    , slackServers : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.Slack.Id Evergreen.V332.Slack.TeamId) (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    , slackToken : Maybe Evergreen.V332.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V332.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V332.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V332.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V332.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V332.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V332.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V332.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V332.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Evergreen.V332.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId, Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V332.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V332.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V332.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V332.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.LocalState.LoadingDiscordChannel (List Evergreen.V332.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V332.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId) Evergreen.V332.Sticker.StickerData
    , discordStickers : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.Discord.Id Evergreen.V332.Discord.StickerId) (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId) Evergreen.V332.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V332.OneToOne.OneToOne Evergreen.V332.RichText.DiscordCustomEmojiIdAndName (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V332.Postmark.ApiKey
    , serverSecret : Evergreen.V332.SecretId.SecretId Evergreen.V332.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V332.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.GamePublicId) ( Evergreen.V332.DmChannelId.GuildOrFullDmId, Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V332.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V332.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V332.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.Id.ThreadRoute (Maybe Evergreen.V332.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V332.DmChannelId.DmChannelId Evergreen.V332.Id.ThreadRoute (Maybe Evergreen.V332.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V332.Id.Id Evergreen.V332.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V332.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V332.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V332.Untrusted.Untrusted Evergreen.V332.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V332.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V332.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V332.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V332.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V332.PersonName.PersonName Evergreen.V332.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V332.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V332.Slack.OAuthCode Evergreen.V332.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V332.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V332.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V332.Id.Id Evergreen.V332.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V332.EmailAddress.EmailAddress (Result Evergreen.V332.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V332.EmailAddress.EmailAddress (Result Evergreen.V332.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V332.EmailAddress.EmailAddress (Result Evergreen.V332.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V332.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMaybeMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Result Evergreen.V332.Discord.HttpError Evergreen.V332.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V332.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Result Evergreen.V332.Discord.HttpError Evergreen.V332.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) (Result Evergreen.V332.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) (Result Evergreen.V332.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) (Result Evergreen.V332.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) (Result Evergreen.V332.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji (Result Evergreen.V332.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji (Result Evergreen.V332.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji (Result Evergreen.V332.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji (Result Evergreen.V332.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V332.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V332.Discord.HttpError (List ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId, Maybe Evergreen.V332.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Effect.Time.Posix Evergreen.V332.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V332.Slack.CurrentUser
            , team : Evergreen.V332.Slack.Team
            , users : List Evergreen.V332.Slack.User
            , channels : List ( Evergreen.V332.Slack.Channel, List Evergreen.V332.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Result Effect.Http.Error Evergreen.V332.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V332.Local.ChangeId Effect.Time.Posix Evergreen.V332.Call.CallId Evergreen.V332.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V332.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V332.Local.ChangeId Effect.Time.Posix Evergreen.V332.Call.CallId Evergreen.V332.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V332.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V332.Local.ChangeId Evergreen.V332.Call.ConnectionId Evergreen.V332.Cloudflare.RealtimeSessionId (List Evergreen.V332.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V332.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V332.Local.ChangeId Evergreen.V332.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Discord.UserAuth (Result Evergreen.V332.Discord.HttpError Evergreen.V332.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Result Evergreen.V332.Discord.HttpError Evergreen.V332.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
        (Result
            Evergreen.V332.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId
                , members : List (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
                }
            , List
                ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId
                , { guild : Evergreen.V332.Discord.GatewayGuild
                  , channels : List Evergreen.V332.Discord.Channel
                  , icon : Maybe Evergreen.V332.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Bool Evergreen.V332.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V332.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.AttachmentId, Evergreen.V332.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V332.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.AttachmentId, Evergreen.V332.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V332.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V332.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V332.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V332.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (Result Evergreen.V332.Discord.HttpError (List Evergreen.V332.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Result Evergreen.V332.Discord.HttpError (List Evergreen.V332.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V332.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V332.DmChannelId.DmChannelId Evergreen.V332.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V332.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V332.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V332.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
        (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V332.Discord.HttpError
            { guild : Evergreen.V332.Discord.GatewayGuild
            , channels : List Evergreen.V332.Discord.Channel
            , icon : Maybe Evergreen.V332.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Result Evergreen.V332.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V332.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (List ( Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId, Result Effect.Http.Error Evergreen.V332.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId, Result Effect.Http.Error Evergreen.V332.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (List ( Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V332.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V332.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V332.Discord.HttpError (List Evergreen.V332.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V332.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V332.SecretId.SecretId Evergreen.V332.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V332.FileStatus.FileHash Int (Maybe (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
