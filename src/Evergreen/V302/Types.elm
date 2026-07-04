module Evergreen.V302.Types exposing (..)

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
import Evergreen.V302.AiChat
import Evergreen.V302.Audio
import Evergreen.V302.Call
import Evergreen.V302.ChannelDescription
import Evergreen.V302.ChannelName
import Evergreen.V302.Cloudflare
import Evergreen.V302.Coord
import Evergreen.V302.CssPixels
import Evergreen.V302.CustomEmoji
import Evergreen.V302.Discord
import Evergreen.V302.DiscordAttachmentId
import Evergreen.V302.DiscordUserData
import Evergreen.V302.DmChannel
import Evergreen.V302.Drawing
import Evergreen.V302.Editable
import Evergreen.V302.EmailAddress
import Evergreen.V302.Embed
import Evergreen.V302.Emoji
import Evergreen.V302.FileStatus
import Evergreen.V302.Game
import Evergreen.V302.Go
import Evergreen.V302.GuildName
import Evergreen.V302.Id
import Evergreen.V302.ImageEditor
import Evergreen.V302.ImageViewer
import Evergreen.V302.LinkedAndOtherDiscordUsers
import Evergreen.V302.Local
import Evergreen.V302.LocalState
import Evergreen.V302.Log
import Evergreen.V302.LoginForm
import Evergreen.V302.MembersAndOwner
import Evergreen.V302.Message
import Evergreen.V302.MessageInput
import Evergreen.V302.MessageView
import Evergreen.V302.MyUi
import Evergreen.V302.NonemptyDict
import Evergreen.V302.NonemptySet
import Evergreen.V302.OneOrGreater
import Evergreen.V302.OneToOne
import Evergreen.V302.Pages.Admin
import Evergreen.V302.Pagination
import Evergreen.V302.PersonName
import Evergreen.V302.Ports
import Evergreen.V302.Postmark
import Evergreen.V302.Range
import Evergreen.V302.RichText
import Evergreen.V302.Route
import Evergreen.V302.SecretId
import Evergreen.V302.SessionIdHash
import Evergreen.V302.Slack
import Evergreen.V302.Sticker
import Evergreen.V302.TextEditor
import Evergreen.V302.ToBackendLog
import Evergreen.V302.Touch
import Evergreen.V302.TwoFactorAuthentication
import Evergreen.V302.Ui.Anim
import Evergreen.V302.Untrusted
import Evergreen.V302.User
import Evergreen.V302.UserAgent
import Evergreen.V302.UserSession
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
    | LoginFormMsg Evergreen.V302.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V302.Pages.Admin.Msg
    | PressedLogOut Evergreen.V302.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V302.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V302.Route.Route
    | SelectedFilesToAttach ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V302.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V302.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V302.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V302.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V302.NonemptyDict.NonemptyDict Int Evergreen.V302.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V302.NonemptyDict.NonemptyDict Int Evergreen.V302.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V302.NonemptySet.NonemptySet (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V302.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V302.AiChat.Msg
    | GameMsg Evergreen.V302.Game.Msg
    | GoSpectatorMsg Evergreen.V302.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V302.Editable.Msg Evergreen.V302.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V302.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V302.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
        { fileId : Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
        { fileId : Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V302.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage Evergreen.V302.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V302.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V302.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V302.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V302.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.User.NotificationLevel
    | GotStartupData Evergreen.V302.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V302.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId
        , otherUserId : Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRoute Evergreen.V302.MessageInput.Msg
    | MessageInputMsg Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRoute Evergreen.V302.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V302.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V302.Range.Range, Evergreen.V302.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V302.Range.Range, Evergreen.V302.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V302.Call.FromJs)
    | VoiceChatMsg Evergreen.V302.Call.Msg
    | PressedChannelHeaderTab Evergreen.V302.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V302.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V302.Audio.LoadError Evergreen.V302.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V302.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V302.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) Evergreen.V302.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.LocalState.DiscordFrontendGuild
    , user : Evergreen.V302.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.User.FrontendUser
    , discordUsers : Evergreen.V302.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V302.SessionIdHash.SessionIdHash Evergreen.V302.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V302.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId) Evergreen.V302.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId) Evergreen.V302.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V302.Call.CallId (Evergreen.V302.NonemptyDict.NonemptyDict ( Evergreen.V302.Id.Id Evergreen.V302.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V302.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V302.Go.PublicGoMatchData Evergreen.V302.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V302.Route.Route
    , windowSize : Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V302.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V302.Audio.LoadError Evergreen.V302.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V302.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V302.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V302.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V302.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V302.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.ChannelName.ChannelName Evergreen.V302.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.ChannelName.ChannelName Evergreen.V302.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.UserSession.ToBeFilledInByBackend (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V302.GuildName.GuildName (Evergreen.V302.UserSession.ToBeFilledInByBackend (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V302.Id.GuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V302.Id.DiscordGuildOrDmId_DmData (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V302.UserSession.SetViewing
    | Local_SetName Evergreen.V302.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V302.Id.GuildOrDmId (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V302.Id.GuildOrDmId (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId) (Evergreen.V302.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V302.Id.DiscordGuildOrDmId (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V302.Id.DiscordGuildOrDmId (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId) (Evergreen.V302.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V302.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V302.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V302.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V302.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V302.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V302.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V302.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V302.NonemptySet.NonemptySet (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V302.Call.LocalChange
    | Local_Game
        { otherUserId : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
        }
        Evergreen.V302.Game.LocalChange
    | Local_Drawing Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Drawing.AnchorType Evergreen.V302.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Effect.Time.Posix Evergreen.V302.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V302.RichText.RichText (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))) Evergreen.V302.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId) Evergreen.V302.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V302.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V302.RichText.RichText (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))) Evergreen.V302.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId) Evergreen.V302.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.ChannelName.ChannelName Evergreen.V302.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.ChannelName.ChannelName Evergreen.V302.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V302.LocalState.JoinGuildError
            { guildId : Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId
            , guild : Evergreen.V302.LocalState.FrontendGuild
            , owner : Evergreen.V302.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.GuildOrDmId Evergreen.V302.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.GuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.GuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.GuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V302.RichText.RichText (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))) (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V302.RichText.RichText (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V302.Id.DiscordGuildOrDmId_DmData (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V302.RichText.RichText (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V302.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V302.SessionIdHash.SessionIdHash Evergreen.V302.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V302.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V302.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V302.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V302.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Evergreen.V302.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.ChannelName.ChannelName (Evergreen.V302.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
        (Evergreen.V302.NonemptyDict.NonemptyDict
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) Evergreen.V302.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Evergreen.V302.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Maybe (Evergreen.V302.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V302.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V302.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V302.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V302.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V302.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V302.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) (Evergreen.V302.Discord.OptionalData String) (Evergreen.V302.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
        (Evergreen.V302.MembersAndOwner.MembersAndOwner
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Evergreen.V302.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId) Evergreen.V302.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId) Evergreen.V302.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V302.Call.ServerChange
    | Server_Game
        (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
        { otherUserId : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
        }
        Evergreen.V302.Game.LocalChange
    | Server_Drawing (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Drawing.AnchorType Evergreen.V302.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V302.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V302.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V302.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V302.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V302.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V302.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V302.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V302.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V302.Id.AnyGuildOrDmId Evergreen.V302.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V302.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels) (Maybe Evergreen.V302.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId) (Evergreen.V302.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V302.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V302.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V302.Local.Local LocalMsg Evergreen.V302.LocalState.LocalState
    , admin : Evergreen.V302.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId, Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V302.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V302.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V302.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V302.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ) (Evergreen.V302.NonemptyDict.NonemptyDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V302.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V302.TextEditor.Model
    , profilePictureEditor : Evergreen.V302.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId, Evergreen.V302.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V302.Emoji.Model
    , voiceChat : Evergreen.V302.Call.Model
    , currentDmGame : SeqDict.SeqDict ( Evergreen.V302.Id.Id Evergreen.V302.Id.UserId, Maybe (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) ) Evergreen.V302.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V302.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V302.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V302.Range.Range
                , direction : Evergreen.V302.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_WordSpellingGameBoard


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V302.NonemptyDict.NonemptyDict Int Evergreen.V302.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V302.NonemptyDict.NonemptyDict Int Evergreen.V302.Touch.Touch
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
    | AdminToFrontend Evergreen.V302.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V302.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V302.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V302.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V302.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V302.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V302.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V302.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V302.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V302.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V302.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V302.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V302.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V302.Audio.LoadError Evergreen.V302.Audio.Source
    , startupData : Evergreen.V302.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V302.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V302.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V302.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V302.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V302.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId, Evergreen.V302.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V302.DmChannel.DmChannelId, Evergreen.V302.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId, Evergreen.V302.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId, Evergreen.V302.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V302.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V302.NonemptyDict.NonemptyDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V302.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V302.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V302.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V302.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V302.DmChannel.DmChannelId Evergreen.V302.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) Evergreen.V302.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.Slack.Id Evergreen.V302.Slack.ChannelId) Evergreen.V302.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V302.OneToOne.OneToOne String (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    , slackUsers : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.Slack.Id Evergreen.V302.Slack.UserId) (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
    , slackServers : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.Slack.Id Evergreen.V302.Slack.TeamId) (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    , slackToken : Maybe Evergreen.V302.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V302.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V302.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V302.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V302.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V302.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V302.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V302.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V302.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Evergreen.V302.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId, Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V302.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V302.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V302.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V302.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.LocalState.LoadingDiscordChannel (List Evergreen.V302.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V302.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId) Evergreen.V302.Sticker.StickerData
    , discordStickers : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.Discord.Id Evergreen.V302.Discord.StickerId) (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId) Evergreen.V302.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V302.OneToOne.OneToOne Evergreen.V302.RichText.DiscordCustomEmojiIdAndName (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V302.Postmark.ApiKey
    , serverSecret : Evergreen.V302.SecretId.SecretId Evergreen.V302.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V302.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.GamePublicId) ( Evergreen.V302.DmChannel.DmChannelId, Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId )
    }


type alias FrontendMsg =
    Evergreen.V302.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V302.DmChannel.DmChannelId Evergreen.V302.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V302.Id.DiscordGuildOrDmId Evergreen.V302.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V302.Id.Id Evergreen.V302.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V302.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V302.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V302.Untrusted.Untrusted Evergreen.V302.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V302.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V302.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V302.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V302.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V302.PersonName.PersonName Evergreen.V302.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V302.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V302.Slack.OAuthCode Evergreen.V302.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V302.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V302.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V302.Id.Id Evergreen.V302.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V302.EmailAddress.EmailAddress (Result Evergreen.V302.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V302.EmailAddress.EmailAddress (Result Evergreen.V302.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V302.EmailAddress.EmailAddress (Result Evergreen.V302.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V302.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMaybeMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Result Evergreen.V302.Discord.HttpError Evergreen.V302.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V302.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Result Evergreen.V302.Discord.HttpError Evergreen.V302.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) (Result Evergreen.V302.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) (Result Evergreen.V302.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) (Result Evergreen.V302.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) (Result Evergreen.V302.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji (Result Evergreen.V302.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji (Result Evergreen.V302.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji (Result Evergreen.V302.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji (Result Evergreen.V302.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V302.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V302.Discord.HttpError (List ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId, Maybe Evergreen.V302.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Effect.Time.Posix Evergreen.V302.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V302.Slack.CurrentUser
            , team : Evergreen.V302.Slack.Team
            , users : List Evergreen.V302.Slack.User
            , channels : List ( Evergreen.V302.Slack.Channel, List Evergreen.V302.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Result Effect.Http.Error Evergreen.V302.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V302.Local.ChangeId Effect.Time.Posix Evergreen.V302.Call.CallId Evergreen.V302.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V302.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V302.Local.ChangeId Effect.Time.Posix Evergreen.V302.Call.CallId Evergreen.V302.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V302.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V302.Local.ChangeId Evergreen.V302.Call.ConnectionId Evergreen.V302.Cloudflare.RealtimeSessionId (List Evergreen.V302.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V302.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V302.Local.ChangeId Evergreen.V302.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Discord.UserAuth (Result Evergreen.V302.Discord.HttpError Evergreen.V302.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Result Evergreen.V302.Discord.HttpError Evergreen.V302.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
        (Result
            Evergreen.V302.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId
                , members : List (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
                }
            , List
                ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId
                , { guild : Evergreen.V302.Discord.GatewayGuild
                  , channels : List Evergreen.V302.Discord.Channel
                  , icon : Maybe Evergreen.V302.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Bool Evergreen.V302.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V302.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.AttachmentId, Evergreen.V302.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V302.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.AttachmentId, Evergreen.V302.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V302.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V302.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V302.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V302.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) (Result Evergreen.V302.Discord.HttpError (List Evergreen.V302.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Result Evergreen.V302.Discord.HttpError (List Evergreen.V302.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V302.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V302.DmChannel.DmChannelId Evergreen.V302.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V302.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V302.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V302.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
        (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V302.Discord.HttpError
            { guild : Evergreen.V302.Discord.GatewayGuild
            , channels : List Evergreen.V302.Discord.Channel
            , icon : Maybe Evergreen.V302.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Result Evergreen.V302.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V302.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (List ( Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId, Result Effect.Http.Error Evergreen.V302.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId, Result Effect.Http.Error Evergreen.V302.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (List ( Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V302.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V302.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V302.Discord.HttpError (List Evergreen.V302.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V302.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V302.SecretId.SecretId Evergreen.V302.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V302.FileStatus.FileHash Int (Maybe (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels))
