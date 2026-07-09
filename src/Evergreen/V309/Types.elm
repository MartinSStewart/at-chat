module Evergreen.V309.Types exposing (..)

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
import Evergreen.V309.AiChat
import Evergreen.V309.Audio
import Evergreen.V309.Call
import Evergreen.V309.ChannelDescription
import Evergreen.V309.ChannelName
import Evergreen.V309.Cloudflare
import Evergreen.V309.Coord
import Evergreen.V309.CssPixels
import Evergreen.V309.CustomEmoji
import Evergreen.V309.Discord
import Evergreen.V309.DiscordAttachmentId
import Evergreen.V309.DiscordUserData
import Evergreen.V309.DmChannel
import Evergreen.V309.DmChannelId
import Evergreen.V309.Drawing
import Evergreen.V309.Editable
import Evergreen.V309.EmailAddress
import Evergreen.V309.Embed
import Evergreen.V309.Emoji
import Evergreen.V309.FileStatus
import Evergreen.V309.Game
import Evergreen.V309.Go
import Evergreen.V309.GuildName
import Evergreen.V309.Id
import Evergreen.V309.ImageEditor
import Evergreen.V309.ImageViewer
import Evergreen.V309.LinkedAndOtherDiscordUsers
import Evergreen.V309.Local
import Evergreen.V309.LocalState
import Evergreen.V309.Log
import Evergreen.V309.LoginForm
import Evergreen.V309.MembersAndOwner
import Evergreen.V309.Message
import Evergreen.V309.MessageInput
import Evergreen.V309.MessageView
import Evergreen.V309.MyUi
import Evergreen.V309.NonemptyDict
import Evergreen.V309.NonemptySet
import Evergreen.V309.OneOrGreater
import Evergreen.V309.OneToOne
import Evergreen.V309.Pages.Admin
import Evergreen.V309.Pagination
import Evergreen.V309.PersonName
import Evergreen.V309.Ports
import Evergreen.V309.Postmark
import Evergreen.V309.Range
import Evergreen.V309.RichText
import Evergreen.V309.Route
import Evergreen.V309.Scroll
import Evergreen.V309.SecretId
import Evergreen.V309.SessionIdHash
import Evergreen.V309.Slack
import Evergreen.V309.Sticker
import Evergreen.V309.TextEditor
import Evergreen.V309.ToBackendLog
import Evergreen.V309.Touch
import Evergreen.V309.TwoFactorAuthentication
import Evergreen.V309.Ui.Anim
import Evergreen.V309.Untrusted
import Evergreen.V309.User
import Evergreen.V309.UserAgent
import Evergreen.V309.UserSession
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
    | LoginFormMsg Evergreen.V309.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V309.Pages.Admin.Msg
    | PressedLogOut Evergreen.V309.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V309.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V309.Route.Route
    | SelectedFilesToAttach ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V309.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V309.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V309.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V309.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V309.NonemptyDict.NonemptyDict Int Evergreen.V309.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V309.NonemptyDict.NonemptyDict Int Evergreen.V309.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRoute Evergreen.V309.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V309.NonemptySet.NonemptySet (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V309.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V309.AiChat.Msg
    | GameMsg Evergreen.V309.Game.Msg
    | GoSpectatorMsg Evergreen.V309.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V309.Editable.Msg Evergreen.V309.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V309.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V309.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
        { fileId : Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
        { fileId : Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V309.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage Evergreen.V309.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V309.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V309.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V309.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V309.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.User.NotificationLevel
    | GotStartupData Evergreen.V309.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V309.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId
        , otherUserId : Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRoute Evergreen.V309.MessageInput.Msg
    | MessageInputMsg Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRoute Evergreen.V309.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V309.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V309.Range.Range, Evergreen.V309.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V309.Range.Range, Evergreen.V309.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V309.Call.FromJs)
    | VoiceChatMsg Evergreen.V309.Call.Msg
    | PressedChannelHeaderTab Evergreen.V309.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V309.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V309.Audio.LoadError Evergreen.V309.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V309.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V309.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) Evergreen.V309.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.LocalState.DiscordFrontendGuild
    , user : Evergreen.V309.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.User.FrontendUser
    , discordUsers : Evergreen.V309.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V309.SessionIdHash.SessionIdHash Evergreen.V309.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V309.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId) Evergreen.V309.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId) Evergreen.V309.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V309.Call.CallId (Evergreen.V309.NonemptyDict.NonemptyDict ( Evergreen.V309.Id.Id Evergreen.V309.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V309.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V309.Go.PublicGoMatchData Evergreen.V309.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V309.Route.Route
    , windowSize : Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V309.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V309.Audio.LoadError Evergreen.V309.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V309.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V309.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V309.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V309.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V309.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.ChannelName.ChannelName Evergreen.V309.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.ChannelName.ChannelName Evergreen.V309.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.UserSession.ToBeFilledInByBackend (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V309.GuildName.GuildName (Evergreen.V309.UserSession.ToBeFilledInByBackend (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V309.Id.DiscordGuildOrDmId_DmData (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V309.UserSession.SetViewing
    | Local_SetName Evergreen.V309.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V309.Id.GuildOrDmId (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V309.Id.GuildOrDmId (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId) (Evergreen.V309.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V309.Id.DiscordGuildOrDmId (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V309.Id.DiscordGuildOrDmId (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId) (Evergreen.V309.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V309.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V309.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V309.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V309.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V309.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V309.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V309.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V309.NonemptySet.NonemptySet (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V309.Call.LocalChange
    | Local_Game Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Game.LocalChange
    | Local_Drawing Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Drawing.AnchorType Evergreen.V309.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Effect.Time.Posix Evergreen.V309.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V309.RichText.RichText (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))) Evergreen.V309.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId) Evergreen.V309.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V309.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V309.RichText.RichText (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))) Evergreen.V309.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId) Evergreen.V309.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.ChannelName.ChannelName Evergreen.V309.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.ChannelName.ChannelName Evergreen.V309.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V309.LocalState.JoinGuildError
            { guildId : Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId
            , guild : Evergreen.V309.LocalState.FrontendGuild
            , owner : Evergreen.V309.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V309.RichText.RichText (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))) (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V309.RichText.RichText (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V309.Id.DiscordGuildOrDmId_DmData (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V309.RichText.RichText (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V309.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V309.SessionIdHash.SessionIdHash Evergreen.V309.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V309.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V309.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V309.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V309.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Evergreen.V309.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.ChannelName.ChannelName (Evergreen.V309.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
        (Evergreen.V309.NonemptyDict.NonemptyDict
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) Evergreen.V309.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Evergreen.V309.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Maybe (Evergreen.V309.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V309.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V309.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V309.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V309.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V309.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V309.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) (Evergreen.V309.Discord.OptionalData String) (Evergreen.V309.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
        (Evergreen.V309.MembersAndOwner.MembersAndOwner
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Evergreen.V309.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId) Evergreen.V309.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId) Evergreen.V309.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V309.Call.ServerChange
    | Server_Game (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Game.LocalChange
    | Server_Drawing (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Drawing.AnchorType Evergreen.V309.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V309.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V309.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V309.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V309.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V309.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V309.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V309.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V309.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V309.Id.AnyGuildOrDmId Evergreen.V309.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V309.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels) (Maybe Evergreen.V309.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId) (Evergreen.V309.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V309.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V309.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V309.Local.Local LocalMsg Evergreen.V309.LocalState.LocalState
    , admin : Evergreen.V309.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId, Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V309.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V309.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V309.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V309.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ) (Evergreen.V309.NonemptyDict.NonemptyDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V309.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V309.Scroll.ScrollPosition
    , textEditor : Evergreen.V309.TextEditor.Model
    , profilePictureEditor : Evergreen.V309.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId, Evergreen.V309.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V309.Emoji.Model
    , voiceChat : Evergreen.V309.Call.Model
    , games : SeqDict.SeqDict Evergreen.V309.Id.GuildOrDmId Evergreen.V309.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V309.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V309.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V309.Range.Range
                , direction : Evergreen.V309.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V309.NonemptyDict.NonemptyDict Int Evergreen.V309.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V309.NonemptyDict.NonemptyDict Int Evergreen.V309.Touch.Touch
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
    | AdminToFrontend Evergreen.V309.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V309.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V309.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V309.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V309.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V309.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V309.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V309.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V309.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V309.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V309.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V309.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V309.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V309.Audio.LoadError Evergreen.V309.Audio.Source
    , startupData : Evergreen.V309.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V309.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V309.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V309.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V309.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V309.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId, Evergreen.V309.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V309.DmChannelId.DmChannelId, Evergreen.V309.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId, Evergreen.V309.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId, Evergreen.V309.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V309.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V309.NonemptyDict.NonemptyDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V309.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V309.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V309.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V309.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V309.DmChannelId.DmChannelId Evergreen.V309.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) Evergreen.V309.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.Slack.Id Evergreen.V309.Slack.ChannelId) Evergreen.V309.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V309.OneToOne.OneToOne String (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    , slackUsers : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.Slack.Id Evergreen.V309.Slack.UserId) (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
    , slackServers : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.Slack.Id Evergreen.V309.Slack.TeamId) (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    , slackToken : Maybe Evergreen.V309.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V309.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V309.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V309.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V309.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V309.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V309.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V309.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V309.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Evergreen.V309.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId, Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V309.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V309.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V309.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V309.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.LocalState.LoadingDiscordChannel (List Evergreen.V309.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V309.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId) Evergreen.V309.Sticker.StickerData
    , discordStickers : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.Discord.Id Evergreen.V309.Discord.StickerId) (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId) Evergreen.V309.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V309.OneToOne.OneToOne Evergreen.V309.RichText.DiscordCustomEmojiIdAndName (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V309.Postmark.ApiKey
    , serverSecret : Evergreen.V309.SecretId.SecretId Evergreen.V309.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V309.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.GamePublicId) ( Evergreen.V309.DmChannelId.GuildOrFullDmId, Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V309.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V309.DmChannelId.DmChannelId Evergreen.V309.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V309.Id.DiscordGuildOrDmId Evergreen.V309.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V309.Id.Id Evergreen.V309.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V309.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V309.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V309.Untrusted.Untrusted Evergreen.V309.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V309.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V309.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V309.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V309.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V309.PersonName.PersonName Evergreen.V309.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V309.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V309.Slack.OAuthCode Evergreen.V309.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V309.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V309.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V309.Id.Id Evergreen.V309.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V309.EmailAddress.EmailAddress (Result Evergreen.V309.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V309.EmailAddress.EmailAddress (Result Evergreen.V309.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V309.EmailAddress.EmailAddress (Result Evergreen.V309.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V309.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMaybeMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Result Evergreen.V309.Discord.HttpError Evergreen.V309.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V309.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Result Evergreen.V309.Discord.HttpError Evergreen.V309.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) (Result Evergreen.V309.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) (Result Evergreen.V309.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) (Result Evergreen.V309.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) (Result Evergreen.V309.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji (Result Evergreen.V309.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji (Result Evergreen.V309.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji (Result Evergreen.V309.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji (Result Evergreen.V309.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V309.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V309.Discord.HttpError (List ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId, Maybe Evergreen.V309.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Effect.Time.Posix Evergreen.V309.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V309.Slack.CurrentUser
            , team : Evergreen.V309.Slack.Team
            , users : List Evergreen.V309.Slack.User
            , channels : List ( Evergreen.V309.Slack.Channel, List Evergreen.V309.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Result Effect.Http.Error Evergreen.V309.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V309.Local.ChangeId Effect.Time.Posix Evergreen.V309.Call.CallId Evergreen.V309.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V309.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V309.Local.ChangeId Effect.Time.Posix Evergreen.V309.Call.CallId Evergreen.V309.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V309.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V309.Local.ChangeId Evergreen.V309.Call.ConnectionId Evergreen.V309.Cloudflare.RealtimeSessionId (List Evergreen.V309.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V309.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V309.Local.ChangeId Evergreen.V309.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Discord.UserAuth (Result Evergreen.V309.Discord.HttpError Evergreen.V309.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Result Evergreen.V309.Discord.HttpError Evergreen.V309.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
        (Result
            Evergreen.V309.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId
                , members : List (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
                }
            , List
                ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId
                , { guild : Evergreen.V309.Discord.GatewayGuild
                  , channels : List Evergreen.V309.Discord.Channel
                  , icon : Maybe Evergreen.V309.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Bool Evergreen.V309.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V309.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.AttachmentId, Evergreen.V309.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V309.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.AttachmentId, Evergreen.V309.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V309.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V309.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V309.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V309.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) (Result Evergreen.V309.Discord.HttpError (List Evergreen.V309.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Result Evergreen.V309.Discord.HttpError (List Evergreen.V309.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V309.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V309.DmChannelId.DmChannelId Evergreen.V309.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V309.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V309.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V309.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
        (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V309.Discord.HttpError
            { guild : Evergreen.V309.Discord.GatewayGuild
            , channels : List Evergreen.V309.Discord.Channel
            , icon : Maybe Evergreen.V309.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Result Evergreen.V309.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V309.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (List ( Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId, Result Effect.Http.Error Evergreen.V309.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId, Result Effect.Http.Error Evergreen.V309.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (List ( Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V309.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V309.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V309.Discord.HttpError (List Evergreen.V309.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V309.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V309.SecretId.SecretId Evergreen.V309.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V309.FileStatus.FileHash Int (Maybe (Evergreen.V309.Coord.Coord Evergreen.V309.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
