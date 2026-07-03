module Evergreen.V301.Types exposing (..)

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
import Evergreen.V301.AiChat
import Evergreen.V301.Audio
import Evergreen.V301.Call
import Evergreen.V301.ChannelDescription
import Evergreen.V301.ChannelName
import Evergreen.V301.Cloudflare
import Evergreen.V301.Coord
import Evergreen.V301.CssPixels
import Evergreen.V301.CustomEmoji
import Evergreen.V301.Discord
import Evergreen.V301.DiscordAttachmentId
import Evergreen.V301.DiscordUserData
import Evergreen.V301.DmChannel
import Evergreen.V301.Drawing
import Evergreen.V301.Editable
import Evergreen.V301.EmailAddress
import Evergreen.V301.Embed
import Evergreen.V301.Emoji
import Evergreen.V301.FileStatus
import Evergreen.V301.Game
import Evergreen.V301.Go
import Evergreen.V301.GuildName
import Evergreen.V301.Id
import Evergreen.V301.ImageEditor
import Evergreen.V301.ImageViewer
import Evergreen.V301.LinkedAndOtherDiscordUsers
import Evergreen.V301.Local
import Evergreen.V301.LocalState
import Evergreen.V301.Log
import Evergreen.V301.LoginForm
import Evergreen.V301.MembersAndOwner
import Evergreen.V301.Message
import Evergreen.V301.MessageInput
import Evergreen.V301.MessageView
import Evergreen.V301.MyUi
import Evergreen.V301.NonemptyDict
import Evergreen.V301.NonemptySet
import Evergreen.V301.OneOrGreater
import Evergreen.V301.OneToOne
import Evergreen.V301.Pages.Admin
import Evergreen.V301.Pagination
import Evergreen.V301.PersonName
import Evergreen.V301.Ports
import Evergreen.V301.Postmark
import Evergreen.V301.Range
import Evergreen.V301.RichText
import Evergreen.V301.Route
import Evergreen.V301.SecretId
import Evergreen.V301.SessionIdHash
import Evergreen.V301.Slack
import Evergreen.V301.Sticker
import Evergreen.V301.TextEditor
import Evergreen.V301.ToBackendLog
import Evergreen.V301.Touch
import Evergreen.V301.TwoFactorAuthentication
import Evergreen.V301.Ui.Anim
import Evergreen.V301.Untrusted
import Evergreen.V301.User
import Evergreen.V301.UserAgent
import Evergreen.V301.UserSession
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
    | LoginFormMsg Evergreen.V301.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V301.Pages.Admin.Msg
    | PressedLogOut Evergreen.V301.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V301.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V301.Route.Route
    | SelectedFilesToAttach ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V301.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V301.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V301.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V301.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V301.NonemptyDict.NonemptyDict Int Evergreen.V301.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V301.NonemptyDict.NonemptyDict Int Evergreen.V301.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V301.NonemptySet.NonemptySet (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V301.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V301.AiChat.Msg
    | GameMsg Evergreen.V301.Game.Msg
    | GoSpectatorMsg Evergreen.V301.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V301.Editable.Msg Evergreen.V301.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V301.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V301.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
        { fileId : Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
        { fileId : Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V301.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage Evergreen.V301.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V301.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V301.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V301.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V301.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.User.NotificationLevel
    | GotStartupData Evergreen.V301.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V301.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId
        , otherUserId : Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRoute Evergreen.V301.MessageInput.Msg
    | MessageInputMsg Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRoute Evergreen.V301.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V301.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V301.Range.Range, Evergreen.V301.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V301.Range.Range, Evergreen.V301.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V301.Call.FromJs)
    | VoiceChatMsg Evergreen.V301.Call.Msg
    | PressedChannelHeaderTab Evergreen.V301.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V301.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V301.Audio.LoadError Evergreen.V301.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V301.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V301.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) Evergreen.V301.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.LocalState.DiscordFrontendGuild
    , user : Evergreen.V301.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.User.FrontendUser
    , discordUsers : Evergreen.V301.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V301.SessionIdHash.SessionIdHash Evergreen.V301.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V301.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId) Evergreen.V301.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId) Evergreen.V301.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V301.Call.CallId (Evergreen.V301.NonemptyDict.NonemptyDict ( Evergreen.V301.Id.Id Evergreen.V301.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V301.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V301.Go.PublicGoMatchData Evergreen.V301.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V301.Route.Route
    , windowSize : Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V301.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V301.Audio.LoadError Evergreen.V301.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V301.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V301.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V301.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V301.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V301.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.ChannelName.ChannelName Evergreen.V301.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.ChannelName.ChannelName Evergreen.V301.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.UserSession.ToBeFilledInByBackend (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V301.GuildName.GuildName (Evergreen.V301.UserSession.ToBeFilledInByBackend (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V301.Id.GuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V301.Id.DiscordGuildOrDmId_DmData (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V301.UserSession.SetViewing
    | Local_SetName Evergreen.V301.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V301.Id.GuildOrDmId (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V301.Id.GuildOrDmId (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId) (Evergreen.V301.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V301.Id.DiscordGuildOrDmId (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V301.Id.DiscordGuildOrDmId (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId) (Evergreen.V301.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V301.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V301.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V301.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V301.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V301.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V301.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V301.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V301.NonemptySet.NonemptySet (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V301.Call.LocalChange
    | Local_Game
        { otherUserId : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
        }
        Evergreen.V301.Game.LocalChange
    | Local_Drawing Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Drawing.AnchorType Evergreen.V301.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Effect.Time.Posix Evergreen.V301.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V301.RichText.RichText (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))) Evergreen.V301.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId) Evergreen.V301.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V301.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V301.RichText.RichText (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))) Evergreen.V301.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId) Evergreen.V301.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.ChannelName.ChannelName Evergreen.V301.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.ChannelName.ChannelName Evergreen.V301.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V301.LocalState.JoinGuildError
            { guildId : Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId
            , guild : Evergreen.V301.LocalState.FrontendGuild
            , owner : Evergreen.V301.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Id.GuildOrDmId Evergreen.V301.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Id.GuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Id.GuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Id.GuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V301.RichText.RichText (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))) (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V301.RichText.RichText (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V301.Id.DiscordGuildOrDmId_DmData (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V301.RichText.RichText (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V301.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V301.SessionIdHash.SessionIdHash Evergreen.V301.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V301.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V301.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V301.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V301.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Evergreen.V301.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.ChannelName.ChannelName (Evergreen.V301.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)
        (Evergreen.V301.NonemptyDict.NonemptyDict
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) Evergreen.V301.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Evergreen.V301.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Maybe (Evergreen.V301.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V301.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V301.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V301.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V301.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V301.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V301.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) (Evergreen.V301.Discord.OptionalData String) (Evergreen.V301.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
        (Evergreen.V301.MembersAndOwner.MembersAndOwner
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Evergreen.V301.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId) Evergreen.V301.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId) Evergreen.V301.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V301.Call.ServerChange
    | Server_Game
        (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
        { otherUserId : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
        }
        Evergreen.V301.Game.LocalChange
    | Server_Drawing (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Drawing.AnchorType Evergreen.V301.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V301.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V301.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V301.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V301.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V301.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V301.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V301.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V301.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V301.Id.AnyGuildOrDmId Evergreen.V301.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V301.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels) (Maybe Evergreen.V301.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId) (Evergreen.V301.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V301.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V301.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V301.Local.Local LocalMsg Evergreen.V301.LocalState.LocalState
    , admin : Evergreen.V301.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId, Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V301.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V301.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V301.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V301.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ) (Evergreen.V301.NonemptyDict.NonemptyDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V301.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V301.TextEditor.Model
    , profilePictureEditor : Evergreen.V301.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId, Evergreen.V301.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V301.Emoji.Model
    , voiceChat : Evergreen.V301.Call.Model
    , currentDmGame : SeqDict.SeqDict ( Evergreen.V301.Id.Id Evergreen.V301.Id.UserId, Maybe (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) ) Evergreen.V301.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V301.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V301.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V301.Range.Range
                , direction : Evergreen.V301.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_WordSpellingGameBoard


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V301.NonemptyDict.NonemptyDict Int Evergreen.V301.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V301.NonemptyDict.NonemptyDict Int Evergreen.V301.Touch.Touch
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
    | AdminToFrontend Evergreen.V301.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V301.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V301.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V301.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V301.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V301.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V301.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V301.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V301.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V301.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V301.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V301.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V301.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V301.Audio.LoadError Evergreen.V301.Audio.Source
    , startupData : Evergreen.V301.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V301.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V301.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V301.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V301.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V301.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId, Evergreen.V301.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V301.DmChannel.DmChannelId, Evergreen.V301.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId, Evergreen.V301.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId, Evergreen.V301.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V301.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V301.NonemptyDict.NonemptyDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V301.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V301.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V301.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V301.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V301.DmChannel.DmChannelId Evergreen.V301.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) Evergreen.V301.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.Slack.Id Evergreen.V301.Slack.ChannelId) Evergreen.V301.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V301.OneToOne.OneToOne String (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    , slackUsers : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.Slack.Id Evergreen.V301.Slack.UserId) (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
    , slackServers : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.Slack.Id Evergreen.V301.Slack.TeamId) (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    , slackToken : Maybe Evergreen.V301.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V301.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V301.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V301.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V301.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V301.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V301.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V301.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V301.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Evergreen.V301.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId, Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V301.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V301.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V301.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V301.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.LocalState.LoadingDiscordChannel (List Evergreen.V301.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V301.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId) Evergreen.V301.Sticker.StickerData
    , discordStickers : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.Discord.Id Evergreen.V301.Discord.StickerId) (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId) Evergreen.V301.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V301.OneToOne.OneToOne Evergreen.V301.RichText.DiscordCustomEmojiIdAndName (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V301.Postmark.ApiKey
    , serverSecret : Evergreen.V301.SecretId.SecretId Evergreen.V301.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V301.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.GamePublicId) ( Evergreen.V301.DmChannel.DmChannelId, Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId )
    }


type alias FrontendMsg =
    Evergreen.V301.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V301.DmChannel.DmChannelId Evergreen.V301.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V301.Id.DiscordGuildOrDmId Evergreen.V301.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V301.Id.Id Evergreen.V301.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V301.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V301.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V301.Untrusted.Untrusted Evergreen.V301.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V301.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V301.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V301.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V301.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V301.PersonName.PersonName Evergreen.V301.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V301.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V301.Slack.OAuthCode Evergreen.V301.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V301.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V301.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V301.Id.Id Evergreen.V301.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V301.EmailAddress.EmailAddress (Result Evergreen.V301.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V301.EmailAddress.EmailAddress (Result Evergreen.V301.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V301.EmailAddress.EmailAddress (Result Evergreen.V301.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V301.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMaybeMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Result Evergreen.V301.Discord.HttpError Evergreen.V301.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V301.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Result Evergreen.V301.Discord.HttpError Evergreen.V301.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) (Result Evergreen.V301.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) (Result Evergreen.V301.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) (Result Evergreen.V301.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) (Result Evergreen.V301.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji (Result Evergreen.V301.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji (Result Evergreen.V301.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji (Result Evergreen.V301.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji (Result Evergreen.V301.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V301.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V301.Discord.HttpError (List ( Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId, Maybe Evergreen.V301.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Effect.Time.Posix Evergreen.V301.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V301.Slack.CurrentUser
            , team : Evergreen.V301.Slack.Team
            , users : List Evergreen.V301.Slack.User
            , channels : List ( Evergreen.V301.Slack.Channel, List Evergreen.V301.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Result Effect.Http.Error Evergreen.V301.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V301.Local.ChangeId Effect.Time.Posix Evergreen.V301.Call.CallId Evergreen.V301.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V301.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V301.Local.ChangeId Effect.Time.Posix Evergreen.V301.Call.CallId Evergreen.V301.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V301.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V301.Local.ChangeId Evergreen.V301.Call.ConnectionId Evergreen.V301.Cloudflare.RealtimeSessionId (List Evergreen.V301.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V301.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V301.Local.ChangeId Evergreen.V301.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Discord.UserAuth (Result Evergreen.V301.Discord.HttpError Evergreen.V301.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Result Evergreen.V301.Discord.HttpError Evergreen.V301.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
        (Result
            Evergreen.V301.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId
                , members : List (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
                }
            , List
                ( Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId
                , { guild : Evergreen.V301.Discord.GatewayGuild
                  , channels : List Evergreen.V301.Discord.Channel
                  , icon : Maybe Evergreen.V301.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Bool Evergreen.V301.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V301.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V301.Discord.Id Evergreen.V301.Discord.AttachmentId, Evergreen.V301.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V301.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V301.Discord.Id Evergreen.V301.Discord.AttachmentId, Evergreen.V301.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V301.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V301.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V301.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V301.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) (Result Evergreen.V301.Discord.HttpError (List Evergreen.V301.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Result Evergreen.V301.Discord.HttpError (List Evergreen.V301.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V301.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V301.DmChannel.DmChannelId Evergreen.V301.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V301.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V301.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V301.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
        (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V301.Discord.HttpError
            { guild : Evergreen.V301.Discord.GatewayGuild
            , channels : List Evergreen.V301.Discord.Channel
            , icon : Maybe Evergreen.V301.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Result Evergreen.V301.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V301.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (List ( Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId, Result Effect.Http.Error Evergreen.V301.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId, Result Effect.Http.Error Evergreen.V301.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (List ( Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V301.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V301.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V301.Discord.HttpError (List Evergreen.V301.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V301.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V301.SecretId.SecretId Evergreen.V301.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V301.FileStatus.FileHash Int (Maybe (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels))
