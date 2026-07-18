module Evergreen.V327.Types exposing (..)

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
import Evergreen.V327.AiChat
import Evergreen.V327.Audio
import Evergreen.V327.Call
import Evergreen.V327.ChannelDescription
import Evergreen.V327.ChannelName
import Evergreen.V327.Cloudflare
import Evergreen.V327.Coord
import Evergreen.V327.CssPixels
import Evergreen.V327.CustomEmoji
import Evergreen.V327.Discord
import Evergreen.V327.DiscordAttachmentId
import Evergreen.V327.DiscordUserData
import Evergreen.V327.DmChannel
import Evergreen.V327.DmChannelId
import Evergreen.V327.Drawing
import Evergreen.V327.Editable
import Evergreen.V327.EmailAddress
import Evergreen.V327.Embed
import Evergreen.V327.Emoji
import Evergreen.V327.FileStatus
import Evergreen.V327.Game
import Evergreen.V327.Go
import Evergreen.V327.GuildName
import Evergreen.V327.Id
import Evergreen.V327.ImageEditor
import Evergreen.V327.ImageViewer
import Evergreen.V327.LinkedAndOtherDiscordUsers
import Evergreen.V327.Local
import Evergreen.V327.LocalState
import Evergreen.V327.Log
import Evergreen.V327.LoginForm
import Evergreen.V327.MembersAndOwner
import Evergreen.V327.Message
import Evergreen.V327.MessageInput
import Evergreen.V327.MessageView
import Evergreen.V327.MyUi
import Evergreen.V327.NonemptyDict
import Evergreen.V327.NonemptySet
import Evergreen.V327.OneOrGreater
import Evergreen.V327.OneToOne
import Evergreen.V327.Pages.Admin
import Evergreen.V327.Pagination
import Evergreen.V327.PersonName
import Evergreen.V327.Ports
import Evergreen.V327.Postmark
import Evergreen.V327.Range
import Evergreen.V327.RichText
import Evergreen.V327.Route
import Evergreen.V327.Scroll
import Evergreen.V327.SecretId
import Evergreen.V327.SessionIdHash
import Evergreen.V327.Slack
import Evergreen.V327.Sticker
import Evergreen.V327.TextEditor
import Evergreen.V327.ToBackendLog
import Evergreen.V327.Touch
import Evergreen.V327.TwoFactorAuthentication
import Evergreen.V327.Ui.Anim
import Evergreen.V327.Untrusted
import Evergreen.V327.User
import Evergreen.V327.UserAgent
import Evergreen.V327.UserSession
import Evergreen.V327.WordSpellingGame
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
    | LoginFormMsg Evergreen.V327.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V327.Pages.Admin.Msg
    | PressedLogOut Evergreen.V327.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V327.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V327.Route.Route
    | SelectedFilesToAttach ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V327.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V327.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V327.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V327.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V327.NonemptyDict.NonemptyDict Int Evergreen.V327.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V327.NonemptyDict.NonemptyDict Int Evergreen.V327.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRoute Evergreen.V327.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V327.NonemptySet.NonemptySet (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V327.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V327.AiChat.Msg
    | GameMsg Evergreen.V327.Game.Msg
    | GoSpectatorMsg Evergreen.V327.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V327.Editable.Msg Evergreen.V327.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V327.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V327.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
        { fileId : Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
        { fileId : Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V327.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage Evergreen.V327.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V327.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V327.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V327.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V327.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.User.NotificationLevel
    | GotStartupData Evergreen.V327.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V327.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId
        , otherUserId : Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRoute Evergreen.V327.MessageInput.Msg
    | MessageInputMsg Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRoute Evergreen.V327.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V327.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V327.Range.Range, Evergreen.V327.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V327.Range.Range, Evergreen.V327.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V327.Call.FromJs)
    | VoiceChatMsg Evergreen.V327.Call.Msg
    | PressedChannelHeaderTab Evergreen.V327.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V327.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V327.Audio.LoadError Evergreen.V327.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V327.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V327.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) Evergreen.V327.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.LocalState.DiscordFrontendGuild
    , user : Evergreen.V327.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.User.FrontendUser
    , discordUsers : Evergreen.V327.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V327.SessionIdHash.SessionIdHash Evergreen.V327.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V327.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId) Evergreen.V327.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId) Evergreen.V327.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V327.Call.CallId (Evergreen.V327.NonemptyDict.NonemptyDict ( Evergreen.V327.Id.Id Evergreen.V327.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V327.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V327.Go.PublicGoMatchData Evergreen.V327.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V327.Route.Route
    , windowSize : Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V327.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V327.Audio.LoadError Evergreen.V327.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V327.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V327.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V327.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V327.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V327.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.ChannelName.ChannelName Evergreen.V327.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.ChannelName.ChannelName Evergreen.V327.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.UserSession.ToBeFilledInByBackend (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V327.GuildName.GuildName (Evergreen.V327.UserSession.ToBeFilledInByBackend (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V327.Id.DiscordGuildOrDmId_DmData (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V327.UserSession.SetViewing
    | Local_SetName Evergreen.V327.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V327.Id.GuildOrDmId (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V327.Id.GuildOrDmId (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId) (Evergreen.V327.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V327.Id.DiscordGuildOrDmId (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V327.Id.DiscordGuildOrDmId (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId) (Evergreen.V327.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V327.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V327.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V327.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V327.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V327.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V327.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V327.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V327.NonemptySet.NonemptySet (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V327.Call.LocalChange
    | Local_Game Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Game.LocalChange
    | Local_Drawing Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Drawing.AnchorType Evergreen.V327.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Effect.Time.Posix Evergreen.V327.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V327.RichText.RichText (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))) Evergreen.V327.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId) Evergreen.V327.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V327.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V327.RichText.RichText (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))) Evergreen.V327.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId) Evergreen.V327.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.ChannelName.ChannelName Evergreen.V327.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.ChannelName.ChannelName Evergreen.V327.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V327.LocalState.JoinGuildError
            { guildId : Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId
            , guild : Evergreen.V327.LocalState.FrontendGuild
            , owner : Evergreen.V327.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V327.RichText.RichText (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))) (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V327.RichText.RichText (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V327.Id.DiscordGuildOrDmId_DmData (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V327.RichText.RichText (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V327.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V327.SessionIdHash.SessionIdHash Evergreen.V327.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V327.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V327.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V327.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V327.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Evergreen.V327.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.ChannelName.ChannelName (Evergreen.V327.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
        (Evergreen.V327.NonemptyDict.NonemptyDict
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) Evergreen.V327.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Evergreen.V327.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Maybe (Evergreen.V327.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V327.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V327.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V327.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V327.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V327.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V327.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) (Evergreen.V327.Discord.OptionalData String) (Evergreen.V327.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
        (Evergreen.V327.MembersAndOwner.MembersAndOwner
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Evergreen.V327.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId) Evergreen.V327.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId) Evergreen.V327.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V327.Call.ServerChange
    | Server_Game (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Game.LocalChange
    | Server_Drawing (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Drawing.AnchorType Evergreen.V327.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V327.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V327.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V327.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V327.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V327.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V327.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V327.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V327.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V327.Id.AnyGuildOrDmId Evergreen.V327.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V327.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels) (Maybe Evergreen.V327.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId) (Evergreen.V327.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V327.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V327.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V327.Local.Local LocalMsg Evergreen.V327.LocalState.LocalState
    , admin : Evergreen.V327.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId, Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V327.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V327.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V327.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V327.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ) (Evergreen.V327.NonemptyDict.NonemptyDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V327.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V327.Scroll.ScrollPosition
    , textEditor : Evergreen.V327.TextEditor.Model
    , profilePictureEditor : Evergreen.V327.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId, Evergreen.V327.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V327.Emoji.Model
    , voiceChat : Evergreen.V327.Call.Model
    , games : SeqDict.SeqDict Evergreen.V327.Id.GuildOrDmId Evergreen.V327.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V327.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
    , friendsSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V327.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V327.Range.Range
                , direction : Evergreen.V327.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V327.NonemptyDict.NonemptyDict Int Evergreen.V327.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V327.NonemptyDict.NonemptyDict Int Evergreen.V327.Touch.Touch
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
    | AdminToFrontend Evergreen.V327.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V327.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V327.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V327.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V327.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V327.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V327.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V327.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V327.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V327.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V327.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V327.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V327.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V327.Audio.LoadError Evergreen.V327.Audio.Source
    , startupData : Evergreen.V327.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V327.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V327.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V327.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V327.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V327.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId, Evergreen.V327.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V327.DmChannelId.DmChannelId, Evergreen.V327.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId, Evergreen.V327.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId, Evergreen.V327.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V327.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V327.NonemptyDict.NonemptyDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V327.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V327.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V327.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V327.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V327.DmChannelId.DmChannelId Evergreen.V327.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) Evergreen.V327.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.Slack.Id Evergreen.V327.Slack.ChannelId) Evergreen.V327.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V327.OneToOne.OneToOne String (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    , slackUsers : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.Slack.Id Evergreen.V327.Slack.UserId) (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
    , slackServers : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.Slack.Id Evergreen.V327.Slack.TeamId) (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    , slackToken : Maybe Evergreen.V327.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V327.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V327.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V327.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V327.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V327.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V327.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V327.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V327.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Evergreen.V327.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId, Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V327.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V327.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V327.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V327.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.LocalState.LoadingDiscordChannel (List Evergreen.V327.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V327.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId) Evergreen.V327.Sticker.StickerData
    , discordStickers : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.Discord.Id Evergreen.V327.Discord.StickerId) (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId) Evergreen.V327.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V327.OneToOne.OneToOne Evergreen.V327.RichText.DiscordCustomEmojiIdAndName (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V327.Postmark.ApiKey
    , serverSecret : Evergreen.V327.SecretId.SecretId Evergreen.V327.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V327.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.GamePublicId) ( Evergreen.V327.DmChannelId.GuildOrFullDmId, Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V327.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V327.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V327.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V327.DmChannelId.DmChannelId Evergreen.V327.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V327.Id.DiscordGuildOrDmId Evergreen.V327.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V327.Id.Id Evergreen.V327.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V327.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V327.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V327.Untrusted.Untrusted Evergreen.V327.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V327.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V327.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V327.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V327.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V327.PersonName.PersonName Evergreen.V327.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V327.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V327.Slack.OAuthCode Evergreen.V327.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V327.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V327.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V327.Id.Id Evergreen.V327.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V327.EmailAddress.EmailAddress (Result Evergreen.V327.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V327.EmailAddress.EmailAddress (Result Evergreen.V327.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V327.EmailAddress.EmailAddress (Result Evergreen.V327.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V327.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMaybeMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Result Evergreen.V327.Discord.HttpError Evergreen.V327.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V327.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Result Evergreen.V327.Discord.HttpError Evergreen.V327.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) (Result Evergreen.V327.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) (Result Evergreen.V327.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) (Result Evergreen.V327.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) (Result Evergreen.V327.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji (Result Evergreen.V327.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji (Result Evergreen.V327.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji (Result Evergreen.V327.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji (Result Evergreen.V327.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V327.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V327.Discord.HttpError (List ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId, Maybe Evergreen.V327.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Effect.Time.Posix Evergreen.V327.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V327.Slack.CurrentUser
            , team : Evergreen.V327.Slack.Team
            , users : List Evergreen.V327.Slack.User
            , channels : List ( Evergreen.V327.Slack.Channel, List Evergreen.V327.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Result Effect.Http.Error Evergreen.V327.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V327.Local.ChangeId Effect.Time.Posix Evergreen.V327.Call.CallId Evergreen.V327.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V327.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V327.Local.ChangeId Effect.Time.Posix Evergreen.V327.Call.CallId Evergreen.V327.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V327.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V327.Local.ChangeId Evergreen.V327.Call.ConnectionId Evergreen.V327.Cloudflare.RealtimeSessionId (List Evergreen.V327.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V327.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V327.Local.ChangeId Evergreen.V327.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Discord.UserAuth (Result Evergreen.V327.Discord.HttpError Evergreen.V327.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Result Evergreen.V327.Discord.HttpError Evergreen.V327.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
        (Result
            Evergreen.V327.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId
                , members : List (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
                }
            , List
                ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId
                , { guild : Evergreen.V327.Discord.GatewayGuild
                  , channels : List Evergreen.V327.Discord.Channel
                  , icon : Maybe Evergreen.V327.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Bool Evergreen.V327.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V327.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.AttachmentId, Evergreen.V327.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V327.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.AttachmentId, Evergreen.V327.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V327.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V327.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V327.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V327.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) (Result Evergreen.V327.Discord.HttpError (List Evergreen.V327.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Result Evergreen.V327.Discord.HttpError (List Evergreen.V327.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V327.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V327.DmChannelId.DmChannelId Evergreen.V327.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V327.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V327.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V327.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
        (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V327.Discord.HttpError
            { guild : Evergreen.V327.Discord.GatewayGuild
            , channels : List Evergreen.V327.Discord.Channel
            , icon : Maybe Evergreen.V327.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Result Evergreen.V327.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V327.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (List ( Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId, Result Effect.Http.Error Evergreen.V327.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId, Result Effect.Http.Error Evergreen.V327.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (List ( Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V327.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V327.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V327.Discord.HttpError (List Evergreen.V327.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V327.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V327.SecretId.SecretId Evergreen.V327.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V327.FileStatus.FileHash Int (Maybe (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
