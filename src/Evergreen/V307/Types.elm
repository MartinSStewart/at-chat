module Evergreen.V307.Types exposing (..)

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
import Evergreen.V307.AiChat
import Evergreen.V307.Audio
import Evergreen.V307.Call
import Evergreen.V307.ChannelDescription
import Evergreen.V307.ChannelName
import Evergreen.V307.Cloudflare
import Evergreen.V307.Coord
import Evergreen.V307.CssPixels
import Evergreen.V307.CustomEmoji
import Evergreen.V307.Discord
import Evergreen.V307.DiscordAttachmentId
import Evergreen.V307.DiscordUserData
import Evergreen.V307.DmChannel
import Evergreen.V307.DmChannelId
import Evergreen.V307.Drawing
import Evergreen.V307.Editable
import Evergreen.V307.EmailAddress
import Evergreen.V307.Embed
import Evergreen.V307.Emoji
import Evergreen.V307.FileStatus
import Evergreen.V307.Game
import Evergreen.V307.Go
import Evergreen.V307.GuildName
import Evergreen.V307.Id
import Evergreen.V307.ImageEditor
import Evergreen.V307.ImageViewer
import Evergreen.V307.LinkedAndOtherDiscordUsers
import Evergreen.V307.Local
import Evergreen.V307.LocalState
import Evergreen.V307.Log
import Evergreen.V307.LoginForm
import Evergreen.V307.MembersAndOwner
import Evergreen.V307.Message
import Evergreen.V307.MessageInput
import Evergreen.V307.MessageView
import Evergreen.V307.MyUi
import Evergreen.V307.NonemptyDict
import Evergreen.V307.NonemptySet
import Evergreen.V307.OneOrGreater
import Evergreen.V307.OneToOne
import Evergreen.V307.Pages.Admin
import Evergreen.V307.Pagination
import Evergreen.V307.PersonName
import Evergreen.V307.Ports
import Evergreen.V307.Postmark
import Evergreen.V307.Range
import Evergreen.V307.RichText
import Evergreen.V307.Route
import Evergreen.V307.Scroll
import Evergreen.V307.SecretId
import Evergreen.V307.SessionIdHash
import Evergreen.V307.Slack
import Evergreen.V307.Sticker
import Evergreen.V307.TextEditor
import Evergreen.V307.ToBackendLog
import Evergreen.V307.Touch
import Evergreen.V307.TwoFactorAuthentication
import Evergreen.V307.Ui.Anim
import Evergreen.V307.Untrusted
import Evergreen.V307.User
import Evergreen.V307.UserAgent
import Evergreen.V307.UserSession
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
    | LoginFormMsg Evergreen.V307.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V307.Pages.Admin.Msg
    | PressedLogOut Evergreen.V307.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V307.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V307.Route.Route
    | SelectedFilesToAttach ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V307.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V307.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V307.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V307.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V307.NonemptyDict.NonemptyDict Int Evergreen.V307.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V307.NonemptyDict.NonemptyDict Int Evergreen.V307.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRoute Evergreen.V307.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V307.NonemptySet.NonemptySet (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V307.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V307.AiChat.Msg
    | GameMsg Evergreen.V307.Game.Msg
    | GoSpectatorMsg Evergreen.V307.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V307.Editable.Msg Evergreen.V307.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V307.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V307.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
        { fileId : Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
        { fileId : Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V307.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage Evergreen.V307.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V307.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V307.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V307.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V307.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.User.NotificationLevel
    | GotStartupData Evergreen.V307.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V307.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId
        , otherUserId : Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRoute Evergreen.V307.MessageInput.Msg
    | MessageInputMsg Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRoute Evergreen.V307.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V307.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V307.Range.Range, Evergreen.V307.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V307.Range.Range, Evergreen.V307.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V307.Call.FromJs)
    | VoiceChatMsg Evergreen.V307.Call.Msg
    | PressedChannelHeaderTab Evergreen.V307.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V307.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V307.Audio.LoadError Evergreen.V307.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V307.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V307.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) Evergreen.V307.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.LocalState.DiscordFrontendGuild
    , user : Evergreen.V307.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.User.FrontendUser
    , discordUsers : Evergreen.V307.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V307.SessionIdHash.SessionIdHash Evergreen.V307.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V307.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId) Evergreen.V307.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId) Evergreen.V307.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V307.Call.CallId (Evergreen.V307.NonemptyDict.NonemptyDict ( Evergreen.V307.Id.Id Evergreen.V307.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V307.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V307.Go.PublicGoMatchData Evergreen.V307.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V307.Route.Route
    , windowSize : Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V307.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V307.Audio.LoadError Evergreen.V307.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V307.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V307.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V307.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V307.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V307.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.ChannelName.ChannelName Evergreen.V307.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.ChannelName.ChannelName Evergreen.V307.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.UserSession.ToBeFilledInByBackend (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V307.GuildName.GuildName (Evergreen.V307.UserSession.ToBeFilledInByBackend (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V307.Id.DiscordGuildOrDmId_DmData (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V307.UserSession.SetViewing
    | Local_SetName Evergreen.V307.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V307.Id.GuildOrDmId (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V307.Id.GuildOrDmId (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId) (Evergreen.V307.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V307.Id.DiscordGuildOrDmId (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V307.Id.DiscordGuildOrDmId (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId) (Evergreen.V307.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V307.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V307.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V307.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V307.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V307.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V307.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V307.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V307.NonemptySet.NonemptySet (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V307.Call.LocalChange
    | Local_Game Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Game.LocalChange
    | Local_Drawing Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Drawing.AnchorType Evergreen.V307.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Effect.Time.Posix Evergreen.V307.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V307.RichText.RichText (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))) Evergreen.V307.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId) Evergreen.V307.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V307.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V307.RichText.RichText (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))) Evergreen.V307.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId) Evergreen.V307.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.ChannelName.ChannelName Evergreen.V307.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.ChannelName.ChannelName Evergreen.V307.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V307.LocalState.JoinGuildError
            { guildId : Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId
            , guild : Evergreen.V307.LocalState.FrontendGuild
            , owner : Evergreen.V307.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V307.RichText.RichText (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))) (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V307.RichText.RichText (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V307.Id.DiscordGuildOrDmId_DmData (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V307.RichText.RichText (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V307.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V307.SessionIdHash.SessionIdHash Evergreen.V307.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V307.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V307.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V307.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V307.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Evergreen.V307.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.ChannelName.ChannelName (Evergreen.V307.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
        (Evergreen.V307.NonemptyDict.NonemptyDict
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) Evergreen.V307.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Evergreen.V307.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Maybe (Evergreen.V307.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V307.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V307.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V307.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V307.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V307.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V307.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) (Evergreen.V307.Discord.OptionalData String) (Evergreen.V307.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
        (Evergreen.V307.MembersAndOwner.MembersAndOwner
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Evergreen.V307.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId) Evergreen.V307.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId) Evergreen.V307.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V307.Call.ServerChange
    | Server_Game (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Game.LocalChange
    | Server_Drawing (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Drawing.AnchorType Evergreen.V307.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V307.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V307.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V307.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V307.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V307.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V307.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V307.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V307.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V307.Id.AnyGuildOrDmId Evergreen.V307.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V307.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels) (Maybe Evergreen.V307.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId) (Evergreen.V307.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V307.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V307.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V307.Local.Local LocalMsg Evergreen.V307.LocalState.LocalState
    , admin : Evergreen.V307.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId, Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V307.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V307.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V307.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V307.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ) (Evergreen.V307.NonemptyDict.NonemptyDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V307.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V307.Scroll.ScrollPosition
    , textEditor : Evergreen.V307.TextEditor.Model
    , profilePictureEditor : Evergreen.V307.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId, Evergreen.V307.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V307.Emoji.Model
    , voiceChat : Evergreen.V307.Call.Model
    , games : SeqDict.SeqDict Evergreen.V307.Id.GuildOrDmId Evergreen.V307.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V307.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V307.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V307.Range.Range
                , direction : Evergreen.V307.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V307.NonemptyDict.NonemptyDict Int Evergreen.V307.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V307.NonemptyDict.NonemptyDict Int Evergreen.V307.Touch.Touch
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
    | AdminToFrontend Evergreen.V307.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V307.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V307.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V307.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V307.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V307.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V307.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V307.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V307.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V307.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V307.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V307.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V307.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V307.Audio.LoadError Evergreen.V307.Audio.Source
    , startupData : Evergreen.V307.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V307.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V307.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V307.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V307.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V307.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId, Evergreen.V307.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V307.DmChannelId.DmChannelId, Evergreen.V307.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId, Evergreen.V307.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId, Evergreen.V307.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V307.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V307.NonemptyDict.NonemptyDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V307.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V307.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V307.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V307.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V307.DmChannelId.DmChannelId Evergreen.V307.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) Evergreen.V307.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.Slack.Id Evergreen.V307.Slack.ChannelId) Evergreen.V307.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V307.OneToOne.OneToOne String (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    , slackUsers : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.Slack.Id Evergreen.V307.Slack.UserId) (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    , slackServers : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.Slack.Id Evergreen.V307.Slack.TeamId) (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    , slackToken : Maybe Evergreen.V307.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V307.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V307.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V307.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V307.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V307.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V307.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V307.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V307.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Evergreen.V307.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId, Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V307.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V307.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V307.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V307.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.LocalState.LoadingDiscordChannel (List Evergreen.V307.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V307.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId) Evergreen.V307.Sticker.StickerData
    , discordStickers : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.Discord.Id Evergreen.V307.Discord.StickerId) (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId) Evergreen.V307.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V307.OneToOne.OneToOne Evergreen.V307.RichText.DiscordCustomEmojiIdAndName (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V307.Postmark.ApiKey
    , serverSecret : Evergreen.V307.SecretId.SecretId Evergreen.V307.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V307.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.GamePublicId) ( Evergreen.V307.DmChannelId.GuildOrFullDmId, Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V307.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V307.DmChannelId.DmChannelId Evergreen.V307.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V307.Id.DiscordGuildOrDmId Evergreen.V307.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V307.Id.Id Evergreen.V307.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V307.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V307.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V307.Untrusted.Untrusted Evergreen.V307.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V307.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V307.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V307.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V307.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V307.PersonName.PersonName Evergreen.V307.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V307.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V307.Slack.OAuthCode Evergreen.V307.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V307.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V307.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V307.Id.Id Evergreen.V307.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V307.EmailAddress.EmailAddress (Result Evergreen.V307.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V307.EmailAddress.EmailAddress (Result Evergreen.V307.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V307.EmailAddress.EmailAddress (Result Evergreen.V307.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V307.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMaybeMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Result Evergreen.V307.Discord.HttpError Evergreen.V307.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V307.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Result Evergreen.V307.Discord.HttpError Evergreen.V307.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) (Result Evergreen.V307.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) (Result Evergreen.V307.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) (Result Evergreen.V307.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) (Result Evergreen.V307.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji (Result Evergreen.V307.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji (Result Evergreen.V307.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji (Result Evergreen.V307.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji (Result Evergreen.V307.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V307.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V307.Discord.HttpError (List ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId, Maybe Evergreen.V307.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Effect.Time.Posix Evergreen.V307.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V307.Slack.CurrentUser
            , team : Evergreen.V307.Slack.Team
            , users : List Evergreen.V307.Slack.User
            , channels : List ( Evergreen.V307.Slack.Channel, List Evergreen.V307.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Result Effect.Http.Error Evergreen.V307.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V307.Local.ChangeId Effect.Time.Posix Evergreen.V307.Call.CallId Evergreen.V307.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V307.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V307.Local.ChangeId Effect.Time.Posix Evergreen.V307.Call.CallId Evergreen.V307.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V307.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V307.Local.ChangeId Evergreen.V307.Call.ConnectionId Evergreen.V307.Cloudflare.RealtimeSessionId (List Evergreen.V307.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V307.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V307.Local.ChangeId Evergreen.V307.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Discord.UserAuth (Result Evergreen.V307.Discord.HttpError Evergreen.V307.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Result Evergreen.V307.Discord.HttpError Evergreen.V307.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
        (Result
            Evergreen.V307.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId
                , members : List (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
                }
            , List
                ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId
                , { guild : Evergreen.V307.Discord.GatewayGuild
                  , channels : List Evergreen.V307.Discord.Channel
                  , icon : Maybe Evergreen.V307.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Bool Evergreen.V307.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V307.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.AttachmentId, Evergreen.V307.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V307.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.AttachmentId, Evergreen.V307.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V307.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V307.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V307.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V307.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) (Result Evergreen.V307.Discord.HttpError (List Evergreen.V307.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Result Evergreen.V307.Discord.HttpError (List Evergreen.V307.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V307.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V307.DmChannelId.DmChannelId Evergreen.V307.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V307.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V307.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V307.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
        (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V307.Discord.HttpError
            { guild : Evergreen.V307.Discord.GatewayGuild
            , channels : List Evergreen.V307.Discord.Channel
            , icon : Maybe Evergreen.V307.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Result Evergreen.V307.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V307.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (List ( Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId, Result Effect.Http.Error Evergreen.V307.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId, Result Effect.Http.Error Evergreen.V307.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (List ( Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V307.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V307.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V307.Discord.HttpError (List Evergreen.V307.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V307.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V307.SecretId.SecretId Evergreen.V307.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V307.FileStatus.FileHash Int (Maybe (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
