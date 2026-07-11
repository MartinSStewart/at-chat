module Evergreen.V316.Types exposing (..)

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
import Evergreen.V316.AiChat
import Evergreen.V316.Audio
import Evergreen.V316.Call
import Evergreen.V316.ChannelDescription
import Evergreen.V316.ChannelName
import Evergreen.V316.Cloudflare
import Evergreen.V316.Coord
import Evergreen.V316.CssPixels
import Evergreen.V316.CustomEmoji
import Evergreen.V316.Discord
import Evergreen.V316.DiscordAttachmentId
import Evergreen.V316.DiscordUserData
import Evergreen.V316.DmChannel
import Evergreen.V316.DmChannelId
import Evergreen.V316.Drawing
import Evergreen.V316.Editable
import Evergreen.V316.EmailAddress
import Evergreen.V316.Embed
import Evergreen.V316.Emoji
import Evergreen.V316.FileStatus
import Evergreen.V316.Game
import Evergreen.V316.Go
import Evergreen.V316.GuildName
import Evergreen.V316.Id
import Evergreen.V316.ImageEditor
import Evergreen.V316.ImageViewer
import Evergreen.V316.LinkedAndOtherDiscordUsers
import Evergreen.V316.Local
import Evergreen.V316.LocalState
import Evergreen.V316.Log
import Evergreen.V316.LoginForm
import Evergreen.V316.MembersAndOwner
import Evergreen.V316.Message
import Evergreen.V316.MessageInput
import Evergreen.V316.MessageView
import Evergreen.V316.MyUi
import Evergreen.V316.NonemptyDict
import Evergreen.V316.NonemptySet
import Evergreen.V316.OneOrGreater
import Evergreen.V316.OneToOne
import Evergreen.V316.Pages.Admin
import Evergreen.V316.Pagination
import Evergreen.V316.PersonName
import Evergreen.V316.Ports
import Evergreen.V316.Postmark
import Evergreen.V316.Range
import Evergreen.V316.RichText
import Evergreen.V316.Route
import Evergreen.V316.Scroll
import Evergreen.V316.SecretId
import Evergreen.V316.SessionIdHash
import Evergreen.V316.Slack
import Evergreen.V316.Sticker
import Evergreen.V316.TextEditor
import Evergreen.V316.ToBackendLog
import Evergreen.V316.Touch
import Evergreen.V316.TwoFactorAuthentication
import Evergreen.V316.Ui.Anim
import Evergreen.V316.Untrusted
import Evergreen.V316.User
import Evergreen.V316.UserAgent
import Evergreen.V316.UserSession
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
    | LoginFormMsg Evergreen.V316.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V316.Pages.Admin.Msg
    | PressedLogOut Evergreen.V316.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V316.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V316.Route.Route
    | SelectedFilesToAttach ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V316.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V316.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V316.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V316.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V316.NonemptyDict.NonemptyDict Int Evergreen.V316.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V316.NonemptyDict.NonemptyDict Int Evergreen.V316.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRoute Evergreen.V316.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V316.NonemptySet.NonemptySet (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V316.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V316.AiChat.Msg
    | GameMsg Evergreen.V316.Game.Msg
    | GoSpectatorMsg Evergreen.V316.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V316.Editable.Msg Evergreen.V316.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V316.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V316.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
        { fileId : Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
        { fileId : Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V316.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage Evergreen.V316.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V316.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V316.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V316.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V316.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.User.NotificationLevel
    | GotStartupData Evergreen.V316.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V316.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId
        , otherUserId : Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRoute Evergreen.V316.MessageInput.Msg
    | MessageInputMsg Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRoute Evergreen.V316.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V316.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V316.Range.Range, Evergreen.V316.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V316.Range.Range, Evergreen.V316.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V316.Call.FromJs)
    | VoiceChatMsg Evergreen.V316.Call.Msg
    | PressedChannelHeaderTab Evergreen.V316.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V316.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V316.Audio.LoadError Evergreen.V316.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V316.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V316.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) Evergreen.V316.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.LocalState.DiscordFrontendGuild
    , user : Evergreen.V316.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.User.FrontendUser
    , discordUsers : Evergreen.V316.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V316.SessionIdHash.SessionIdHash Evergreen.V316.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V316.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId) Evergreen.V316.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId) Evergreen.V316.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V316.Call.CallId (Evergreen.V316.NonemptyDict.NonemptyDict ( Evergreen.V316.Id.Id Evergreen.V316.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V316.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V316.Go.PublicGoMatchData Evergreen.V316.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V316.Route.Route
    , windowSize : Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V316.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V316.Audio.LoadError Evergreen.V316.Audio.Source
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V316.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V316.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V316.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V316.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V316.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.ChannelName.ChannelName Evergreen.V316.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.ChannelName.ChannelName Evergreen.V316.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.UserSession.ToBeFilledInByBackend (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V316.GuildName.GuildName (Evergreen.V316.UserSession.ToBeFilledInByBackend (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V316.Id.DiscordGuildOrDmId_DmData (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V316.UserSession.SetViewing
    | Local_SetName Evergreen.V316.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V316.Id.GuildOrDmId (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V316.Id.GuildOrDmId (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId) (Evergreen.V316.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V316.Id.DiscordGuildOrDmId (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V316.Id.DiscordGuildOrDmId (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId) (Evergreen.V316.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V316.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V316.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V316.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V316.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V316.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V316.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V316.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V316.NonemptySet.NonemptySet (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V316.Call.LocalChange
    | Local_Game Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Game.LocalChange
    | Local_Drawing Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Drawing.AnchorType Evergreen.V316.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Effect.Time.Posix Evergreen.V316.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V316.RichText.RichText (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))) Evergreen.V316.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId) Evergreen.V316.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V316.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V316.RichText.RichText (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))) Evergreen.V316.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId) Evergreen.V316.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.ChannelName.ChannelName Evergreen.V316.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.ChannelName.ChannelName Evergreen.V316.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V316.LocalState.JoinGuildError
            { guildId : Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId
            , guild : Evergreen.V316.LocalState.FrontendGuild
            , owner : Evergreen.V316.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V316.RichText.RichText (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))) (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V316.RichText.RichText (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V316.Id.DiscordGuildOrDmId_DmData (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V316.RichText.RichText (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V316.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V316.SessionIdHash.SessionIdHash Evergreen.V316.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V316.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V316.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V316.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V316.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Evergreen.V316.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.ChannelName.ChannelName (Evergreen.V316.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
        (Evergreen.V316.NonemptyDict.NonemptyDict
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) Evergreen.V316.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Evergreen.V316.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Maybe (Evergreen.V316.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V316.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V316.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V316.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V316.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V316.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V316.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) (Evergreen.V316.Discord.OptionalData String) (Evergreen.V316.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
        (Evergreen.V316.MembersAndOwner.MembersAndOwner
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Evergreen.V316.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId) Evergreen.V316.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId) Evergreen.V316.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V316.Call.ServerChange
    | Server_Game (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Game.LocalChange
    | Server_Drawing (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Drawing.AnchorType Evergreen.V316.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V316.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V316.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V316.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V316.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V316.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V316.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V316.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V316.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V316.Id.AnyGuildOrDmId Evergreen.V316.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V316.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels) (Maybe Evergreen.V316.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId) (Evergreen.V316.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V316.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V316.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V316.Local.Local LocalMsg Evergreen.V316.LocalState.LocalState
    , admin : Evergreen.V316.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId, Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V316.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V316.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V316.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V316.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ) (Evergreen.V316.NonemptyDict.NonemptyDict (Evergreen.V316.Id.Id Evergreen.V316.FileStatus.FileId) Evergreen.V316.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V316.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V316.Scroll.ScrollPosition
    , textEditor : Evergreen.V316.TextEditor.Model
    , profilePictureEditor : Evergreen.V316.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId, Evergreen.V316.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V316.Emoji.Model
    , voiceChat : Evergreen.V316.Call.Model
    , games : SeqDict.SeqDict Evergreen.V316.Id.GuildOrDmId Evergreen.V316.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V316.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V316.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V316.Range.Range
                , direction : Evergreen.V316.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V316.NonemptyDict.NonemptyDict Int Evergreen.V316.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V316.NonemptyDict.NonemptyDict Int Evergreen.V316.Touch.Touch
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
    | AdminToFrontend Evergreen.V316.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V316.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V316.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V316.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V316.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V316.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V316.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V316.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V316.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V316.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V316.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V316.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V316.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V316.Audio.LoadError Evergreen.V316.Audio.Source
    , startupData : Evergreen.V316.Ports.StartupData
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V316.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V316.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V316.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V316.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V316.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId, Evergreen.V316.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V316.DmChannelId.DmChannelId, Evergreen.V316.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId, Evergreen.V316.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId, Evergreen.V316.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V316.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V316.NonemptyDict.NonemptyDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V316.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V316.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V316.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V316.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V316.DmChannelId.DmChannelId Evergreen.V316.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) Evergreen.V316.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.Slack.Id Evergreen.V316.Slack.ChannelId) Evergreen.V316.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V316.OneToOne.OneToOne String (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    , slackUsers : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.Slack.Id Evergreen.V316.Slack.UserId) (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
    , slackServers : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.Slack.Id Evergreen.V316.Slack.TeamId) (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    , slackToken : Maybe Evergreen.V316.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V316.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V316.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V316.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V316.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V316.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V316.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V316.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V316.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Evergreen.V316.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId, Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V316.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V316.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V316.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V316.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.LocalState.LoadingDiscordChannel (List Evergreen.V316.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V316.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId) Evergreen.V316.Sticker.StickerData
    , discordStickers : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.Discord.Id Evergreen.V316.Discord.StickerId) (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId) Evergreen.V316.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V316.OneToOne.OneToOne Evergreen.V316.RichText.DiscordCustomEmojiIdAndName (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V316.Postmark.ApiKey
    , serverSecret : Evergreen.V316.SecretId.SecretId Evergreen.V316.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V316.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.GamePublicId) ( Evergreen.V316.DmChannelId.GuildOrFullDmId, Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V316.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V316.DmChannelId.DmChannelId Evergreen.V316.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V316.Id.DiscordGuildOrDmId Evergreen.V316.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V316.Id.Id Evergreen.V316.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V316.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V316.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V316.Untrusted.Untrusted Evergreen.V316.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V316.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V316.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V316.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V316.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V316.PersonName.PersonName Evergreen.V316.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V316.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V316.Slack.OAuthCode Evergreen.V316.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V316.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V316.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V316.Id.Id Evergreen.V316.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V316.EmailAddress.EmailAddress (Result Evergreen.V316.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V316.EmailAddress.EmailAddress (Result Evergreen.V316.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V316.EmailAddress.EmailAddress (Result Evergreen.V316.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V316.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMaybeMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Result Evergreen.V316.Discord.HttpError Evergreen.V316.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V316.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Result Evergreen.V316.Discord.HttpError Evergreen.V316.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) (Result Evergreen.V316.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) (Result Evergreen.V316.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) (Result Evergreen.V316.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) (Result Evergreen.V316.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji (Result Evergreen.V316.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji (Result Evergreen.V316.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji (Result Evergreen.V316.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji (Result Evergreen.V316.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V316.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V316.Discord.HttpError (List ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId, Maybe Evergreen.V316.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Effect.Time.Posix Evergreen.V316.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V316.Slack.CurrentUser
            , team : Evergreen.V316.Slack.Team
            , users : List Evergreen.V316.Slack.User
            , channels : List ( Evergreen.V316.Slack.Channel, List Evergreen.V316.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Result Effect.Http.Error Evergreen.V316.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V316.Local.ChangeId Effect.Time.Posix Evergreen.V316.Call.CallId Evergreen.V316.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V316.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V316.Local.ChangeId Effect.Time.Posix Evergreen.V316.Call.CallId Evergreen.V316.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V316.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V316.Local.ChangeId Evergreen.V316.Call.ConnectionId Evergreen.V316.Cloudflare.RealtimeSessionId (List Evergreen.V316.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V316.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V316.Local.ChangeId Evergreen.V316.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Discord.UserAuth (Result Evergreen.V316.Discord.HttpError Evergreen.V316.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Result Evergreen.V316.Discord.HttpError Evergreen.V316.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
        (Result
            Evergreen.V316.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId
                , members : List (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
                }
            , List
                ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId
                , { guild : Evergreen.V316.Discord.GatewayGuild
                  , channels : List Evergreen.V316.Discord.Channel
                  , icon : Maybe Evergreen.V316.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Bool Evergreen.V316.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V316.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.AttachmentId, Evergreen.V316.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V316.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.AttachmentId, Evergreen.V316.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V316.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V316.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V316.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V316.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) (Result Evergreen.V316.Discord.HttpError (List Evergreen.V316.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Result Evergreen.V316.Discord.HttpError (List Evergreen.V316.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V316.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V316.DmChannelId.DmChannelId Evergreen.V316.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V316.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V316.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V316.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
        (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V316.Discord.HttpError
            { guild : Evergreen.V316.Discord.GatewayGuild
            , channels : List Evergreen.V316.Discord.Channel
            , icon : Maybe Evergreen.V316.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Result Evergreen.V316.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V316.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (List ( Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId, Result Effect.Http.Error Evergreen.V316.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId, Result Effect.Http.Error Evergreen.V316.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (List ( Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V316.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V316.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V316.Discord.HttpError (List Evergreen.V316.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V316.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V316.SecretId.SecretId Evergreen.V316.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V316.FileStatus.FileHash Int (Maybe (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
