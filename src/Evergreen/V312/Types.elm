module Evergreen.V312.Types exposing (..)

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
import Evergreen.V312.AiChat
import Evergreen.V312.Audio
import Evergreen.V312.Call
import Evergreen.V312.ChannelDescription
import Evergreen.V312.ChannelName
import Evergreen.V312.Cloudflare
import Evergreen.V312.Coord
import Evergreen.V312.CssPixels
import Evergreen.V312.CustomEmoji
import Evergreen.V312.Discord
import Evergreen.V312.DiscordAttachmentId
import Evergreen.V312.DiscordUserData
import Evergreen.V312.DmChannel
import Evergreen.V312.DmChannelId
import Evergreen.V312.Drawing
import Evergreen.V312.Editable
import Evergreen.V312.EmailAddress
import Evergreen.V312.Embed
import Evergreen.V312.Emoji
import Evergreen.V312.FileStatus
import Evergreen.V312.Game
import Evergreen.V312.Go
import Evergreen.V312.GuildName
import Evergreen.V312.Id
import Evergreen.V312.ImageEditor
import Evergreen.V312.ImageViewer
import Evergreen.V312.LinkedAndOtherDiscordUsers
import Evergreen.V312.Local
import Evergreen.V312.LocalState
import Evergreen.V312.Log
import Evergreen.V312.LoginForm
import Evergreen.V312.MembersAndOwner
import Evergreen.V312.Message
import Evergreen.V312.MessageInput
import Evergreen.V312.MessageView
import Evergreen.V312.MyUi
import Evergreen.V312.NonemptyDict
import Evergreen.V312.NonemptySet
import Evergreen.V312.OneOrGreater
import Evergreen.V312.OneToOne
import Evergreen.V312.Pages.Admin
import Evergreen.V312.Pagination
import Evergreen.V312.PersonName
import Evergreen.V312.Ports
import Evergreen.V312.Postmark
import Evergreen.V312.Range
import Evergreen.V312.RichText
import Evergreen.V312.Route
import Evergreen.V312.Scroll
import Evergreen.V312.SecretId
import Evergreen.V312.SessionIdHash
import Evergreen.V312.Slack
import Evergreen.V312.Sticker
import Evergreen.V312.TextEditor
import Evergreen.V312.ToBackendLog
import Evergreen.V312.Touch
import Evergreen.V312.TwoFactorAuthentication
import Evergreen.V312.Ui.Anim
import Evergreen.V312.Untrusted
import Evergreen.V312.User
import Evergreen.V312.UserAgent
import Evergreen.V312.UserSession
import List.Nonempty
import Quantity
import SeqDict
import Set
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


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V312.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V312.Pages.Admin.Msg
    | PressedLogOut Evergreen.V312.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V312.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V312.Route.Route
    | SelectedFilesToAttach ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V312.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V312.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V312.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V312.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V312.NonemptyDict.NonemptyDict Int Evergreen.V312.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V312.NonemptyDict.NonemptyDict Int Evergreen.V312.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRoute Evergreen.V312.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V312.NonemptySet.NonemptySet (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V312.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V312.AiChat.Msg
    | GameMsg Evergreen.V312.Game.Msg
    | GoSpectatorMsg Evergreen.V312.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V312.Editable.Msg Evergreen.V312.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V312.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V312.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
        { fileId : Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
        { fileId : Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V312.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage Evergreen.V312.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V312.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V312.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V312.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V312.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.User.NotificationLevel
    | GotStartupData Evergreen.V312.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V312.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId
        , otherUserId : Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRoute Evergreen.V312.MessageInput.Msg
    | MessageInputMsg Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRoute Evergreen.V312.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V312.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V312.Range.Range, Evergreen.V312.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V312.Range.Range, Evergreen.V312.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V312.Call.FromJs)
    | VoiceChatMsg Evergreen.V312.Call.Msg
    | PressedChannelHeaderTab Evergreen.V312.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V312.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V312.Audio.LoadError Evergreen.V312.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V312.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V312.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) Evergreen.V312.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.LocalState.DiscordFrontendGuild
    , user : Evergreen.V312.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.User.FrontendUser
    , discordUsers : Evergreen.V312.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V312.SessionIdHash.SessionIdHash Evergreen.V312.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V312.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId) Evergreen.V312.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId) Evergreen.V312.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V312.Call.CallId (Evergreen.V312.NonemptyDict.NonemptyDict ( Evergreen.V312.Id.Id Evergreen.V312.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V312.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V312.Go.PublicGoMatchData Evergreen.V312.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V312.Route.Route
    , windowSize : Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V312.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V312.Audio.LoadError Evergreen.V312.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V312.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V312.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V312.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V312.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V312.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.ChannelName.ChannelName Evergreen.V312.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.ChannelName.ChannelName Evergreen.V312.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.UserSession.ToBeFilledInByBackend (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V312.GuildName.GuildName (Evergreen.V312.UserSession.ToBeFilledInByBackend (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V312.Id.DiscordGuildOrDmId_DmData (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V312.UserSession.SetViewing
    | Local_SetName Evergreen.V312.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V312.Id.GuildOrDmId (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V312.Id.GuildOrDmId (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId) (Evergreen.V312.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V312.Id.DiscordGuildOrDmId (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V312.Id.DiscordGuildOrDmId (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId) (Evergreen.V312.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V312.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V312.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V312.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V312.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V312.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V312.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V312.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V312.NonemptySet.NonemptySet (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V312.Call.LocalChange
    | Local_Game Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Game.LocalChange
    | Local_Drawing Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Drawing.AnchorType Evergreen.V312.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Effect.Time.Posix Evergreen.V312.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V312.RichText.RichText (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))) Evergreen.V312.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId) Evergreen.V312.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V312.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V312.RichText.RichText (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))) Evergreen.V312.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId) Evergreen.V312.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.ChannelName.ChannelName Evergreen.V312.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.ChannelName.ChannelName Evergreen.V312.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V312.LocalState.JoinGuildError
            { guildId : Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId
            , guild : Evergreen.V312.LocalState.FrontendGuild
            , owner : Evergreen.V312.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V312.RichText.RichText (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))) (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V312.RichText.RichText (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V312.Id.DiscordGuildOrDmId_DmData (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V312.RichText.RichText (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V312.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V312.SessionIdHash.SessionIdHash Evergreen.V312.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V312.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V312.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V312.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V312.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Evergreen.V312.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.ChannelName.ChannelName (Evergreen.V312.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
        (Evergreen.V312.NonemptyDict.NonemptyDict
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) Evergreen.V312.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Evergreen.V312.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Maybe (Evergreen.V312.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V312.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V312.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V312.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V312.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V312.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V312.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) (Evergreen.V312.Discord.OptionalData String) (Evergreen.V312.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
        (Evergreen.V312.MembersAndOwner.MembersAndOwner
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Evergreen.V312.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId) Evergreen.V312.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId) Evergreen.V312.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V312.Call.ServerChange
    | Server_Game (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Game.LocalChange
    | Server_Drawing (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Drawing.AnchorType Evergreen.V312.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V312.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V312.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V312.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V312.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V312.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V312.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V312.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V312.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V312.Id.AnyGuildOrDmId Evergreen.V312.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V312.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels) (Maybe Evergreen.V312.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId) (Evergreen.V312.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V312.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V312.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V312.Local.Local LocalMsg Evergreen.V312.LocalState.LocalState
    , admin : Evergreen.V312.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId, Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V312.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V312.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V312.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V312.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ) (Evergreen.V312.NonemptyDict.NonemptyDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V312.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V312.Scroll.ScrollPosition
    , textEditor : Evergreen.V312.TextEditor.Model
    , profilePictureEditor : Evergreen.V312.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId, Evergreen.V312.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V312.Emoji.Model
    , voiceChat : Evergreen.V312.Call.Model
    , games : SeqDict.SeqDict Evergreen.V312.Id.GuildOrDmId Evergreen.V312.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V312.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V312.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V312.Range.Range
                , direction : Evergreen.V312.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V312.NonemptyDict.NonemptyDict Int Evergreen.V312.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V312.NonemptyDict.NonemptyDict Int Evergreen.V312.Touch.Touch
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
    | AdminToFrontend Evergreen.V312.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V312.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V312.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V312.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V312.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V312.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V312.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V312.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V312.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V312.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V312.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V312.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V312.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V312.Audio.LoadError Evergreen.V312.Audio.Source
    , startupData : Evergreen.V312.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V312.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V312.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V312.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V312.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V312.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId, Evergreen.V312.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V312.DmChannelId.DmChannelId, Evergreen.V312.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId, Evergreen.V312.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId, Evergreen.V312.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V312.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V312.NonemptyDict.NonemptyDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V312.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V312.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V312.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V312.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V312.DmChannelId.DmChannelId Evergreen.V312.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) Evergreen.V312.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.Slack.Id Evergreen.V312.Slack.ChannelId) Evergreen.V312.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V312.OneToOne.OneToOne String (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    , slackUsers : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.Slack.Id Evergreen.V312.Slack.UserId) (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
    , slackServers : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.Slack.Id Evergreen.V312.Slack.TeamId) (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    , slackToken : Maybe Evergreen.V312.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V312.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V312.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V312.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V312.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V312.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V312.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V312.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V312.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Evergreen.V312.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId, Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V312.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V312.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V312.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V312.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.LocalState.LoadingDiscordChannel (List Evergreen.V312.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V312.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId) Evergreen.V312.Sticker.StickerData
    , discordStickers : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.Discord.Id Evergreen.V312.Discord.StickerId) (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId) Evergreen.V312.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V312.OneToOne.OneToOne Evergreen.V312.RichText.DiscordCustomEmojiIdAndName (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V312.Postmark.ApiKey
    , serverSecret : Evergreen.V312.SecretId.SecretId Evergreen.V312.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V312.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.GamePublicId) ( Evergreen.V312.DmChannelId.GuildOrFullDmId, Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V312.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V312.DmChannelId.DmChannelId Evergreen.V312.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V312.Id.DiscordGuildOrDmId Evergreen.V312.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V312.Id.Id Evergreen.V312.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V312.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V312.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V312.Untrusted.Untrusted Evergreen.V312.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V312.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V312.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V312.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V312.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V312.PersonName.PersonName Evergreen.V312.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V312.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V312.Slack.OAuthCode Evergreen.V312.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V312.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V312.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V312.Id.Id Evergreen.V312.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V312.EmailAddress.EmailAddress (Result Evergreen.V312.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V312.EmailAddress.EmailAddress (Result Evergreen.V312.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V312.EmailAddress.EmailAddress (Result Evergreen.V312.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V312.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMaybeMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Result Evergreen.V312.Discord.HttpError Evergreen.V312.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V312.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Result Evergreen.V312.Discord.HttpError Evergreen.V312.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) (Result Evergreen.V312.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) (Result Evergreen.V312.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) (Result Evergreen.V312.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) (Result Evergreen.V312.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji (Result Evergreen.V312.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji (Result Evergreen.V312.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji (Result Evergreen.V312.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji (Result Evergreen.V312.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V312.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V312.Discord.HttpError (List ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId, Maybe Evergreen.V312.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Effect.Time.Posix Evergreen.V312.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V312.Slack.CurrentUser
            , team : Evergreen.V312.Slack.Team
            , users : List Evergreen.V312.Slack.User
            , channels : List ( Evergreen.V312.Slack.Channel, List Evergreen.V312.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Result Effect.Http.Error Evergreen.V312.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V312.Local.ChangeId Effect.Time.Posix Evergreen.V312.Call.CallId Evergreen.V312.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V312.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V312.Local.ChangeId Effect.Time.Posix Evergreen.V312.Call.CallId Evergreen.V312.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V312.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V312.Local.ChangeId Evergreen.V312.Call.ConnectionId Evergreen.V312.Cloudflare.RealtimeSessionId (List Evergreen.V312.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V312.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V312.Local.ChangeId Evergreen.V312.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Discord.UserAuth (Result Evergreen.V312.Discord.HttpError Evergreen.V312.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Result Evergreen.V312.Discord.HttpError Evergreen.V312.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
        (Result
            Evergreen.V312.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId
                , members : List (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
                }
            , List
                ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId
                , { guild : Evergreen.V312.Discord.GatewayGuild
                  , channels : List Evergreen.V312.Discord.Channel
                  , icon : Maybe Evergreen.V312.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Bool Evergreen.V312.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V312.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.AttachmentId, Evergreen.V312.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V312.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.AttachmentId, Evergreen.V312.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V312.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V312.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V312.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V312.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) (Result Evergreen.V312.Discord.HttpError (List Evergreen.V312.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Result Evergreen.V312.Discord.HttpError (List Evergreen.V312.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V312.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V312.DmChannelId.DmChannelId Evergreen.V312.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V312.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V312.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V312.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
        (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V312.Discord.HttpError
            { guild : Evergreen.V312.Discord.GatewayGuild
            , channels : List Evergreen.V312.Discord.Channel
            , icon : Maybe Evergreen.V312.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Result Evergreen.V312.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V312.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (List ( Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId, Result Effect.Http.Error Evergreen.V312.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId, Result Effect.Http.Error Evergreen.V312.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (List ( Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V312.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V312.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V312.Discord.HttpError (List Evergreen.V312.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V312.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V312.SecretId.SecretId Evergreen.V312.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V312.FileStatus.FileHash Int (Maybe (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
