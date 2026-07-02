module Evergreen.V299.Types exposing (..)

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
import Evergreen.V299.AiChat
import Evergreen.V299.Audio
import Evergreen.V299.Call
import Evergreen.V299.ChannelDescription
import Evergreen.V299.ChannelName
import Evergreen.V299.Cloudflare
import Evergreen.V299.Coord
import Evergreen.V299.CssPixels
import Evergreen.V299.CustomEmoji
import Evergreen.V299.Discord
import Evergreen.V299.DiscordAttachmentId
import Evergreen.V299.DiscordUserData
import Evergreen.V299.DmChannel
import Evergreen.V299.Drawing
import Evergreen.V299.Editable
import Evergreen.V299.EmailAddress
import Evergreen.V299.Embed
import Evergreen.V299.Emoji
import Evergreen.V299.FileStatus
import Evergreen.V299.Game
import Evergreen.V299.Go
import Evergreen.V299.GuildName
import Evergreen.V299.Id
import Evergreen.V299.ImageEditor
import Evergreen.V299.ImageViewer
import Evergreen.V299.LinkedAndOtherDiscordUsers
import Evergreen.V299.Local
import Evergreen.V299.LocalState
import Evergreen.V299.Log
import Evergreen.V299.LoginForm
import Evergreen.V299.MembersAndOwner
import Evergreen.V299.Message
import Evergreen.V299.MessageInput
import Evergreen.V299.MessageView
import Evergreen.V299.MyUi
import Evergreen.V299.NonemptyDict
import Evergreen.V299.NonemptySet
import Evergreen.V299.OneOrGreater
import Evergreen.V299.OneToOne
import Evergreen.V299.Pages.Admin
import Evergreen.V299.Pagination
import Evergreen.V299.PersonName
import Evergreen.V299.Ports
import Evergreen.V299.Postmark
import Evergreen.V299.Range
import Evergreen.V299.RichText
import Evergreen.V299.Route
import Evergreen.V299.SecretId
import Evergreen.V299.SessionIdHash
import Evergreen.V299.Slack
import Evergreen.V299.Sticker
import Evergreen.V299.TextEditor
import Evergreen.V299.ToBackendLog
import Evergreen.V299.Touch
import Evergreen.V299.TwoFactorAuthentication
import Evergreen.V299.Ui.Anim
import Evergreen.V299.Untrusted
import Evergreen.V299.User
import Evergreen.V299.UserAgent
import Evergreen.V299.UserSession
import List.Nonempty
import Quantity
import SeqDict
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
    | LoginFormMsg Evergreen.V299.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V299.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V299.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V299.Route.Route
    | SelectedFilesToAttach ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V299.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V299.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V299.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V299.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V299.NonemptyDict.NonemptyDict Int Evergreen.V299.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V299.NonemptyDict.NonemptyDict Int Evergreen.V299.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V299.NonemptySet.NonemptySet (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V299.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V299.AiChat.Msg
    | GameMsg Evergreen.V299.Game.Msg
    | GoSpectatorMsg Evergreen.V299.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V299.Editable.Msg Evergreen.V299.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V299.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V299.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
        { fileId : Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
        { fileId : Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V299.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage Evergreen.V299.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V299.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V299.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V299.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V299.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.User.NotificationLevel
    | GotStartupData Evergreen.V299.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V299.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId
        , otherUserId : Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRoute Evergreen.V299.MessageInput.Msg
    | MessageInputMsg Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRoute Evergreen.V299.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V299.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V299.Range.Range, Evergreen.V299.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V299.Range.Range, Evergreen.V299.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V299.Call.FromJs)
    | VoiceChatMsg Evergreen.V299.Call.Msg
    | PressedChannelHeaderTab Evergreen.V299.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V299.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V299.Audio.LoadError Evergreen.V299.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V299.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V299.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) Evergreen.V299.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.LocalState.DiscordFrontendGuild
    , user : Evergreen.V299.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.User.FrontendUser
    , discordUsers : Evergreen.V299.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V299.SessionIdHash.SessionIdHash Evergreen.V299.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V299.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId) Evergreen.V299.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId) Evergreen.V299.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V299.Call.CallId (Evergreen.V299.NonemptyDict.NonemptyDict ( Evergreen.V299.Id.Id Evergreen.V299.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V299.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V299.Go.PublicGoMatchData Evergreen.V299.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V299.Route.Route
    , windowSize : Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V299.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V299.Audio.LoadError Evergreen.V299.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V299.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V299.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V299.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V299.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V299.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.ChannelName.ChannelName Evergreen.V299.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.ChannelName.ChannelName Evergreen.V299.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.UserSession.ToBeFilledInByBackend (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V299.GuildName.GuildName (Evergreen.V299.UserSession.ToBeFilledInByBackend (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V299.Id.GuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V299.Id.DiscordGuildOrDmId_DmData (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V299.UserSession.SetViewing
    | Local_SetName Evergreen.V299.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V299.Id.GuildOrDmId (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V299.Id.GuildOrDmId (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId) (Evergreen.V299.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V299.Id.DiscordGuildOrDmId (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V299.Id.DiscordGuildOrDmId (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId) (Evergreen.V299.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V299.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V299.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V299.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V299.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V299.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V299.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V299.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V299.NonemptySet.NonemptySet (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V299.Call.LocalChange
    | Local_Game
        { otherUserId : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
        }
        Evergreen.V299.Game.LocalChange
    | Local_Drawing Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Drawing.AnchorType Evergreen.V299.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Effect.Time.Posix Evergreen.V299.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V299.RichText.RichText (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))) Evergreen.V299.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId) Evergreen.V299.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V299.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V299.RichText.RichText (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))) Evergreen.V299.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId) Evergreen.V299.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.ChannelName.ChannelName Evergreen.V299.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.ChannelName.ChannelName Evergreen.V299.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V299.LocalState.JoinGuildError
            { guildId : Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId
            , guild : Evergreen.V299.LocalState.FrontendGuild
            , owner : Evergreen.V299.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.GuildOrDmId Evergreen.V299.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.GuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.GuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.GuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V299.RichText.RichText (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))) (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V299.RichText.RichText (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V299.Id.DiscordGuildOrDmId_DmData (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V299.RichText.RichText (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V299.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V299.SessionIdHash.SessionIdHash Evergreen.V299.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V299.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V299.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V299.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Evergreen.V299.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.ChannelName.ChannelName (Evergreen.V299.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
        (Evergreen.V299.NonemptyDict.NonemptyDict
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) Evergreen.V299.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Evergreen.V299.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Maybe (Evergreen.V299.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V299.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V299.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V299.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V299.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V299.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V299.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) (Evergreen.V299.Discord.OptionalData String) (Evergreen.V299.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
        (Evergreen.V299.MembersAndOwner.MembersAndOwner
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Evergreen.V299.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId) Evergreen.V299.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId) Evergreen.V299.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V299.Call.ServerChange
    | Server_Game
        (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
        { otherUserId : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
        }
        Evergreen.V299.Game.LocalChange
    | Server_Drawing (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Drawing.AnchorType Evergreen.V299.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V299.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V299.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V299.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V299.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V299.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V299.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V299.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V299.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V299.Id.AnyGuildOrDmId Evergreen.V299.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V299.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels) (Maybe Evergreen.V299.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId) (Evergreen.V299.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V299.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V299.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V299.Local.Local LocalMsg Evergreen.V299.LocalState.LocalState
    , admin : Evergreen.V299.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId, Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V299.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V299.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V299.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V299.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute ) (Evergreen.V299.NonemptyDict.NonemptyDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V299.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V299.TextEditor.Model
    , profilePictureEditor : Evergreen.V299.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId, Evergreen.V299.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V299.Emoji.Model
    , voiceChat : Evergreen.V299.Call.Model
    , currentDmGame : SeqDict.SeqDict ( Evergreen.V299.Id.Id Evergreen.V299.Id.UserId, Maybe (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) ) Evergreen.V299.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V299.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V299.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V299.Range.Range
                , direction : Evergreen.V299.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_WordSpellingGameBoard


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V299.NonemptyDict.NonemptyDict Int Evergreen.V299.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V299.NonemptyDict.NonemptyDict Int Evergreen.V299.Touch.Touch
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
    | AdminToFrontend Evergreen.V299.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V299.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V299.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V299.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V299.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V299.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V299.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V299.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V299.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V299.MyUi.LastCopy
    , notificationPermission : Evergreen.V299.Ports.NotificationPermission
    , pwaStatus : Evergreen.V299.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V299.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V299.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V299.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V299.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V299.Audio.LoadError Evergreen.V299.Audio.Source
    , safeAreaInsetTop : Int
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V299.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V299.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V299.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V299.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V299.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId, Evergreen.V299.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V299.DmChannel.DmChannelId, Evergreen.V299.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId, Evergreen.V299.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId, Evergreen.V299.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V299.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V299.NonemptyDict.NonemptyDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V299.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V299.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V299.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V299.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V299.DmChannel.DmChannelId Evergreen.V299.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) Evergreen.V299.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.Slack.Id Evergreen.V299.Slack.ChannelId) Evergreen.V299.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V299.OneToOne.OneToOne String (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    , slackUsers : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.Slack.Id Evergreen.V299.Slack.UserId) (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
    , slackServers : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.Slack.Id Evergreen.V299.Slack.TeamId) (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    , slackToken : Maybe Evergreen.V299.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V299.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V299.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V299.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V299.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V299.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V299.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V299.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V299.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Evergreen.V299.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId, Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V299.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V299.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V299.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V299.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.LocalState.LoadingDiscordChannel (List Evergreen.V299.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V299.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId) Evergreen.V299.Sticker.StickerData
    , discordStickers : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.Discord.Id Evergreen.V299.Discord.StickerId) (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId) Evergreen.V299.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V299.OneToOne.OneToOne Evergreen.V299.RichText.DiscordCustomEmojiIdAndName (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V299.Postmark.ApiKey
    , serverSecret : Evergreen.V299.SecretId.SecretId Evergreen.V299.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V299.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.GamePublicId) ( Evergreen.V299.DmChannel.DmChannelId, Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId )
    }


type alias FrontendMsg =
    Evergreen.V299.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V299.DmChannel.DmChannelId Evergreen.V299.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V299.Id.DiscordGuildOrDmId Evergreen.V299.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V299.Id.Id Evergreen.V299.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V299.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V299.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V299.Untrusted.Untrusted Evergreen.V299.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V299.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V299.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V299.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V299.PersonName.PersonName Evergreen.V299.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V299.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V299.Slack.OAuthCode Evergreen.V299.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V299.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V299.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V299.Id.Id Evergreen.V299.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V299.EmailAddress.EmailAddress (Result Evergreen.V299.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V299.EmailAddress.EmailAddress (Result Evergreen.V299.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V299.EmailAddress.EmailAddress (Result Evergreen.V299.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V299.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMaybeMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Result Evergreen.V299.Discord.HttpError Evergreen.V299.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V299.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Result Evergreen.V299.Discord.HttpError Evergreen.V299.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) (Result Evergreen.V299.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) (Result Evergreen.V299.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) (Result Evergreen.V299.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) (Result Evergreen.V299.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji (Result Evergreen.V299.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji (Result Evergreen.V299.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji (Result Evergreen.V299.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji (Result Evergreen.V299.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V299.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V299.Discord.HttpError (List ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId, Maybe Evergreen.V299.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Effect.Time.Posix Evergreen.V299.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V299.Slack.CurrentUser
            , team : Evergreen.V299.Slack.Team
            , users : List Evergreen.V299.Slack.User
            , channels : List ( Evergreen.V299.Slack.Channel, List Evergreen.V299.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Result Effect.Http.Error Evergreen.V299.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V299.Local.ChangeId Effect.Time.Posix Evergreen.V299.Call.CallId Evergreen.V299.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V299.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V299.Local.ChangeId Effect.Time.Posix Evergreen.V299.Call.CallId Evergreen.V299.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V299.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V299.Local.ChangeId Evergreen.V299.Call.ConnectionId Evergreen.V299.Cloudflare.RealtimeSessionId (List Evergreen.V299.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V299.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V299.Local.ChangeId Evergreen.V299.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Discord.UserAuth (Result Evergreen.V299.Discord.HttpError Evergreen.V299.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Result Evergreen.V299.Discord.HttpError Evergreen.V299.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
        (Result
            Evergreen.V299.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId
                , members : List (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
                }
            , List
                ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId
                , { guild : Evergreen.V299.Discord.GatewayGuild
                  , channels : List Evergreen.V299.Discord.Channel
                  , icon : Maybe Evergreen.V299.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Bool Evergreen.V299.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V299.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.AttachmentId, Evergreen.V299.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V299.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.AttachmentId, Evergreen.V299.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V299.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V299.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V299.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V299.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) (Result Evergreen.V299.Discord.HttpError (List Evergreen.V299.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Result Evergreen.V299.Discord.HttpError (List Evergreen.V299.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V299.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V299.DmChannel.DmChannelId Evergreen.V299.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V299.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V299.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V299.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
        (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V299.Discord.HttpError
            { guild : Evergreen.V299.Discord.GatewayGuild
            , channels : List Evergreen.V299.Discord.Channel
            , icon : Maybe Evergreen.V299.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Result Evergreen.V299.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V299.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (List ( Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId, Result Effect.Http.Error Evergreen.V299.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId, Result Effect.Http.Error Evergreen.V299.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (List ( Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V299.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V299.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V299.Discord.HttpError (List Evergreen.V299.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V299.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V299.SecretId.SecretId Evergreen.V299.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V299.FileStatus.FileHash Int (Maybe (Evergreen.V299.Coord.Coord Evergreen.V299.CssPixels.CssPixels))
