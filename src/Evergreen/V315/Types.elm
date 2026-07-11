module Evergreen.V315.Types exposing (..)

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
import Evergreen.V315.AiChat
import Evergreen.V315.Audio
import Evergreen.V315.Call
import Evergreen.V315.ChannelDescription
import Evergreen.V315.ChannelName
import Evergreen.V315.Cloudflare
import Evergreen.V315.Coord
import Evergreen.V315.CssPixels
import Evergreen.V315.CustomEmoji
import Evergreen.V315.Discord
import Evergreen.V315.DiscordAttachmentId
import Evergreen.V315.DiscordUserData
import Evergreen.V315.DmChannel
import Evergreen.V315.DmChannelId
import Evergreen.V315.Drawing
import Evergreen.V315.Editable
import Evergreen.V315.EmailAddress
import Evergreen.V315.Embed
import Evergreen.V315.Emoji
import Evergreen.V315.FileStatus
import Evergreen.V315.Game
import Evergreen.V315.Go
import Evergreen.V315.GuildName
import Evergreen.V315.Id
import Evergreen.V315.ImageEditor
import Evergreen.V315.ImageViewer
import Evergreen.V315.LinkedAndOtherDiscordUsers
import Evergreen.V315.Local
import Evergreen.V315.LocalState
import Evergreen.V315.Log
import Evergreen.V315.LoginForm
import Evergreen.V315.MembersAndOwner
import Evergreen.V315.Message
import Evergreen.V315.MessageInput
import Evergreen.V315.MessageView
import Evergreen.V315.MyUi
import Evergreen.V315.NonemptyDict
import Evergreen.V315.NonemptySet
import Evergreen.V315.OneOrGreater
import Evergreen.V315.OneToOne
import Evergreen.V315.Pages.Admin
import Evergreen.V315.Pagination
import Evergreen.V315.PersonName
import Evergreen.V315.Ports
import Evergreen.V315.Postmark
import Evergreen.V315.Range
import Evergreen.V315.RichText
import Evergreen.V315.Route
import Evergreen.V315.Scroll
import Evergreen.V315.SecretId
import Evergreen.V315.SessionIdHash
import Evergreen.V315.Slack
import Evergreen.V315.Sticker
import Evergreen.V315.TextEditor
import Evergreen.V315.ToBackendLog
import Evergreen.V315.Touch
import Evergreen.V315.TwoFactorAuthentication
import Evergreen.V315.Ui.Anim
import Evergreen.V315.Untrusted
import Evergreen.V315.User
import Evergreen.V315.UserAgent
import Evergreen.V315.UserSession
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
    | LoginFormMsg Evergreen.V315.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V315.Pages.Admin.Msg
    | PressedLogOut Evergreen.V315.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V315.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V315.Route.Route
    | SelectedFilesToAttach ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V315.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V315.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V315.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V315.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V315.NonemptyDict.NonemptyDict Int Evergreen.V315.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V315.NonemptyDict.NonemptyDict Int Evergreen.V315.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRoute Evergreen.V315.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V315.NonemptySet.NonemptySet (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V315.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V315.AiChat.Msg
    | GameMsg Evergreen.V315.Game.Msg
    | GoSpectatorMsg Evergreen.V315.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V315.Editable.Msg Evergreen.V315.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V315.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V315.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
        { fileId : Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
        { fileId : Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V315.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage Evergreen.V315.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V315.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V315.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V315.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V315.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.User.NotificationLevel
    | GotStartupData Evergreen.V315.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V315.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId
        , otherUserId : Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRoute Evergreen.V315.MessageInput.Msg
    | MessageInputMsg Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRoute Evergreen.V315.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V315.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V315.Range.Range, Evergreen.V315.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V315.Range.Range, Evergreen.V315.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V315.Call.FromJs)
    | VoiceChatMsg Evergreen.V315.Call.Msg
    | PressedChannelHeaderTab Evergreen.V315.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V315.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V315.Audio.LoadError Evergreen.V315.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V315.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V315.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) Evergreen.V315.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.LocalState.DiscordFrontendGuild
    , user : Evergreen.V315.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.User.FrontendUser
    , discordUsers : Evergreen.V315.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V315.SessionIdHash.SessionIdHash Evergreen.V315.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V315.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId) Evergreen.V315.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId) Evergreen.V315.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V315.Call.CallId (Evergreen.V315.NonemptyDict.NonemptyDict ( Evergreen.V315.Id.Id Evergreen.V315.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V315.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V315.Go.PublicGoMatchData Evergreen.V315.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V315.Route.Route
    , windowSize : Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V315.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V315.Audio.LoadError Evergreen.V315.Audio.Source
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V315.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V315.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V315.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V315.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V315.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.ChannelName.ChannelName Evergreen.V315.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.ChannelName.ChannelName Evergreen.V315.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.UserSession.ToBeFilledInByBackend (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V315.GuildName.GuildName (Evergreen.V315.UserSession.ToBeFilledInByBackend (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V315.Id.DiscordGuildOrDmId_DmData (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V315.UserSession.SetViewing
    | Local_SetName Evergreen.V315.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V315.Id.GuildOrDmId (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V315.Id.GuildOrDmId (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId) (Evergreen.V315.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V315.Id.DiscordGuildOrDmId (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V315.Id.DiscordGuildOrDmId (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId) (Evergreen.V315.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V315.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V315.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V315.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V315.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V315.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V315.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V315.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V315.NonemptySet.NonemptySet (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V315.Call.LocalChange
    | Local_Game Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Game.LocalChange
    | Local_Drawing Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Drawing.AnchorType Evergreen.V315.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Effect.Time.Posix Evergreen.V315.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V315.RichText.RichText (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))) Evergreen.V315.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId) Evergreen.V315.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V315.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V315.RichText.RichText (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))) Evergreen.V315.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId) Evergreen.V315.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.ChannelName.ChannelName Evergreen.V315.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.ChannelName.ChannelName Evergreen.V315.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V315.LocalState.JoinGuildError
            { guildId : Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId
            , guild : Evergreen.V315.LocalState.FrontendGuild
            , owner : Evergreen.V315.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V315.RichText.RichText (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))) (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V315.RichText.RichText (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V315.Id.DiscordGuildOrDmId_DmData (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V315.RichText.RichText (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V315.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V315.SessionIdHash.SessionIdHash Evergreen.V315.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V315.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V315.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V315.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V315.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Evergreen.V315.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.ChannelName.ChannelName (Evergreen.V315.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
        (Evergreen.V315.NonemptyDict.NonemptyDict
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) Evergreen.V315.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Evergreen.V315.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Maybe (Evergreen.V315.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V315.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V315.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V315.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V315.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V315.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V315.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) (Evergreen.V315.Discord.OptionalData String) (Evergreen.V315.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
        (Evergreen.V315.MembersAndOwner.MembersAndOwner
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Evergreen.V315.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId) Evergreen.V315.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId) Evergreen.V315.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V315.Call.ServerChange
    | Server_Game (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Game.LocalChange
    | Server_Drawing (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Drawing.AnchorType Evergreen.V315.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V315.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V315.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V315.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V315.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V315.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V315.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V315.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V315.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V315.Id.AnyGuildOrDmId Evergreen.V315.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V315.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels) (Maybe Evergreen.V315.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId) (Evergreen.V315.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V315.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V315.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V315.Local.Local LocalMsg Evergreen.V315.LocalState.LocalState
    , admin : Evergreen.V315.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId, Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V315.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V315.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V315.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V315.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ) (Evergreen.V315.NonemptyDict.NonemptyDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V315.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V315.Scroll.ScrollPosition
    , textEditor : Evergreen.V315.TextEditor.Model
    , profilePictureEditor : Evergreen.V315.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId, Evergreen.V315.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V315.Emoji.Model
    , voiceChat : Evergreen.V315.Call.Model
    , games : SeqDict.SeqDict Evergreen.V315.Id.GuildOrDmId Evergreen.V315.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V315.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V315.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V315.Range.Range
                , direction : Evergreen.V315.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V315.NonemptyDict.NonemptyDict Int Evergreen.V315.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V315.NonemptyDict.NonemptyDict Int Evergreen.V315.Touch.Touch
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
    | AdminToFrontend Evergreen.V315.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V315.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V315.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V315.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V315.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V315.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V315.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V315.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V315.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V315.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V315.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V315.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V315.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V315.Audio.LoadError Evergreen.V315.Audio.Source
    , startupData : Evergreen.V315.Ports.StartupData
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V315.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V315.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V315.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V315.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V315.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId, Evergreen.V315.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V315.DmChannelId.DmChannelId, Evergreen.V315.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId, Evergreen.V315.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId, Evergreen.V315.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V315.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V315.NonemptyDict.NonemptyDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V315.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V315.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V315.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V315.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V315.DmChannelId.DmChannelId Evergreen.V315.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) Evergreen.V315.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.Slack.Id Evergreen.V315.Slack.ChannelId) Evergreen.V315.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V315.OneToOne.OneToOne String (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    , slackUsers : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.Slack.Id Evergreen.V315.Slack.UserId) (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
    , slackServers : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.Slack.Id Evergreen.V315.Slack.TeamId) (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    , slackToken : Maybe Evergreen.V315.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V315.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V315.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V315.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V315.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V315.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V315.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V315.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V315.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Evergreen.V315.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId, Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V315.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V315.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V315.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V315.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.LocalState.LoadingDiscordChannel (List Evergreen.V315.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V315.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId) Evergreen.V315.Sticker.StickerData
    , discordStickers : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.Discord.Id Evergreen.V315.Discord.StickerId) (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId) Evergreen.V315.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V315.OneToOne.OneToOne Evergreen.V315.RichText.DiscordCustomEmojiIdAndName (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V315.Postmark.ApiKey
    , serverSecret : Evergreen.V315.SecretId.SecretId Evergreen.V315.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V315.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.GamePublicId) ( Evergreen.V315.DmChannelId.GuildOrFullDmId, Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V315.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V315.DmChannelId.DmChannelId Evergreen.V315.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V315.Id.DiscordGuildOrDmId Evergreen.V315.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V315.Id.Id Evergreen.V315.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V315.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V315.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V315.Untrusted.Untrusted Evergreen.V315.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V315.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V315.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V315.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V315.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V315.PersonName.PersonName Evergreen.V315.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V315.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V315.Slack.OAuthCode Evergreen.V315.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V315.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V315.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V315.Id.Id Evergreen.V315.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V315.EmailAddress.EmailAddress (Result Evergreen.V315.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V315.EmailAddress.EmailAddress (Result Evergreen.V315.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V315.EmailAddress.EmailAddress (Result Evergreen.V315.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V315.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMaybeMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Result Evergreen.V315.Discord.HttpError Evergreen.V315.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V315.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Result Evergreen.V315.Discord.HttpError Evergreen.V315.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) (Result Evergreen.V315.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) (Result Evergreen.V315.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) (Result Evergreen.V315.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) (Result Evergreen.V315.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji (Result Evergreen.V315.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji (Result Evergreen.V315.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji (Result Evergreen.V315.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji (Result Evergreen.V315.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V315.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V315.Discord.HttpError (List ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId, Maybe Evergreen.V315.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Effect.Time.Posix Evergreen.V315.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V315.Slack.CurrentUser
            , team : Evergreen.V315.Slack.Team
            , users : List Evergreen.V315.Slack.User
            , channels : List ( Evergreen.V315.Slack.Channel, List Evergreen.V315.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Result Effect.Http.Error Evergreen.V315.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V315.Local.ChangeId Effect.Time.Posix Evergreen.V315.Call.CallId Evergreen.V315.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V315.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V315.Local.ChangeId Effect.Time.Posix Evergreen.V315.Call.CallId Evergreen.V315.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V315.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V315.Local.ChangeId Evergreen.V315.Call.ConnectionId Evergreen.V315.Cloudflare.RealtimeSessionId (List Evergreen.V315.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V315.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V315.Local.ChangeId Evergreen.V315.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Discord.UserAuth (Result Evergreen.V315.Discord.HttpError Evergreen.V315.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Result Evergreen.V315.Discord.HttpError Evergreen.V315.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
        (Result
            Evergreen.V315.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId
                , members : List (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
                }
            , List
                ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId
                , { guild : Evergreen.V315.Discord.GatewayGuild
                  , channels : List Evergreen.V315.Discord.Channel
                  , icon : Maybe Evergreen.V315.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Bool Evergreen.V315.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V315.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.AttachmentId, Evergreen.V315.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V315.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.AttachmentId, Evergreen.V315.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V315.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V315.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V315.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V315.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) (Result Evergreen.V315.Discord.HttpError (List Evergreen.V315.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Result Evergreen.V315.Discord.HttpError (List Evergreen.V315.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V315.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V315.DmChannelId.DmChannelId Evergreen.V315.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V315.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V315.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V315.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
        (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V315.Discord.HttpError
            { guild : Evergreen.V315.Discord.GatewayGuild
            , channels : List Evergreen.V315.Discord.Channel
            , icon : Maybe Evergreen.V315.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Result Evergreen.V315.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V315.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (List ( Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId, Result Effect.Http.Error Evergreen.V315.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId, Result Effect.Http.Error Evergreen.V315.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (List ( Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V315.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V315.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V315.Discord.HttpError (List Evergreen.V315.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V315.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V315.SecretId.SecretId Evergreen.V315.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V315.FileStatus.FileHash Int (Maybe (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
