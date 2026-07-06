module Evergreen.V304.Types exposing (..)

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
import Evergreen.V304.AiChat
import Evergreen.V304.Audio
import Evergreen.V304.Call
import Evergreen.V304.ChannelDescription
import Evergreen.V304.ChannelName
import Evergreen.V304.Cloudflare
import Evergreen.V304.Coord
import Evergreen.V304.CssPixels
import Evergreen.V304.CustomEmoji
import Evergreen.V304.Discord
import Evergreen.V304.DiscordAttachmentId
import Evergreen.V304.DiscordUserData
import Evergreen.V304.DmChannel
import Evergreen.V304.DmChannelId
import Evergreen.V304.Drawing
import Evergreen.V304.Editable
import Evergreen.V304.EmailAddress
import Evergreen.V304.Embed
import Evergreen.V304.Emoji
import Evergreen.V304.FileStatus
import Evergreen.V304.Game
import Evergreen.V304.Go
import Evergreen.V304.GuildName
import Evergreen.V304.Id
import Evergreen.V304.ImageEditor
import Evergreen.V304.ImageViewer
import Evergreen.V304.LinkedAndOtherDiscordUsers
import Evergreen.V304.Local
import Evergreen.V304.LocalState
import Evergreen.V304.Log
import Evergreen.V304.LoginForm
import Evergreen.V304.MembersAndOwner
import Evergreen.V304.Message
import Evergreen.V304.MessageInput
import Evergreen.V304.MessageView
import Evergreen.V304.MyUi
import Evergreen.V304.NonemptyDict
import Evergreen.V304.NonemptySet
import Evergreen.V304.OneOrGreater
import Evergreen.V304.OneToOne
import Evergreen.V304.Pages.Admin
import Evergreen.V304.Pagination
import Evergreen.V304.PersonName
import Evergreen.V304.Ports
import Evergreen.V304.Postmark
import Evergreen.V304.Range
import Evergreen.V304.RichText
import Evergreen.V304.Route
import Evergreen.V304.SecretId
import Evergreen.V304.SessionIdHash
import Evergreen.V304.Slack
import Evergreen.V304.Sticker
import Evergreen.V304.TextEditor
import Evergreen.V304.ToBackendLog
import Evergreen.V304.Touch
import Evergreen.V304.TwoFactorAuthentication
import Evergreen.V304.Ui.Anim
import Evergreen.V304.Untrusted
import Evergreen.V304.User
import Evergreen.V304.UserAgent
import Evergreen.V304.UserSession
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


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V304.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V304.Pages.Admin.Msg
    | PressedLogOut Evergreen.V304.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V304.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V304.Route.Route
    | SelectedFilesToAttach ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V304.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V304.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V304.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V304.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V304.NonemptyDict.NonemptyDict Int Evergreen.V304.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V304.NonemptyDict.NonemptyDict Int Evergreen.V304.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V304.NonemptySet.NonemptySet (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V304.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V304.AiChat.Msg
    | GameMsg Evergreen.V304.Game.Msg
    | GoSpectatorMsg Evergreen.V304.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V304.Editable.Msg Evergreen.V304.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V304.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V304.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
        { fileId : Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
        { fileId : Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V304.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage Evergreen.V304.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V304.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V304.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V304.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V304.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.User.NotificationLevel
    | GotStartupData Evergreen.V304.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V304.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId
        , otherUserId : Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRoute Evergreen.V304.MessageInput.Msg
    | MessageInputMsg Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRoute Evergreen.V304.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V304.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V304.Range.Range, Evergreen.V304.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V304.Range.Range, Evergreen.V304.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V304.Call.FromJs)
    | VoiceChatMsg Evergreen.V304.Call.Msg
    | PressedChannelHeaderTab Evergreen.V304.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V304.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V304.Audio.LoadError Evergreen.V304.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V304.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V304.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) Evergreen.V304.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.LocalState.DiscordFrontendGuild
    , user : Evergreen.V304.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.User.FrontendUser
    , discordUsers : Evergreen.V304.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V304.SessionIdHash.SessionIdHash Evergreen.V304.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V304.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId) Evergreen.V304.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId) Evergreen.V304.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V304.Call.CallId (Evergreen.V304.NonemptyDict.NonemptyDict ( Evergreen.V304.Id.Id Evergreen.V304.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V304.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V304.Go.PublicGoMatchData Evergreen.V304.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V304.Route.Route
    , windowSize : Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V304.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V304.Audio.LoadError Evergreen.V304.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V304.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V304.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V304.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V304.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V304.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.ChannelName.ChannelName Evergreen.V304.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.ChannelName.ChannelName Evergreen.V304.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.UserSession.ToBeFilledInByBackend (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V304.GuildName.GuildName (Evergreen.V304.UserSession.ToBeFilledInByBackend (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V304.Id.DiscordGuildOrDmId_DmData (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V304.UserSession.SetViewing
    | Local_SetName Evergreen.V304.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V304.Id.GuildOrDmId (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V304.Id.GuildOrDmId (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId) (Evergreen.V304.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V304.Id.DiscordGuildOrDmId (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V304.Id.DiscordGuildOrDmId (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId) (Evergreen.V304.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V304.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V304.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V304.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V304.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V304.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V304.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V304.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V304.NonemptySet.NonemptySet (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V304.Call.LocalChange
    | Local_Game Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Game.LocalChange
    | Local_Drawing Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Drawing.AnchorType Evergreen.V304.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Effect.Time.Posix Evergreen.V304.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V304.RichText.RichText (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))) Evergreen.V304.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId) Evergreen.V304.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V304.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V304.RichText.RichText (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))) Evergreen.V304.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId) Evergreen.V304.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.ChannelName.ChannelName Evergreen.V304.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.ChannelName.ChannelName Evergreen.V304.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V304.LocalState.JoinGuildError
            { guildId : Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId
            , guild : Evergreen.V304.LocalState.FrontendGuild
            , owner : Evergreen.V304.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V304.RichText.RichText (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))) (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V304.RichText.RichText (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V304.Id.DiscordGuildOrDmId_DmData (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V304.RichText.RichText (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V304.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V304.SessionIdHash.SessionIdHash Evergreen.V304.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V304.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V304.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V304.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V304.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Evergreen.V304.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.ChannelName.ChannelName (Evergreen.V304.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
        (Evergreen.V304.NonemptyDict.NonemptyDict
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) Evergreen.V304.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Evergreen.V304.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Maybe (Evergreen.V304.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V304.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V304.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V304.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V304.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V304.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V304.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) (Evergreen.V304.Discord.OptionalData String) (Evergreen.V304.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
        (Evergreen.V304.MembersAndOwner.MembersAndOwner
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Evergreen.V304.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId) Evergreen.V304.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId) Evergreen.V304.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V304.Call.ServerChange
    | Server_Game (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Game.LocalChange
    | Server_Drawing (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Drawing.AnchorType Evergreen.V304.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V304.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V304.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V304.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V304.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V304.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V304.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V304.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V304.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V304.Id.AnyGuildOrDmId Evergreen.V304.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V304.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels) (Maybe Evergreen.V304.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId) (Evergreen.V304.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V304.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V304.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V304.Local.Local LocalMsg Evergreen.V304.LocalState.LocalState
    , admin : Evergreen.V304.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId, Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V304.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V304.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V304.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V304.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ) (Evergreen.V304.NonemptyDict.NonemptyDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V304.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V304.TextEditor.Model
    , profilePictureEditor : Evergreen.V304.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId, Evergreen.V304.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V304.Emoji.Model
    , voiceChat : Evergreen.V304.Call.Model
    , games : SeqDict.SeqDict Evergreen.V304.Id.GuildOrDmId Evergreen.V304.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V304.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V304.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V304.Range.Range
                , direction : Evergreen.V304.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V304.NonemptyDict.NonemptyDict Int Evergreen.V304.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V304.NonemptyDict.NonemptyDict Int Evergreen.V304.Touch.Touch
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
    | AdminToFrontend Evergreen.V304.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V304.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V304.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V304.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V304.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V304.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V304.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V304.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V304.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V304.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V304.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V304.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V304.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V304.Audio.LoadError Evergreen.V304.Audio.Source
    , startupData : Evergreen.V304.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V304.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V304.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V304.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V304.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V304.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId, Evergreen.V304.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V304.DmChannelId.DmChannelId, Evergreen.V304.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId, Evergreen.V304.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId, Evergreen.V304.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V304.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V304.NonemptyDict.NonemptyDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V304.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V304.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V304.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V304.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V304.DmChannelId.DmChannelId Evergreen.V304.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) Evergreen.V304.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.Slack.Id Evergreen.V304.Slack.ChannelId) Evergreen.V304.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V304.OneToOne.OneToOne String (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    , slackUsers : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.Slack.Id Evergreen.V304.Slack.UserId) (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
    , slackServers : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.Slack.Id Evergreen.V304.Slack.TeamId) (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    , slackToken : Maybe Evergreen.V304.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V304.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V304.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V304.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V304.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V304.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V304.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V304.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V304.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Evergreen.V304.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId, Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V304.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V304.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V304.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V304.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.LocalState.LoadingDiscordChannel (List Evergreen.V304.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V304.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId) Evergreen.V304.Sticker.StickerData
    , discordStickers : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.Discord.Id Evergreen.V304.Discord.StickerId) (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId) Evergreen.V304.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V304.OneToOne.OneToOne Evergreen.V304.RichText.DiscordCustomEmojiIdAndName (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V304.Postmark.ApiKey
    , serverSecret : Evergreen.V304.SecretId.SecretId Evergreen.V304.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V304.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.GamePublicId) ( Evergreen.V304.DmChannelId.GuildOrFullDmId, Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V304.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V304.DmChannelId.DmChannelId Evergreen.V304.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V304.Id.DiscordGuildOrDmId Evergreen.V304.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V304.Id.Id Evergreen.V304.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V304.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V304.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V304.Untrusted.Untrusted Evergreen.V304.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V304.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V304.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V304.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V304.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V304.PersonName.PersonName Evergreen.V304.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V304.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V304.Slack.OAuthCode Evergreen.V304.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V304.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V304.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V304.Id.Id Evergreen.V304.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V304.EmailAddress.EmailAddress (Result Evergreen.V304.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V304.EmailAddress.EmailAddress (Result Evergreen.V304.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V304.EmailAddress.EmailAddress (Result Evergreen.V304.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V304.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMaybeMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Result Evergreen.V304.Discord.HttpError Evergreen.V304.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V304.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Result Evergreen.V304.Discord.HttpError Evergreen.V304.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) (Result Evergreen.V304.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) (Result Evergreen.V304.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) (Result Evergreen.V304.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) (Result Evergreen.V304.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji (Result Evergreen.V304.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji (Result Evergreen.V304.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji (Result Evergreen.V304.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji (Result Evergreen.V304.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V304.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V304.Discord.HttpError (List ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId, Maybe Evergreen.V304.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Effect.Time.Posix Evergreen.V304.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V304.Slack.CurrentUser
            , team : Evergreen.V304.Slack.Team
            , users : List Evergreen.V304.Slack.User
            , channels : List ( Evergreen.V304.Slack.Channel, List Evergreen.V304.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Result Effect.Http.Error Evergreen.V304.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V304.Local.ChangeId Effect.Time.Posix Evergreen.V304.Call.CallId Evergreen.V304.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V304.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V304.Local.ChangeId Effect.Time.Posix Evergreen.V304.Call.CallId Evergreen.V304.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V304.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V304.Local.ChangeId Evergreen.V304.Call.ConnectionId Evergreen.V304.Cloudflare.RealtimeSessionId (List Evergreen.V304.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V304.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V304.Local.ChangeId Evergreen.V304.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Discord.UserAuth (Result Evergreen.V304.Discord.HttpError Evergreen.V304.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Result Evergreen.V304.Discord.HttpError Evergreen.V304.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
        (Result
            Evergreen.V304.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId
                , members : List (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
                }
            , List
                ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId
                , { guild : Evergreen.V304.Discord.GatewayGuild
                  , channels : List Evergreen.V304.Discord.Channel
                  , icon : Maybe Evergreen.V304.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Bool Evergreen.V304.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V304.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.AttachmentId, Evergreen.V304.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V304.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.AttachmentId, Evergreen.V304.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V304.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V304.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V304.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V304.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) (Result Evergreen.V304.Discord.HttpError (List Evergreen.V304.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Result Evergreen.V304.Discord.HttpError (List Evergreen.V304.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V304.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V304.DmChannelId.DmChannelId Evergreen.V304.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V304.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V304.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V304.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
        (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V304.Discord.HttpError
            { guild : Evergreen.V304.Discord.GatewayGuild
            , channels : List Evergreen.V304.Discord.Channel
            , icon : Maybe Evergreen.V304.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Result Evergreen.V304.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V304.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (List ( Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId, Result Effect.Http.Error Evergreen.V304.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId, Result Effect.Http.Error Evergreen.V304.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (List ( Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V304.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V304.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V304.Discord.HttpError (List Evergreen.V304.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V304.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V304.SecretId.SecretId Evergreen.V304.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V304.FileStatus.FileHash Int (Maybe (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
