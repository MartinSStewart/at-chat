module Evergreen.V319.Types exposing (..)

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
import Evergreen.V319.AiChat
import Evergreen.V319.Audio
import Evergreen.V319.Call
import Evergreen.V319.ChannelDescription
import Evergreen.V319.ChannelName
import Evergreen.V319.Cloudflare
import Evergreen.V319.Coord
import Evergreen.V319.CssPixels
import Evergreen.V319.CustomEmoji
import Evergreen.V319.Discord
import Evergreen.V319.DiscordAttachmentId
import Evergreen.V319.DiscordUserData
import Evergreen.V319.DmChannel
import Evergreen.V319.DmChannelId
import Evergreen.V319.Drawing
import Evergreen.V319.Editable
import Evergreen.V319.EmailAddress
import Evergreen.V319.Embed
import Evergreen.V319.Emoji
import Evergreen.V319.FileStatus
import Evergreen.V319.Game
import Evergreen.V319.Go
import Evergreen.V319.GuildName
import Evergreen.V319.Id
import Evergreen.V319.ImageEditor
import Evergreen.V319.ImageViewer
import Evergreen.V319.LinkedAndOtherDiscordUsers
import Evergreen.V319.Local
import Evergreen.V319.LocalState
import Evergreen.V319.Log
import Evergreen.V319.LoginForm
import Evergreen.V319.MembersAndOwner
import Evergreen.V319.Message
import Evergreen.V319.MessageInput
import Evergreen.V319.MessageView
import Evergreen.V319.MyUi
import Evergreen.V319.NonemptyDict
import Evergreen.V319.NonemptySet
import Evergreen.V319.OneOrGreater
import Evergreen.V319.OneToOne
import Evergreen.V319.Pages.Admin
import Evergreen.V319.Pagination
import Evergreen.V319.PersonName
import Evergreen.V319.Ports
import Evergreen.V319.Postmark
import Evergreen.V319.Range
import Evergreen.V319.RichText
import Evergreen.V319.Route
import Evergreen.V319.Scroll
import Evergreen.V319.SecretId
import Evergreen.V319.SessionIdHash
import Evergreen.V319.Slack
import Evergreen.V319.Sticker
import Evergreen.V319.TextEditor
import Evergreen.V319.ToBackendLog
import Evergreen.V319.Touch
import Evergreen.V319.TwoFactorAuthentication
import Evergreen.V319.Ui.Anim
import Evergreen.V319.Untrusted
import Evergreen.V319.User
import Evergreen.V319.UserAgent
import Evergreen.V319.UserSession
import Evergreen.V319.WordSpellingGame
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
    { deleteConfirmation : String
    , showDeleteConfirmation : Bool
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
    | LoginFormMsg Evergreen.V319.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V319.Pages.Admin.Msg
    | PressedLogOut Evergreen.V319.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V319.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V319.Route.Route
    | SelectedFilesToAttach ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V319.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V319.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V319.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V319.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V319.NonemptyDict.NonemptyDict Int Evergreen.V319.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V319.NonemptyDict.NonemptyDict Int Evergreen.V319.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRoute Evergreen.V319.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V319.NonemptySet.NonemptySet (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V319.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V319.AiChat.Msg
    | GameMsg Evergreen.V319.Game.Msg
    | GoSpectatorMsg Evergreen.V319.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V319.Editable.Msg Evergreen.V319.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V319.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V319.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
        { fileId : Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
        { fileId : Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V319.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage Evergreen.V319.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V319.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V319.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V319.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V319.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.User.NotificationLevel
    | GotStartupData Evergreen.V319.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V319.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId
        , otherUserId : Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRoute Evergreen.V319.MessageInput.Msg
    | MessageInputMsg Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRoute Evergreen.V319.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V319.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V319.Range.Range, Evergreen.V319.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V319.Range.Range, Evergreen.V319.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V319.Call.FromJs)
    | VoiceChatMsg Evergreen.V319.Call.Msg
    | PressedChannelHeaderTab Evergreen.V319.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V319.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V319.Audio.LoadError Evergreen.V319.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V319.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V319.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) Evergreen.V319.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.LocalState.DiscordFrontendGuild
    , user : Evergreen.V319.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.User.FrontendUser
    , discordUsers : Evergreen.V319.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V319.SessionIdHash.SessionIdHash Evergreen.V319.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V319.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId) Evergreen.V319.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId) Evergreen.V319.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V319.Call.CallId (Evergreen.V319.NonemptyDict.NonemptyDict ( Evergreen.V319.Id.Id Evergreen.V319.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V319.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V319.Go.PublicGoMatchData Evergreen.V319.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V319.Route.Route
    , windowSize : Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V319.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V319.Audio.LoadError Evergreen.V319.Audio.Source
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V319.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V319.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V319.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V319.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V319.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.ChannelName.ChannelName Evergreen.V319.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.ChannelName.ChannelName Evergreen.V319.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.UserSession.ToBeFilledInByBackend (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V319.GuildName.GuildName (Evergreen.V319.UserSession.ToBeFilledInByBackend (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V319.Id.DiscordGuildOrDmId_DmData (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V319.UserSession.SetViewing
    | Local_SetName Evergreen.V319.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V319.Id.GuildOrDmId (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V319.Id.GuildOrDmId (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId) (Evergreen.V319.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V319.Id.DiscordGuildOrDmId (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V319.Id.DiscordGuildOrDmId (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId) (Evergreen.V319.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V319.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V319.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V319.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V319.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V319.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V319.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V319.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V319.NonemptySet.NonemptySet (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V319.Call.LocalChange
    | Local_Game Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Game.LocalChange
    | Local_Drawing Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Drawing.AnchorType Evergreen.V319.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Effect.Time.Posix Evergreen.V319.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V319.RichText.RichText (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))) Evergreen.V319.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId) Evergreen.V319.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V319.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V319.RichText.RichText (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))) Evergreen.V319.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId) Evergreen.V319.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.ChannelName.ChannelName Evergreen.V319.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.ChannelName.ChannelName Evergreen.V319.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V319.LocalState.JoinGuildError
            { guildId : Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId
            , guild : Evergreen.V319.LocalState.FrontendGuild
            , owner : Evergreen.V319.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V319.RichText.RichText (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))) (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V319.RichText.RichText (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V319.Id.DiscordGuildOrDmId_DmData (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V319.RichText.RichText (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V319.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V319.SessionIdHash.SessionIdHash Evergreen.V319.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V319.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V319.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V319.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V319.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Evergreen.V319.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.ChannelName.ChannelName (Evergreen.V319.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
        (Evergreen.V319.NonemptyDict.NonemptyDict
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) Evergreen.V319.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Evergreen.V319.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Maybe (Evergreen.V319.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V319.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V319.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V319.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V319.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V319.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V319.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) (Evergreen.V319.Discord.OptionalData String) (Evergreen.V319.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
        (Evergreen.V319.MembersAndOwner.MembersAndOwner
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Evergreen.V319.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId) Evergreen.V319.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId) Evergreen.V319.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V319.Call.ServerChange
    | Server_Game (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Game.LocalChange
    | Server_Drawing (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Drawing.AnchorType Evergreen.V319.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V319.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V319.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V319.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V319.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V319.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V319.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V319.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V319.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V319.Id.AnyGuildOrDmId Evergreen.V319.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V319.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels) (Maybe Evergreen.V319.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId) (Evergreen.V319.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V319.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V319.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V319.Local.Local LocalMsg Evergreen.V319.LocalState.LocalState
    , admin : Evergreen.V319.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId, Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V319.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V319.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V319.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V319.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ) (Evergreen.V319.NonemptyDict.NonemptyDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V319.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V319.Scroll.ScrollPosition
    , textEditor : Evergreen.V319.TextEditor.Model
    , profilePictureEditor : Evergreen.V319.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId, Evergreen.V319.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V319.Emoji.Model
    , voiceChat : Evergreen.V319.Call.Model
    , games : SeqDict.SeqDict Evergreen.V319.Id.GuildOrDmId Evergreen.V319.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V319.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
    , friendsSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V319.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V319.Range.Range
                , direction : Evergreen.V319.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V319.NonemptyDict.NonemptyDict Int Evergreen.V319.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V319.NonemptyDict.NonemptyDict Int Evergreen.V319.Touch.Touch
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
    | AdminToFrontend Evergreen.V319.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V319.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V319.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V319.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V319.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V319.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V319.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V319.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V319.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V319.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V319.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V319.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V319.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V319.Audio.LoadError Evergreen.V319.Audio.Source
    , startupData : Evergreen.V319.Ports.StartupData
    , lastUrlChange : Maybe Effect.Time.Posix
    , routingLog :
        List
            { time : Effect.Time.Posix
            , entry : String
            }
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V319.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V319.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V319.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V319.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V319.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId, Evergreen.V319.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V319.DmChannelId.DmChannelId, Evergreen.V319.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId, Evergreen.V319.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId, Evergreen.V319.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V319.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V319.NonemptyDict.NonemptyDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V319.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V319.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V319.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V319.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V319.DmChannelId.DmChannelId Evergreen.V319.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) Evergreen.V319.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.Slack.Id Evergreen.V319.Slack.ChannelId) Evergreen.V319.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V319.OneToOne.OneToOne String (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    , slackUsers : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.Slack.Id Evergreen.V319.Slack.UserId) (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    , slackServers : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.Slack.Id Evergreen.V319.Slack.TeamId) (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    , slackToken : Maybe Evergreen.V319.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V319.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V319.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V319.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V319.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V319.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V319.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V319.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V319.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Evergreen.V319.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId, Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V319.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V319.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V319.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V319.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.LocalState.LoadingDiscordChannel (List Evergreen.V319.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V319.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId) Evergreen.V319.Sticker.StickerData
    , discordStickers : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.Discord.Id Evergreen.V319.Discord.StickerId) (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId) Evergreen.V319.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V319.OneToOne.OneToOne Evergreen.V319.RichText.DiscordCustomEmojiIdAndName (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V319.Postmark.ApiKey
    , serverSecret : Evergreen.V319.SecretId.SecretId Evergreen.V319.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V319.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.GamePublicId) ( Evergreen.V319.DmChannelId.GuildOrFullDmId, Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V319.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V319.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V319.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V319.DmChannelId.DmChannelId Evergreen.V319.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V319.Id.DiscordGuildOrDmId Evergreen.V319.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V319.Id.Id Evergreen.V319.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V319.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V319.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V319.Untrusted.Untrusted Evergreen.V319.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V319.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V319.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V319.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V319.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V319.PersonName.PersonName Evergreen.V319.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V319.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V319.Slack.OAuthCode Evergreen.V319.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V319.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V319.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V319.Id.Id Evergreen.V319.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V319.EmailAddress.EmailAddress (Result Evergreen.V319.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V319.EmailAddress.EmailAddress (Result Evergreen.V319.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V319.EmailAddress.EmailAddress (Result Evergreen.V319.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V319.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMaybeMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Result Evergreen.V319.Discord.HttpError Evergreen.V319.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V319.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Result Evergreen.V319.Discord.HttpError Evergreen.V319.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) (Result Evergreen.V319.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) (Result Evergreen.V319.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) (Result Evergreen.V319.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) (Result Evergreen.V319.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji (Result Evergreen.V319.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji (Result Evergreen.V319.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji (Result Evergreen.V319.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji (Result Evergreen.V319.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V319.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V319.Discord.HttpError (List ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId, Maybe Evergreen.V319.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Effect.Time.Posix Evergreen.V319.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V319.Slack.CurrentUser
            , team : Evergreen.V319.Slack.Team
            , users : List Evergreen.V319.Slack.User
            , channels : List ( Evergreen.V319.Slack.Channel, List Evergreen.V319.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Result Effect.Http.Error Evergreen.V319.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V319.Local.ChangeId Effect.Time.Posix Evergreen.V319.Call.CallId Evergreen.V319.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V319.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V319.Local.ChangeId Effect.Time.Posix Evergreen.V319.Call.CallId Evergreen.V319.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V319.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V319.Local.ChangeId Evergreen.V319.Call.ConnectionId Evergreen.V319.Cloudflare.RealtimeSessionId (List Evergreen.V319.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V319.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V319.Local.ChangeId Evergreen.V319.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Discord.UserAuth (Result Evergreen.V319.Discord.HttpError Evergreen.V319.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Result Evergreen.V319.Discord.HttpError Evergreen.V319.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
        (Result
            Evergreen.V319.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId
                , members : List (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
                }
            , List
                ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId
                , { guild : Evergreen.V319.Discord.GatewayGuild
                  , channels : List Evergreen.V319.Discord.Channel
                  , icon : Maybe Evergreen.V319.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Bool Evergreen.V319.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V319.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.AttachmentId, Evergreen.V319.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V319.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.AttachmentId, Evergreen.V319.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V319.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V319.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V319.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V319.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) (Result Evergreen.V319.Discord.HttpError (List Evergreen.V319.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Result Evergreen.V319.Discord.HttpError (List Evergreen.V319.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V319.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V319.DmChannelId.DmChannelId Evergreen.V319.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V319.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V319.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V319.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
        (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V319.Discord.HttpError
            { guild : Evergreen.V319.Discord.GatewayGuild
            , channels : List Evergreen.V319.Discord.Channel
            , icon : Maybe Evergreen.V319.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Result Evergreen.V319.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V319.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (List ( Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId, Result Effect.Http.Error Evergreen.V319.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId, Result Effect.Http.Error Evergreen.V319.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (List ( Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V319.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V319.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V319.Discord.HttpError (List Evergreen.V319.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V319.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V319.SecretId.SecretId Evergreen.V319.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V319.FileStatus.FileHash Int (Maybe (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
