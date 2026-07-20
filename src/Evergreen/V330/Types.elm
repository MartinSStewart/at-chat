module Evergreen.V330.Types exposing (..)

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
import Evergreen.V330.AiChat
import Evergreen.V330.Audio
import Evergreen.V330.Call
import Evergreen.V330.ChannelDescription
import Evergreen.V330.ChannelName
import Evergreen.V330.Cloudflare
import Evergreen.V330.Coord
import Evergreen.V330.CssPixels
import Evergreen.V330.CustomEmoji
import Evergreen.V330.Discord
import Evergreen.V330.DiscordAttachmentId
import Evergreen.V330.DiscordUserData
import Evergreen.V330.DmChannel
import Evergreen.V330.DmChannelId
import Evergreen.V330.Drawing
import Evergreen.V330.Editable
import Evergreen.V330.EmailAddress
import Evergreen.V330.Embed
import Evergreen.V330.Emoji
import Evergreen.V330.FileStatus
import Evergreen.V330.Game
import Evergreen.V330.Go
import Evergreen.V330.GuildName
import Evergreen.V330.Id
import Evergreen.V330.ImageEditor
import Evergreen.V330.ImageViewer
import Evergreen.V330.LinkedAndOtherDiscordUsers
import Evergreen.V330.Local
import Evergreen.V330.LocalState
import Evergreen.V330.Log
import Evergreen.V330.LoginForm
import Evergreen.V330.MembersAndOwner
import Evergreen.V330.Message
import Evergreen.V330.MessageInput
import Evergreen.V330.MessageView
import Evergreen.V330.MyUi
import Evergreen.V330.NonemptyDict
import Evergreen.V330.NonemptySet
import Evergreen.V330.OneOrGreater
import Evergreen.V330.OneToOne
import Evergreen.V330.Pages.Admin
import Evergreen.V330.Pagination
import Evergreen.V330.PersonName
import Evergreen.V330.Ports
import Evergreen.V330.Postmark
import Evergreen.V330.Range
import Evergreen.V330.RichText
import Evergreen.V330.Route
import Evergreen.V330.Scroll
import Evergreen.V330.SecretId
import Evergreen.V330.SessionIdHash
import Evergreen.V330.Slack
import Evergreen.V330.Sticker
import Evergreen.V330.TextEditor
import Evergreen.V330.ToBackendLog
import Evergreen.V330.Touch
import Evergreen.V330.TwoFactorAuthentication
import Evergreen.V330.Ui.Anim
import Evergreen.V330.Untrusted
import Evergreen.V330.User
import Evergreen.V330.UserAgent
import Evergreen.V330.UserSession
import Evergreen.V330.WordSpellingGame
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
    | LoginFormMsg Evergreen.V330.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V330.Pages.Admin.Msg
    | PressedLogOut Evergreen.V330.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V330.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V330.Route.Route
    | SelectedFilesToAttach ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V330.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V330.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V330.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V330.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V330.NonemptyDict.NonemptyDict Int Evergreen.V330.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V330.NonemptyDict.NonemptyDict Int Evergreen.V330.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRoute Evergreen.V330.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V330.NonemptySet.NonemptySet (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V330.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V330.AiChat.Msg
    | GameMsg Evergreen.V330.Game.Msg
    | GoSpectatorMsg Evergreen.V330.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V330.Editable.Msg Evergreen.V330.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V330.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V330.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute )
        { fileId : Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute )
        { fileId : Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V330.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage Evergreen.V330.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V330.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V330.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V330.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V330.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.User.NotificationLevel
    | GotStartupData Evergreen.V330.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V330.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId
        , otherUserId : Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRoute Evergreen.V330.MessageInput.Msg
    | MessageInputMsg Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRoute Evergreen.V330.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V330.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V330.Range.Range, Evergreen.V330.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V330.Range.Range, Evergreen.V330.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V330.Call.FromJs)
    | VoiceChatMsg Evergreen.V330.Call.Msg
    | PressedChannelHeaderTab Evergreen.V330.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V330.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V330.Audio.LoadError Evergreen.V330.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V330.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V330.UserSession.UserSession
    , currentlyViewing : Evergreen.V330.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) Evergreen.V330.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.LocalState.DiscordFrontendGuild
    , user : Evergreen.V330.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.User.FrontendUser
    , discordUsers : Evergreen.V330.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V330.SessionIdHash.SessionIdHash Evergreen.V330.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V330.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId) Evergreen.V330.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId) Evergreen.V330.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V330.Call.CallId (Evergreen.V330.NonemptyDict.NonemptyDict ( Evergreen.V330.Id.Id Evergreen.V330.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V330.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V330.Go.PublicGoMatchData Evergreen.V330.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V330.Route.Route
    , windowSize : Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V330.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V330.Audio.LoadError Evergreen.V330.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V330.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V330.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V330.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V330.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V330.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.ChannelName.ChannelName Evergreen.V330.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.ChannelName.ChannelName Evergreen.V330.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.UserSession.ToBeFilledInByBackend (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V330.GuildName.GuildName (Evergreen.V330.UserSession.ToBeFilledInByBackend (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V330.Id.DiscordGuildOrDmId_DmData (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V330.UserSession.SetViewing
    | Local_SetName Evergreen.V330.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V330.Id.GuildOrDmId (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V330.Id.GuildOrDmId (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId) (Evergreen.V330.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V330.Id.DiscordGuildOrDmId (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V330.Id.DiscordGuildOrDmId (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId) (Evergreen.V330.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V330.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V330.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V330.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V330.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V330.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V330.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V330.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V330.NonemptySet.NonemptySet (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V330.Call.LocalChange
    | Local_Game Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Game.LocalChange
    | Local_Drawing Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Drawing.AnchorType Evergreen.V330.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Effect.Time.Posix Evergreen.V330.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V330.RichText.RichText (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))) Evergreen.V330.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId) Evergreen.V330.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V330.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V330.RichText.RichText (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))) Evergreen.V330.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId) Evergreen.V330.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.ChannelName.ChannelName Evergreen.V330.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.ChannelName.ChannelName Evergreen.V330.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V330.LocalState.JoinGuildError
            { guildId : Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId
            , guild : Evergreen.V330.LocalState.FrontendGuild
            , owner : Evergreen.V330.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V330.RichText.RichText (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))) (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V330.RichText.RichText (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V330.Id.DiscordGuildOrDmId_DmData (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V330.RichText.RichText (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V330.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V330.SessionIdHash.SessionIdHash Evergreen.V330.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V330.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V330.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V330.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V330.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V330.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Evergreen.V330.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.ChannelName.ChannelName (Evergreen.V330.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
        (Evergreen.V330.NonemptyDict.NonemptyDict
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) Evergreen.V330.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Evergreen.V330.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Maybe (Evergreen.V330.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V330.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V330.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V330.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V330.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V330.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V330.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (Evergreen.V330.Discord.OptionalData String) (Evergreen.V330.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
        (Evergreen.V330.MembersAndOwner.MembersAndOwner
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Evergreen.V330.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId) Evergreen.V330.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId) Evergreen.V330.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V330.Call.ServerChange
    | Server_Game (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Game.LocalChange
    | Server_Drawing (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Drawing.AnchorType Evergreen.V330.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V330.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V330.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V330.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V330.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V330.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V330.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V330.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V330.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V330.Id.AnyGuildOrDmId Evergreen.V330.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V330.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels) (Maybe Evergreen.V330.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId) (Evergreen.V330.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V330.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V330.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V330.Local.Local LocalMsg Evergreen.V330.LocalState.LocalState
    , admin : Evergreen.V330.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId, Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V330.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V330.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V330.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V330.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.ThreadRoute ) (Evergreen.V330.NonemptyDict.NonemptyDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V330.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V330.Scroll.ScrollPosition
    , textEditor : Evergreen.V330.TextEditor.Model
    , profilePictureEditor : Evergreen.V330.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId, Evergreen.V330.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V330.Emoji.Model
    , voiceChat : Evergreen.V330.Call.Model
    , games : SeqDict.SeqDict Evergreen.V330.Id.GuildOrDmId Evergreen.V330.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V330.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V330.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V330.Range.Range
                , direction : Evergreen.V330.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V330.NonemptyDict.NonemptyDict Int Evergreen.V330.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V330.NonemptyDict.NonemptyDict Int Evergreen.V330.Touch.Touch
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
    | AdminToFrontend Evergreen.V330.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V330.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V330.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V330.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V330.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V330.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V330.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V330.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V330.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V330.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V330.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V330.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V330.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V330.Audio.LoadError Evergreen.V330.Audio.Source
    , startupData : Evergreen.V330.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V330.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V330.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V330.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V330.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V330.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId, Evergreen.V330.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V330.DmChannelId.DmChannelId, Evergreen.V330.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId, Evergreen.V330.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId, Evergreen.V330.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V330.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V330.NonemptyDict.NonemptyDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V330.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V330.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V330.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V330.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V330.DmChannelId.DmChannelId Evergreen.V330.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) Evergreen.V330.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.Slack.Id Evergreen.V330.Slack.ChannelId) Evergreen.V330.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V330.OneToOne.OneToOne String (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    , slackUsers : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.Slack.Id Evergreen.V330.Slack.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
    , slackServers : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.Slack.Id Evergreen.V330.Slack.TeamId) (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    , slackToken : Maybe Evergreen.V330.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V330.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V330.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V330.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V330.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V330.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V330.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V330.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V330.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Evergreen.V330.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId, Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V330.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V330.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V330.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V330.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.LocalState.LoadingDiscordChannel (List Evergreen.V330.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V330.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId) Evergreen.V330.Sticker.StickerData
    , discordStickers : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.Discord.Id Evergreen.V330.Discord.StickerId) (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId) Evergreen.V330.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V330.OneToOne.OneToOne Evergreen.V330.RichText.DiscordCustomEmojiIdAndName (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V330.Postmark.ApiKey
    , serverSecret : Evergreen.V330.SecretId.SecretId Evergreen.V330.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V330.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.GamePublicId) ( Evergreen.V330.DmChannelId.GuildOrFullDmId, Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V330.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V330.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V330.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.Id.ThreadRoute (Maybe Evergreen.V330.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V330.DmChannelId.DmChannelId Evergreen.V330.Id.ThreadRoute (Maybe Evergreen.V330.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V330.Id.Id Evergreen.V330.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V330.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V330.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V330.Untrusted.Untrusted Evergreen.V330.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V330.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V330.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V330.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V330.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V330.PersonName.PersonName Evergreen.V330.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V330.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V330.Slack.OAuthCode Evergreen.V330.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V330.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V330.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V330.Id.Id Evergreen.V330.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V330.EmailAddress.EmailAddress (Result Evergreen.V330.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V330.EmailAddress.EmailAddress (Result Evergreen.V330.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V330.EmailAddress.EmailAddress (Result Evergreen.V330.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V330.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMaybeMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Result Evergreen.V330.Discord.HttpError Evergreen.V330.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V330.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Result Evergreen.V330.Discord.HttpError Evergreen.V330.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) (Result Evergreen.V330.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) (Result Evergreen.V330.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) (Result Evergreen.V330.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) (Result Evergreen.V330.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji (Result Evergreen.V330.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji (Result Evergreen.V330.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji (Result Evergreen.V330.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji (Result Evergreen.V330.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V330.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V330.Discord.HttpError (List ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId, Maybe Evergreen.V330.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Effect.Time.Posix Evergreen.V330.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V330.Slack.CurrentUser
            , team : Evergreen.V330.Slack.Team
            , users : List Evergreen.V330.Slack.User
            , channels : List ( Evergreen.V330.Slack.Channel, List Evergreen.V330.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Result Effect.Http.Error Evergreen.V330.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V330.Local.ChangeId Effect.Time.Posix Evergreen.V330.Call.CallId Evergreen.V330.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V330.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V330.Local.ChangeId Effect.Time.Posix Evergreen.V330.Call.CallId Evergreen.V330.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V330.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V330.Local.ChangeId Evergreen.V330.Call.ConnectionId Evergreen.V330.Cloudflare.RealtimeSessionId (List Evergreen.V330.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V330.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V330.Local.ChangeId Evergreen.V330.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Discord.UserAuth (Result Evergreen.V330.Discord.HttpError Evergreen.V330.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Result Evergreen.V330.Discord.HttpError Evergreen.V330.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
        (Result
            Evergreen.V330.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId
                , members : List (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
                }
            , List
                ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId
                , { guild : Evergreen.V330.Discord.GatewayGuild
                  , channels : List Evergreen.V330.Discord.Channel
                  , icon : Maybe Evergreen.V330.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Bool Evergreen.V330.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V330.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.AttachmentId, Evergreen.V330.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V330.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.AttachmentId, Evergreen.V330.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V330.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V330.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V330.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V330.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (Result Evergreen.V330.Discord.HttpError (List Evergreen.V330.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Result Evergreen.V330.Discord.HttpError (List Evergreen.V330.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V330.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V330.DmChannelId.DmChannelId Evergreen.V330.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V330.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V330.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V330.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
        (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V330.Discord.HttpError
            { guild : Evergreen.V330.Discord.GatewayGuild
            , channels : List Evergreen.V330.Discord.Channel
            , icon : Maybe Evergreen.V330.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Result Evergreen.V330.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V330.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (List ( Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId, Result Effect.Http.Error Evergreen.V330.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId, Result Effect.Http.Error Evergreen.V330.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (List ( Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V330.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V330.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V330.Discord.HttpError (List Evergreen.V330.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V330.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V330.SecretId.SecretId Evergreen.V330.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V330.FileStatus.FileHash Int (Maybe (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
