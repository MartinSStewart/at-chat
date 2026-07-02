module Evergreen.V298.Types exposing (..)

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
import Evergreen.V298.AiChat
import Evergreen.V298.Audio
import Evergreen.V298.Call
import Evergreen.V298.ChannelDescription
import Evergreen.V298.ChannelName
import Evergreen.V298.Cloudflare
import Evergreen.V298.Coord
import Evergreen.V298.CssPixels
import Evergreen.V298.CustomEmoji
import Evergreen.V298.Discord
import Evergreen.V298.DiscordAttachmentId
import Evergreen.V298.DiscordUserData
import Evergreen.V298.DmChannel
import Evergreen.V298.Drawing
import Evergreen.V298.Editable
import Evergreen.V298.EmailAddress
import Evergreen.V298.Embed
import Evergreen.V298.Emoji
import Evergreen.V298.FileStatus
import Evergreen.V298.Game
import Evergreen.V298.Go
import Evergreen.V298.GuildName
import Evergreen.V298.Id
import Evergreen.V298.ImageEditor
import Evergreen.V298.ImageViewer
import Evergreen.V298.LinkedAndOtherDiscordUsers
import Evergreen.V298.Local
import Evergreen.V298.LocalState
import Evergreen.V298.Log
import Evergreen.V298.LoginForm
import Evergreen.V298.MembersAndOwner
import Evergreen.V298.Message
import Evergreen.V298.MessageInput
import Evergreen.V298.MessageView
import Evergreen.V298.MyUi
import Evergreen.V298.NonemptyDict
import Evergreen.V298.NonemptySet
import Evergreen.V298.OneOrGreater
import Evergreen.V298.OneToOne
import Evergreen.V298.Pages.Admin
import Evergreen.V298.Pagination
import Evergreen.V298.PersonName
import Evergreen.V298.Ports
import Evergreen.V298.Postmark
import Evergreen.V298.Range
import Evergreen.V298.RichText
import Evergreen.V298.Route
import Evergreen.V298.SecretId
import Evergreen.V298.SessionIdHash
import Evergreen.V298.Slack
import Evergreen.V298.Sticker
import Evergreen.V298.TextEditor
import Evergreen.V298.ToBackendLog
import Evergreen.V298.Touch
import Evergreen.V298.TwoFactorAuthentication
import Evergreen.V298.Ui.Anim
import Evergreen.V298.Untrusted
import Evergreen.V298.User
import Evergreen.V298.UserAgent
import Evergreen.V298.UserSession
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
    | LoginFormMsg Evergreen.V298.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V298.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V298.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V298.Route.Route
    | SelectedFilesToAttach ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V298.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V298.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V298.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V298.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V298.NonemptyDict.NonemptyDict Int Evergreen.V298.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V298.NonemptyDict.NonemptyDict Int Evergreen.V298.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V298.NonemptySet.NonemptySet (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V298.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V298.AiChat.Msg
    | GameMsg Evergreen.V298.Game.Msg
    | GoSpectatorMsg Evergreen.V298.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V298.Editable.Msg Evergreen.V298.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V298.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V298.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
        { fileId : Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
        { fileId : Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V298.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage Evergreen.V298.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V298.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V298.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V298.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V298.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.User.NotificationLevel
    | GotStartupData Evergreen.V298.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V298.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId
        , otherUserId : Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRoute Evergreen.V298.MessageInput.Msg
    | MessageInputMsg Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRoute Evergreen.V298.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V298.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V298.Range.Range, Evergreen.V298.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V298.Range.Range, Evergreen.V298.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V298.Call.FromJs)
    | VoiceChatMsg Evergreen.V298.Call.Msg
    | PressedChannelHeaderTab Evergreen.V298.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V298.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V298.Audio.LoadError Evergreen.V298.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V298.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V298.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) Evergreen.V298.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.LocalState.DiscordFrontendGuild
    , user : Evergreen.V298.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.User.FrontendUser
    , discordUsers : Evergreen.V298.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V298.SessionIdHash.SessionIdHash Evergreen.V298.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V298.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId) Evergreen.V298.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId) Evergreen.V298.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V298.Call.CallId (Evergreen.V298.NonemptyDict.NonemptyDict ( Evergreen.V298.Id.Id Evergreen.V298.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V298.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V298.Go.PublicGoMatchData Evergreen.V298.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V298.Route.Route
    , windowSize : Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V298.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V298.Audio.LoadError Evergreen.V298.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V298.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V298.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V298.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V298.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V298.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.ChannelName.ChannelName Evergreen.V298.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.ChannelName.ChannelName Evergreen.V298.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.UserSession.ToBeFilledInByBackend (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V298.GuildName.GuildName (Evergreen.V298.UserSession.ToBeFilledInByBackend (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V298.Id.GuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V298.Id.DiscordGuildOrDmId_DmData (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V298.UserSession.SetViewing
    | Local_SetName Evergreen.V298.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V298.Id.GuildOrDmId (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V298.Id.GuildOrDmId (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId) (Evergreen.V298.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V298.Id.DiscordGuildOrDmId (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V298.Id.DiscordGuildOrDmId (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId) (Evergreen.V298.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V298.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V298.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V298.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V298.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V298.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V298.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V298.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V298.NonemptySet.NonemptySet (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V298.Call.LocalChange
    | Local_Game
        { otherUserId : Evergreen.V298.Id.Id Evergreen.V298.Id.UserId
        }
        Evergreen.V298.Game.LocalChange
    | Local_Drawing Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Drawing.AnchorType Evergreen.V298.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Effect.Time.Posix Evergreen.V298.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V298.RichText.RichText (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))) Evergreen.V298.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId) Evergreen.V298.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V298.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V298.RichText.RichText (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))) Evergreen.V298.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId) Evergreen.V298.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.ChannelName.ChannelName Evergreen.V298.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.ChannelName.ChannelName Evergreen.V298.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V298.LocalState.JoinGuildError
            { guildId : Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId
            , guild : Evergreen.V298.LocalState.FrontendGuild
            , owner : Evergreen.V298.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.GuildOrDmId Evergreen.V298.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.GuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.GuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.GuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V298.RichText.RichText (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))) (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V298.RichText.RichText (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V298.Id.DiscordGuildOrDmId_DmData (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V298.RichText.RichText (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V298.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V298.SessionIdHash.SessionIdHash Evergreen.V298.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V298.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V298.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V298.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Evergreen.V298.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.ChannelName.ChannelName (Evergreen.V298.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
        (Evergreen.V298.NonemptyDict.NonemptyDict
            (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) Evergreen.V298.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Evergreen.V298.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Maybe (Evergreen.V298.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V298.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V298.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V298.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V298.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V298.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V298.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) (Evergreen.V298.Discord.OptionalData String) (Evergreen.V298.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
        (Evergreen.V298.MembersAndOwner.MembersAndOwner
            (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Evergreen.V298.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId) Evergreen.V298.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId) Evergreen.V298.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V298.Call.ServerChange
    | Server_Game
        (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
        { otherUserId : Evergreen.V298.Id.Id Evergreen.V298.Id.UserId
        }
        Evergreen.V298.Game.LocalChange
    | Server_Drawing (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Drawing.AnchorType Evergreen.V298.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V298.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V298.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V298.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V298.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V298.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V298.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V298.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V298.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V298.Id.AnyGuildOrDmId Evergreen.V298.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V298.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels) (Maybe Evergreen.V298.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId) (Evergreen.V298.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V298.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V298.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V298.Local.Local LocalMsg Evergreen.V298.LocalState.LocalState
    , admin : Evergreen.V298.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId, Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V298.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V298.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V298.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V298.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute ) (Evergreen.V298.NonemptyDict.NonemptyDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V298.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V298.TextEditor.Model
    , profilePictureEditor : Evergreen.V298.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId, Evergreen.V298.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V298.Emoji.Model
    , voiceChat : Evergreen.V298.Call.Model
    , currentDmGame : SeqDict.SeqDict ( Evergreen.V298.Id.Id Evergreen.V298.Id.UserId, Maybe (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) ) Evergreen.V298.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V298.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V298.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V298.Range.Range
                , direction : Evergreen.V298.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_WordSpellingGameBoard


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V298.NonemptyDict.NonemptyDict Int Evergreen.V298.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V298.NonemptyDict.NonemptyDict Int Evergreen.V298.Touch.Touch
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
    | AdminToFrontend Evergreen.V298.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V298.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V298.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V298.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V298.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V298.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V298.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V298.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V298.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V298.MyUi.LastCopy
    , notificationPermission : Evergreen.V298.Ports.NotificationPermission
    , pwaStatus : Evergreen.V298.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V298.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V298.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V298.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V298.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V298.Audio.LoadError Evergreen.V298.Audio.Source
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V298.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V298.Id.Id Evergreen.V298.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V298.Id.Id Evergreen.V298.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V298.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V298.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V298.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V298.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId, Evergreen.V298.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V298.DmChannel.DmChannelId, Evergreen.V298.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId, Evergreen.V298.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId, Evergreen.V298.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V298.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V298.NonemptyDict.NonemptyDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V298.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V298.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V298.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V298.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V298.DmChannel.DmChannelId Evergreen.V298.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) Evergreen.V298.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V298.OneToOne.OneToOne (Evergreen.V298.Slack.Id Evergreen.V298.Slack.ChannelId) Evergreen.V298.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V298.OneToOne.OneToOne String (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    , slackUsers : Evergreen.V298.OneToOne.OneToOne (Evergreen.V298.Slack.Id Evergreen.V298.Slack.UserId) (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
    , slackServers : Evergreen.V298.OneToOne.OneToOne (Evergreen.V298.Slack.Id Evergreen.V298.Slack.TeamId) (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    , slackToken : Maybe Evergreen.V298.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V298.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V298.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V298.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V298.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V298.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V298.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V298.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V298.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Evergreen.V298.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId, Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V298.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V298.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V298.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V298.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.LocalState.LoadingDiscordChannel (List Evergreen.V298.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V298.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId) Evergreen.V298.Sticker.StickerData
    , discordStickers : Evergreen.V298.OneToOne.OneToOne (Evergreen.V298.Discord.Id Evergreen.V298.Discord.StickerId) (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId) Evergreen.V298.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V298.OneToOne.OneToOne Evergreen.V298.RichText.DiscordCustomEmojiIdAndName (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V298.Postmark.ApiKey
    , serverSecret : Evergreen.V298.SecretId.SecretId Evergreen.V298.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V298.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V298.OneToOne.OneToOne (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.GamePublicId) ( Evergreen.V298.DmChannel.DmChannelId, Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId )
    }


type alias FrontendMsg =
    Evergreen.V298.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V298.DmChannel.DmChannelId Evergreen.V298.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V298.Id.DiscordGuildOrDmId Evergreen.V298.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V298.Id.Id Evergreen.V298.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V298.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V298.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V298.Untrusted.Untrusted Evergreen.V298.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V298.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V298.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V298.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V298.PersonName.PersonName Evergreen.V298.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V298.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V298.Slack.OAuthCode Evergreen.V298.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V298.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V298.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V298.Id.Id Evergreen.V298.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V298.EmailAddress.EmailAddress (Result Evergreen.V298.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V298.EmailAddress.EmailAddress (Result Evergreen.V298.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V298.EmailAddress.EmailAddress (Result Evergreen.V298.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V298.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMaybeMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Result Evergreen.V298.Discord.HttpError Evergreen.V298.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V298.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Result Evergreen.V298.Discord.HttpError Evergreen.V298.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) (Result Evergreen.V298.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) (Result Evergreen.V298.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) (Result Evergreen.V298.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) (Result Evergreen.V298.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji (Result Evergreen.V298.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji (Result Evergreen.V298.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji (Result Evergreen.V298.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji (Result Evergreen.V298.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V298.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V298.Discord.HttpError (List ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId, Maybe Evergreen.V298.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Effect.Time.Posix Evergreen.V298.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V298.Slack.CurrentUser
            , team : Evergreen.V298.Slack.Team
            , users : List Evergreen.V298.Slack.User
            , channels : List ( Evergreen.V298.Slack.Channel, List Evergreen.V298.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Result Effect.Http.Error Evergreen.V298.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V298.Local.ChangeId Effect.Time.Posix Evergreen.V298.Call.CallId Evergreen.V298.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V298.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V298.Local.ChangeId Effect.Time.Posix Evergreen.V298.Call.CallId Evergreen.V298.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V298.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V298.Local.ChangeId Evergreen.V298.Call.ConnectionId Evergreen.V298.Cloudflare.RealtimeSessionId (List Evergreen.V298.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V298.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V298.Local.ChangeId Evergreen.V298.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Discord.UserAuth (Result Evergreen.V298.Discord.HttpError Evergreen.V298.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Result Evergreen.V298.Discord.HttpError Evergreen.V298.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
        (Result
            Evergreen.V298.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId
                , members : List (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
                }
            , List
                ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId
                , { guild : Evergreen.V298.Discord.GatewayGuild
                  , channels : List Evergreen.V298.Discord.Channel
                  , icon : Maybe Evergreen.V298.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Bool Evergreen.V298.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V298.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.AttachmentId, Evergreen.V298.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V298.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.AttachmentId, Evergreen.V298.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V298.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V298.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V298.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V298.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) (Result Evergreen.V298.Discord.HttpError (List Evergreen.V298.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Result Evergreen.V298.Discord.HttpError (List Evergreen.V298.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V298.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V298.DmChannel.DmChannelId Evergreen.V298.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V298.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V298.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V298.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
        (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V298.Discord.HttpError
            { guild : Evergreen.V298.Discord.GatewayGuild
            , channels : List Evergreen.V298.Discord.Channel
            , icon : Maybe Evergreen.V298.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Result Evergreen.V298.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V298.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (List ( Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId, Result Effect.Http.Error Evergreen.V298.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId, Result Effect.Http.Error Evergreen.V298.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (List ( Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V298.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V298.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V298.Discord.HttpError (List Evergreen.V298.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V298.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V298.SecretId.SecretId Evergreen.V298.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V298.FileStatus.FileHash Int (Maybe (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels))
