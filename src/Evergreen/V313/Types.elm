module Evergreen.V313.Types exposing (..)

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
import Evergreen.V313.AiChat
import Evergreen.V313.Audio
import Evergreen.V313.Call
import Evergreen.V313.ChannelDescription
import Evergreen.V313.ChannelName
import Evergreen.V313.Cloudflare
import Evergreen.V313.Coord
import Evergreen.V313.CssPixels
import Evergreen.V313.CustomEmoji
import Evergreen.V313.Discord
import Evergreen.V313.DiscordAttachmentId
import Evergreen.V313.DiscordUserData
import Evergreen.V313.DmChannel
import Evergreen.V313.DmChannelId
import Evergreen.V313.Drawing
import Evergreen.V313.Editable
import Evergreen.V313.EmailAddress
import Evergreen.V313.Embed
import Evergreen.V313.Emoji
import Evergreen.V313.FileStatus
import Evergreen.V313.Game
import Evergreen.V313.Go
import Evergreen.V313.GuildName
import Evergreen.V313.Id
import Evergreen.V313.ImageEditor
import Evergreen.V313.ImageViewer
import Evergreen.V313.LinkedAndOtherDiscordUsers
import Evergreen.V313.Local
import Evergreen.V313.LocalState
import Evergreen.V313.Log
import Evergreen.V313.LoginForm
import Evergreen.V313.MembersAndOwner
import Evergreen.V313.Message
import Evergreen.V313.MessageInput
import Evergreen.V313.MessageView
import Evergreen.V313.MyUi
import Evergreen.V313.NonemptyDict
import Evergreen.V313.NonemptySet
import Evergreen.V313.OneOrGreater
import Evergreen.V313.OneToOne
import Evergreen.V313.Pages.Admin
import Evergreen.V313.Pagination
import Evergreen.V313.PersonName
import Evergreen.V313.Ports
import Evergreen.V313.Postmark
import Evergreen.V313.Range
import Evergreen.V313.RichText
import Evergreen.V313.Route
import Evergreen.V313.Scroll
import Evergreen.V313.SecretId
import Evergreen.V313.SessionIdHash
import Evergreen.V313.Slack
import Evergreen.V313.Sticker
import Evergreen.V313.TextEditor
import Evergreen.V313.ToBackendLog
import Evergreen.V313.Touch
import Evergreen.V313.TwoFactorAuthentication
import Evergreen.V313.Ui.Anim
import Evergreen.V313.Untrusted
import Evergreen.V313.User
import Evergreen.V313.UserAgent
import Evergreen.V313.UserSession
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
    | LoginFormMsg Evergreen.V313.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V313.Pages.Admin.Msg
    | PressedLogOut Evergreen.V313.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V313.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V313.Route.Route
    | SelectedFilesToAttach ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V313.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V313.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V313.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V313.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V313.NonemptyDict.NonemptyDict Int Evergreen.V313.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V313.NonemptyDict.NonemptyDict Int Evergreen.V313.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRoute Evergreen.V313.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V313.NonemptySet.NonemptySet (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V313.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V313.AiChat.Msg
    | GameMsg Evergreen.V313.Game.Msg
    | GoSpectatorMsg Evergreen.V313.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V313.Editable.Msg Evergreen.V313.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V313.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V313.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
        { fileId : Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
        { fileId : Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V313.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage Evergreen.V313.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V313.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V313.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V313.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V313.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.User.NotificationLevel
    | GotStartupData Evergreen.V313.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V313.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId
        , otherUserId : Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRoute Evergreen.V313.MessageInput.Msg
    | MessageInputMsg Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRoute Evergreen.V313.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V313.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V313.Range.Range, Evergreen.V313.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V313.Range.Range, Evergreen.V313.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V313.Call.FromJs)
    | VoiceChatMsg Evergreen.V313.Call.Msg
    | PressedChannelHeaderTab Evergreen.V313.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V313.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V313.Audio.LoadError Evergreen.V313.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V313.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V313.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) Evergreen.V313.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.LocalState.DiscordFrontendGuild
    , user : Evergreen.V313.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.User.FrontendUser
    , discordUsers : Evergreen.V313.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V313.SessionIdHash.SessionIdHash Evergreen.V313.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V313.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId) Evergreen.V313.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId) Evergreen.V313.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V313.Call.CallId (Evergreen.V313.NonemptyDict.NonemptyDict ( Evergreen.V313.Id.Id Evergreen.V313.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V313.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V313.Go.PublicGoMatchData Evergreen.V313.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V313.Route.Route
    , windowSize : Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V313.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V313.Audio.LoadError Evergreen.V313.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V313.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V313.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V313.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V313.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V313.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.ChannelName.ChannelName Evergreen.V313.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.ChannelName.ChannelName Evergreen.V313.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.UserSession.ToBeFilledInByBackend (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V313.GuildName.GuildName (Evergreen.V313.UserSession.ToBeFilledInByBackend (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V313.Id.DiscordGuildOrDmId_DmData (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V313.UserSession.SetViewing
    | Local_SetName Evergreen.V313.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V313.Id.GuildOrDmId (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V313.Id.GuildOrDmId (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId) (Evergreen.V313.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V313.Id.DiscordGuildOrDmId (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V313.Id.DiscordGuildOrDmId (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId) (Evergreen.V313.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V313.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V313.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V313.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V313.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V313.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V313.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V313.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V313.NonemptySet.NonemptySet (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V313.Call.LocalChange
    | Local_Game Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Game.LocalChange
    | Local_Drawing Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Drawing.AnchorType Evergreen.V313.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Effect.Time.Posix Evergreen.V313.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V313.RichText.RichText (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))) Evergreen.V313.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId) Evergreen.V313.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V313.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V313.RichText.RichText (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))) Evergreen.V313.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId) Evergreen.V313.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.ChannelName.ChannelName Evergreen.V313.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.ChannelName.ChannelName Evergreen.V313.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V313.LocalState.JoinGuildError
            { guildId : Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId
            , guild : Evergreen.V313.LocalState.FrontendGuild
            , owner : Evergreen.V313.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V313.RichText.RichText (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))) (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V313.RichText.RichText (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V313.Id.DiscordGuildOrDmId_DmData (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V313.RichText.RichText (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V313.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V313.SessionIdHash.SessionIdHash Evergreen.V313.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V313.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V313.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V313.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V313.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Evergreen.V313.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.ChannelName.ChannelName (Evergreen.V313.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
        (Evergreen.V313.NonemptyDict.NonemptyDict
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) Evergreen.V313.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Evergreen.V313.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Maybe (Evergreen.V313.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V313.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V313.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V313.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V313.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V313.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V313.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) (Evergreen.V313.Discord.OptionalData String) (Evergreen.V313.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
        (Evergreen.V313.MembersAndOwner.MembersAndOwner
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Evergreen.V313.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId) Evergreen.V313.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId) Evergreen.V313.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V313.Call.ServerChange
    | Server_Game (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Game.LocalChange
    | Server_Drawing (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Drawing.AnchorType Evergreen.V313.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V313.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V313.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V313.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V313.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V313.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V313.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V313.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V313.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V313.Id.AnyGuildOrDmId Evergreen.V313.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V313.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels) (Maybe Evergreen.V313.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId) (Evergreen.V313.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V313.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V313.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V313.Local.Local LocalMsg Evergreen.V313.LocalState.LocalState
    , admin : Evergreen.V313.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId, Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V313.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V313.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V313.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V313.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ) (Evergreen.V313.NonemptyDict.NonemptyDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V313.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V313.Scroll.ScrollPosition
    , textEditor : Evergreen.V313.TextEditor.Model
    , profilePictureEditor : Evergreen.V313.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId, Evergreen.V313.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V313.Emoji.Model
    , voiceChat : Evergreen.V313.Call.Model
    , games : SeqDict.SeqDict Evergreen.V313.Id.GuildOrDmId Evergreen.V313.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V313.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V313.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V313.Range.Range
                , direction : Evergreen.V313.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V313.NonemptyDict.NonemptyDict Int Evergreen.V313.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V313.NonemptyDict.NonemptyDict Int Evergreen.V313.Touch.Touch
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
    | AdminToFrontend Evergreen.V313.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V313.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V313.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V313.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V313.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V313.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V313.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V313.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V313.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V313.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V313.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V313.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V313.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V313.Audio.LoadError Evergreen.V313.Audio.Source
    , startupData : Evergreen.V313.Ports.StartupData
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V313.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V313.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V313.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V313.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V313.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId, Evergreen.V313.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V313.DmChannelId.DmChannelId, Evergreen.V313.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId, Evergreen.V313.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId, Evergreen.V313.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V313.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V313.NonemptyDict.NonemptyDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V313.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V313.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V313.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V313.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V313.DmChannelId.DmChannelId Evergreen.V313.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) Evergreen.V313.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.Slack.Id Evergreen.V313.Slack.ChannelId) Evergreen.V313.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V313.OneToOne.OneToOne String (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    , slackUsers : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.Slack.Id Evergreen.V313.Slack.UserId) (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
    , slackServers : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.Slack.Id Evergreen.V313.Slack.TeamId) (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    , slackToken : Maybe Evergreen.V313.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V313.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V313.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V313.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V313.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V313.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V313.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V313.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V313.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Evergreen.V313.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId, Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V313.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V313.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V313.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V313.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.LocalState.LoadingDiscordChannel (List Evergreen.V313.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V313.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId) Evergreen.V313.Sticker.StickerData
    , discordStickers : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.Discord.Id Evergreen.V313.Discord.StickerId) (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId) Evergreen.V313.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V313.OneToOne.OneToOne Evergreen.V313.RichText.DiscordCustomEmojiIdAndName (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V313.Postmark.ApiKey
    , serverSecret : Evergreen.V313.SecretId.SecretId Evergreen.V313.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V313.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.GamePublicId) ( Evergreen.V313.DmChannelId.GuildOrFullDmId, Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V313.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V313.DmChannelId.DmChannelId Evergreen.V313.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V313.Id.DiscordGuildOrDmId Evergreen.V313.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V313.Id.Id Evergreen.V313.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V313.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V313.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V313.Untrusted.Untrusted Evergreen.V313.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V313.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V313.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V313.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V313.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V313.PersonName.PersonName Evergreen.V313.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V313.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V313.Slack.OAuthCode Evergreen.V313.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V313.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V313.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V313.Id.Id Evergreen.V313.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V313.EmailAddress.EmailAddress (Result Evergreen.V313.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V313.EmailAddress.EmailAddress (Result Evergreen.V313.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V313.EmailAddress.EmailAddress (Result Evergreen.V313.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V313.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMaybeMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Result Evergreen.V313.Discord.HttpError Evergreen.V313.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V313.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Result Evergreen.V313.Discord.HttpError Evergreen.V313.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) (Result Evergreen.V313.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) (Result Evergreen.V313.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) (Result Evergreen.V313.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) (Result Evergreen.V313.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji (Result Evergreen.V313.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji (Result Evergreen.V313.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji (Result Evergreen.V313.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji (Result Evergreen.V313.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V313.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V313.Discord.HttpError (List ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId, Maybe Evergreen.V313.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Effect.Time.Posix Evergreen.V313.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V313.Slack.CurrentUser
            , team : Evergreen.V313.Slack.Team
            , users : List Evergreen.V313.Slack.User
            , channels : List ( Evergreen.V313.Slack.Channel, List Evergreen.V313.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Result Effect.Http.Error Evergreen.V313.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V313.Local.ChangeId Effect.Time.Posix Evergreen.V313.Call.CallId Evergreen.V313.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V313.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V313.Local.ChangeId Effect.Time.Posix Evergreen.V313.Call.CallId Evergreen.V313.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V313.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V313.Local.ChangeId Evergreen.V313.Call.ConnectionId Evergreen.V313.Cloudflare.RealtimeSessionId (List Evergreen.V313.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V313.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V313.Local.ChangeId Evergreen.V313.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Discord.UserAuth (Result Evergreen.V313.Discord.HttpError Evergreen.V313.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Result Evergreen.V313.Discord.HttpError Evergreen.V313.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
        (Result
            Evergreen.V313.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId
                , members : List (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
                }
            , List
                ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId
                , { guild : Evergreen.V313.Discord.GatewayGuild
                  , channels : List Evergreen.V313.Discord.Channel
                  , icon : Maybe Evergreen.V313.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Bool Evergreen.V313.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V313.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.AttachmentId, Evergreen.V313.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V313.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.AttachmentId, Evergreen.V313.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V313.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V313.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V313.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V313.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) (Result Evergreen.V313.Discord.HttpError (List Evergreen.V313.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Result Evergreen.V313.Discord.HttpError (List Evergreen.V313.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V313.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V313.DmChannelId.DmChannelId Evergreen.V313.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V313.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V313.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V313.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
        (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V313.Discord.HttpError
            { guild : Evergreen.V313.Discord.GatewayGuild
            , channels : List Evergreen.V313.Discord.Channel
            , icon : Maybe Evergreen.V313.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Result Evergreen.V313.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V313.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (List ( Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId, Result Effect.Http.Error Evergreen.V313.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId, Result Effect.Http.Error Evergreen.V313.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (List ( Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V313.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V313.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V313.Discord.HttpError (List Evergreen.V313.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V313.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V313.SecretId.SecretId Evergreen.V313.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V313.FileStatus.FileHash Int (Maybe (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
