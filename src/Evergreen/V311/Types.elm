module Evergreen.V311.Types exposing (..)

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
import Evergreen.V311.AiChat
import Evergreen.V311.Audio
import Evergreen.V311.Call
import Evergreen.V311.ChannelDescription
import Evergreen.V311.ChannelName
import Evergreen.V311.Cloudflare
import Evergreen.V311.Coord
import Evergreen.V311.CssPixels
import Evergreen.V311.CustomEmoji
import Evergreen.V311.Discord
import Evergreen.V311.DiscordAttachmentId
import Evergreen.V311.DiscordUserData
import Evergreen.V311.DmChannel
import Evergreen.V311.DmChannelId
import Evergreen.V311.Drawing
import Evergreen.V311.Editable
import Evergreen.V311.EmailAddress
import Evergreen.V311.Embed
import Evergreen.V311.Emoji
import Evergreen.V311.FileStatus
import Evergreen.V311.Game
import Evergreen.V311.Go
import Evergreen.V311.GuildName
import Evergreen.V311.Id
import Evergreen.V311.ImageEditor
import Evergreen.V311.ImageViewer
import Evergreen.V311.LinkedAndOtherDiscordUsers
import Evergreen.V311.Local
import Evergreen.V311.LocalState
import Evergreen.V311.Log
import Evergreen.V311.LoginForm
import Evergreen.V311.MembersAndOwner
import Evergreen.V311.Message
import Evergreen.V311.MessageInput
import Evergreen.V311.MessageView
import Evergreen.V311.MyUi
import Evergreen.V311.NonemptyDict
import Evergreen.V311.NonemptySet
import Evergreen.V311.OneOrGreater
import Evergreen.V311.OneToOne
import Evergreen.V311.Pages.Admin
import Evergreen.V311.Pagination
import Evergreen.V311.PersonName
import Evergreen.V311.Ports
import Evergreen.V311.Postmark
import Evergreen.V311.Range
import Evergreen.V311.RichText
import Evergreen.V311.Route
import Evergreen.V311.Scroll
import Evergreen.V311.SecretId
import Evergreen.V311.SessionIdHash
import Evergreen.V311.Slack
import Evergreen.V311.Sticker
import Evergreen.V311.TextEditor
import Evergreen.V311.ToBackendLog
import Evergreen.V311.Touch
import Evergreen.V311.TwoFactorAuthentication
import Evergreen.V311.Ui.Anim
import Evergreen.V311.Untrusted
import Evergreen.V311.User
import Evergreen.V311.UserAgent
import Evergreen.V311.UserSession
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
    | LoginFormMsg Evergreen.V311.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V311.Pages.Admin.Msg
    | PressedLogOut Evergreen.V311.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V311.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V311.Route.Route
    | SelectedFilesToAttach ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V311.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V311.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V311.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V311.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V311.NonemptyDict.NonemptyDict Int Evergreen.V311.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V311.NonemptyDict.NonemptyDict Int Evergreen.V311.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRoute Evergreen.V311.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V311.NonemptySet.NonemptySet (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V311.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V311.AiChat.Msg
    | GameMsg Evergreen.V311.Game.Msg
    | GoSpectatorMsg Evergreen.V311.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V311.Editable.Msg Evergreen.V311.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V311.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V311.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
        { fileId : Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
        { fileId : Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V311.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage Evergreen.V311.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V311.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V311.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V311.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V311.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.User.NotificationLevel
    | GotStartupData Evergreen.V311.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V311.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId
        , otherUserId : Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRoute Evergreen.V311.MessageInput.Msg
    | MessageInputMsg Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRoute Evergreen.V311.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V311.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V311.Range.Range, Evergreen.V311.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V311.Range.Range, Evergreen.V311.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V311.Call.FromJs)
    | VoiceChatMsg Evergreen.V311.Call.Msg
    | PressedChannelHeaderTab Evergreen.V311.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V311.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V311.Audio.LoadError Evergreen.V311.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V311.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V311.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) Evergreen.V311.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.LocalState.DiscordFrontendGuild
    , user : Evergreen.V311.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.User.FrontendUser
    , discordUsers : Evergreen.V311.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V311.SessionIdHash.SessionIdHash Evergreen.V311.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V311.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId) Evergreen.V311.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId) Evergreen.V311.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V311.Call.CallId (Evergreen.V311.NonemptyDict.NonemptyDict ( Evergreen.V311.Id.Id Evergreen.V311.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V311.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V311.Go.PublicGoMatchData Evergreen.V311.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V311.Route.Route
    , windowSize : Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V311.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V311.Audio.LoadError Evergreen.V311.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V311.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V311.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V311.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V311.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V311.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.ChannelName.ChannelName Evergreen.V311.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.ChannelName.ChannelName Evergreen.V311.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.UserSession.ToBeFilledInByBackend (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V311.GuildName.GuildName (Evergreen.V311.UserSession.ToBeFilledInByBackend (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V311.Id.DiscordGuildOrDmId_DmData (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V311.UserSession.SetViewing
    | Local_SetName Evergreen.V311.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V311.Id.GuildOrDmId (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V311.Id.GuildOrDmId (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId) (Evergreen.V311.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V311.Id.DiscordGuildOrDmId (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V311.Id.DiscordGuildOrDmId (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId) (Evergreen.V311.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V311.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V311.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V311.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V311.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V311.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V311.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V311.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V311.NonemptySet.NonemptySet (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V311.Call.LocalChange
    | Local_Game Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Game.LocalChange
    | Local_Drawing Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Drawing.AnchorType Evergreen.V311.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Effect.Time.Posix Evergreen.V311.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V311.RichText.RichText (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))) Evergreen.V311.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId) Evergreen.V311.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V311.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V311.RichText.RichText (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))) Evergreen.V311.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId) Evergreen.V311.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.ChannelName.ChannelName Evergreen.V311.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.ChannelName.ChannelName Evergreen.V311.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V311.LocalState.JoinGuildError
            { guildId : Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId
            , guild : Evergreen.V311.LocalState.FrontendGuild
            , owner : Evergreen.V311.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V311.RichText.RichText (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))) (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V311.RichText.RichText (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V311.Id.DiscordGuildOrDmId_DmData (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V311.RichText.RichText (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V311.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V311.SessionIdHash.SessionIdHash Evergreen.V311.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V311.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V311.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V311.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V311.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Evergreen.V311.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.ChannelName.ChannelName (Evergreen.V311.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
        (Evergreen.V311.NonemptyDict.NonemptyDict
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) Evergreen.V311.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Evergreen.V311.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Maybe (Evergreen.V311.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V311.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V311.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V311.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V311.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V311.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V311.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) (Evergreen.V311.Discord.OptionalData String) (Evergreen.V311.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
        (Evergreen.V311.MembersAndOwner.MembersAndOwner
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Evergreen.V311.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId) Evergreen.V311.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId) Evergreen.V311.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V311.Call.ServerChange
    | Server_Game (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Game.LocalChange
    | Server_Drawing (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Drawing.AnchorType Evergreen.V311.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V311.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V311.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V311.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V311.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V311.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V311.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V311.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V311.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V311.Id.AnyGuildOrDmId Evergreen.V311.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V311.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels) (Maybe Evergreen.V311.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId) (Evergreen.V311.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V311.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V311.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V311.Local.Local LocalMsg Evergreen.V311.LocalState.LocalState
    , admin : Evergreen.V311.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId, Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V311.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V311.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V311.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V311.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ) (Evergreen.V311.NonemptyDict.NonemptyDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V311.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V311.Scroll.ScrollPosition
    , textEditor : Evergreen.V311.TextEditor.Model
    , profilePictureEditor : Evergreen.V311.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId, Evergreen.V311.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V311.Emoji.Model
    , voiceChat : Evergreen.V311.Call.Model
    , games : SeqDict.SeqDict Evergreen.V311.Id.GuildOrDmId Evergreen.V311.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V311.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V311.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V311.Range.Range
                , direction : Evergreen.V311.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V311.NonemptyDict.NonemptyDict Int Evergreen.V311.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V311.NonemptyDict.NonemptyDict Int Evergreen.V311.Touch.Touch
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
    | AdminToFrontend Evergreen.V311.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V311.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V311.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V311.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V311.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V311.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V311.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V311.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V311.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V311.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V311.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V311.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V311.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V311.Audio.LoadError Evergreen.V311.Audio.Source
    , startupData : Evergreen.V311.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V311.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V311.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V311.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V311.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V311.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId, Evergreen.V311.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V311.DmChannelId.DmChannelId, Evergreen.V311.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId, Evergreen.V311.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId, Evergreen.V311.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V311.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V311.NonemptyDict.NonemptyDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V311.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V311.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V311.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V311.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V311.DmChannelId.DmChannelId Evergreen.V311.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) Evergreen.V311.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.Slack.Id Evergreen.V311.Slack.ChannelId) Evergreen.V311.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V311.OneToOne.OneToOne String (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    , slackUsers : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.Slack.Id Evergreen.V311.Slack.UserId) (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
    , slackServers : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.Slack.Id Evergreen.V311.Slack.TeamId) (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    , slackToken : Maybe Evergreen.V311.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V311.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V311.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V311.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V311.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V311.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V311.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V311.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V311.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Evergreen.V311.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId, Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V311.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V311.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V311.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V311.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.LocalState.LoadingDiscordChannel (List Evergreen.V311.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V311.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId) Evergreen.V311.Sticker.StickerData
    , discordStickers : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.Discord.Id Evergreen.V311.Discord.StickerId) (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId) Evergreen.V311.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V311.OneToOne.OneToOne Evergreen.V311.RichText.DiscordCustomEmojiIdAndName (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V311.Postmark.ApiKey
    , serverSecret : Evergreen.V311.SecretId.SecretId Evergreen.V311.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V311.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.GamePublicId) ( Evergreen.V311.DmChannelId.GuildOrFullDmId, Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V311.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V311.DmChannelId.DmChannelId Evergreen.V311.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V311.Id.DiscordGuildOrDmId Evergreen.V311.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V311.Id.Id Evergreen.V311.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V311.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V311.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V311.Untrusted.Untrusted Evergreen.V311.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V311.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V311.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V311.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V311.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V311.PersonName.PersonName Evergreen.V311.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V311.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V311.Slack.OAuthCode Evergreen.V311.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V311.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V311.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V311.Id.Id Evergreen.V311.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V311.EmailAddress.EmailAddress (Result Evergreen.V311.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V311.EmailAddress.EmailAddress (Result Evergreen.V311.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V311.EmailAddress.EmailAddress (Result Evergreen.V311.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V311.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMaybeMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Result Evergreen.V311.Discord.HttpError Evergreen.V311.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V311.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Result Evergreen.V311.Discord.HttpError Evergreen.V311.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) (Result Evergreen.V311.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) (Result Evergreen.V311.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) (Result Evergreen.V311.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) (Result Evergreen.V311.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji (Result Evergreen.V311.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji (Result Evergreen.V311.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji (Result Evergreen.V311.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji (Result Evergreen.V311.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V311.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V311.Discord.HttpError (List ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId, Maybe Evergreen.V311.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Effect.Time.Posix Evergreen.V311.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V311.Slack.CurrentUser
            , team : Evergreen.V311.Slack.Team
            , users : List Evergreen.V311.Slack.User
            , channels : List ( Evergreen.V311.Slack.Channel, List Evergreen.V311.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Result Effect.Http.Error Evergreen.V311.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V311.Local.ChangeId Effect.Time.Posix Evergreen.V311.Call.CallId Evergreen.V311.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V311.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V311.Local.ChangeId Effect.Time.Posix Evergreen.V311.Call.CallId Evergreen.V311.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V311.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V311.Local.ChangeId Evergreen.V311.Call.ConnectionId Evergreen.V311.Cloudflare.RealtimeSessionId (List Evergreen.V311.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V311.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V311.Local.ChangeId Evergreen.V311.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Discord.UserAuth (Result Evergreen.V311.Discord.HttpError Evergreen.V311.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Result Evergreen.V311.Discord.HttpError Evergreen.V311.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
        (Result
            Evergreen.V311.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId
                , members : List (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
                }
            , List
                ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId
                , { guild : Evergreen.V311.Discord.GatewayGuild
                  , channels : List Evergreen.V311.Discord.Channel
                  , icon : Maybe Evergreen.V311.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Bool Evergreen.V311.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V311.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.AttachmentId, Evergreen.V311.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V311.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.AttachmentId, Evergreen.V311.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V311.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V311.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V311.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V311.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) (Result Evergreen.V311.Discord.HttpError (List Evergreen.V311.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Result Evergreen.V311.Discord.HttpError (List Evergreen.V311.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V311.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V311.DmChannelId.DmChannelId Evergreen.V311.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V311.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V311.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V311.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
        (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V311.Discord.HttpError
            { guild : Evergreen.V311.Discord.GatewayGuild
            , channels : List Evergreen.V311.Discord.Channel
            , icon : Maybe Evergreen.V311.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Result Evergreen.V311.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V311.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (List ( Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId, Result Effect.Http.Error Evergreen.V311.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId, Result Effect.Http.Error Evergreen.V311.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (List ( Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V311.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V311.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V311.Discord.HttpError (List Evergreen.V311.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V311.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V311.SecretId.SecretId Evergreen.V311.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V311.FileStatus.FileHash Int (Maybe (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
