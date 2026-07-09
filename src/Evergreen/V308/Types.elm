module Evergreen.V308.Types exposing (..)

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
import Evergreen.V308.AiChat
import Evergreen.V308.Audio
import Evergreen.V308.Call
import Evergreen.V308.ChannelDescription
import Evergreen.V308.ChannelName
import Evergreen.V308.Cloudflare
import Evergreen.V308.Coord
import Evergreen.V308.CssPixels
import Evergreen.V308.CustomEmoji
import Evergreen.V308.Discord
import Evergreen.V308.DiscordAttachmentId
import Evergreen.V308.DiscordUserData
import Evergreen.V308.DmChannel
import Evergreen.V308.DmChannelId
import Evergreen.V308.Drawing
import Evergreen.V308.Editable
import Evergreen.V308.EmailAddress
import Evergreen.V308.Embed
import Evergreen.V308.Emoji
import Evergreen.V308.FileStatus
import Evergreen.V308.Game
import Evergreen.V308.Go
import Evergreen.V308.GuildName
import Evergreen.V308.Id
import Evergreen.V308.ImageEditor
import Evergreen.V308.ImageViewer
import Evergreen.V308.LinkedAndOtherDiscordUsers
import Evergreen.V308.Local
import Evergreen.V308.LocalState
import Evergreen.V308.Log
import Evergreen.V308.LoginForm
import Evergreen.V308.MembersAndOwner
import Evergreen.V308.Message
import Evergreen.V308.MessageInput
import Evergreen.V308.MessageView
import Evergreen.V308.MyUi
import Evergreen.V308.NonemptyDict
import Evergreen.V308.NonemptySet
import Evergreen.V308.OneOrGreater
import Evergreen.V308.OneToOne
import Evergreen.V308.Pages.Admin
import Evergreen.V308.Pagination
import Evergreen.V308.PersonName
import Evergreen.V308.Ports
import Evergreen.V308.Postmark
import Evergreen.V308.Range
import Evergreen.V308.RichText
import Evergreen.V308.Route
import Evergreen.V308.Scroll
import Evergreen.V308.SecretId
import Evergreen.V308.SessionIdHash
import Evergreen.V308.Slack
import Evergreen.V308.Sticker
import Evergreen.V308.TextEditor
import Evergreen.V308.ToBackendLog
import Evergreen.V308.Touch
import Evergreen.V308.TwoFactorAuthentication
import Evergreen.V308.Ui.Anim
import Evergreen.V308.Untrusted
import Evergreen.V308.User
import Evergreen.V308.UserAgent
import Evergreen.V308.UserSession
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
    | LoginFormMsg Evergreen.V308.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V308.Pages.Admin.Msg
    | PressedLogOut Evergreen.V308.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V308.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V308.Route.Route
    | SelectedFilesToAttach ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V308.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V308.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V308.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V308.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V308.NonemptyDict.NonemptyDict Int Evergreen.V308.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V308.NonemptyDict.NonemptyDict Int Evergreen.V308.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRoute Evergreen.V308.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V308.NonemptySet.NonemptySet (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V308.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V308.AiChat.Msg
    | GameMsg Evergreen.V308.Game.Msg
    | GoSpectatorMsg Evergreen.V308.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V308.Editable.Msg Evergreen.V308.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V308.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V308.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
        { fileId : Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
        { fileId : Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V308.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage Evergreen.V308.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V308.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V308.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V308.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V308.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.User.NotificationLevel
    | GotStartupData Evergreen.V308.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V308.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId
        , otherUserId : Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRoute Evergreen.V308.MessageInput.Msg
    | MessageInputMsg Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRoute Evergreen.V308.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V308.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V308.Range.Range, Evergreen.V308.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V308.Range.Range, Evergreen.V308.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V308.Call.FromJs)
    | VoiceChatMsg Evergreen.V308.Call.Msg
    | PressedChannelHeaderTab Evergreen.V308.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V308.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V308.Audio.LoadError Evergreen.V308.Audio.Source)


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V308.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V308.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) Evergreen.V308.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.LocalState.DiscordFrontendGuild
    , user : Evergreen.V308.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.User.FrontendUser
    , discordUsers : Evergreen.V308.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V308.SessionIdHash.SessionIdHash Evergreen.V308.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V308.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId) Evergreen.V308.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId) Evergreen.V308.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V308.Call.CallId (Evergreen.V308.NonemptyDict.NonemptyDict ( Evergreen.V308.Id.Id Evergreen.V308.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V308.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V308.Go.PublicGoMatchData Evergreen.V308.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V308.Route.Route
    , windowSize : Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V308.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V308.Audio.LoadError Evergreen.V308.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V308.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V308.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V308.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V308.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V308.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.ChannelName.ChannelName Evergreen.V308.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.ChannelName.ChannelName Evergreen.V308.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.UserSession.ToBeFilledInByBackend (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V308.GuildName.GuildName (Evergreen.V308.UserSession.ToBeFilledInByBackend (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V308.Id.DiscordGuildOrDmId_DmData (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V308.UserSession.SetViewing
    | Local_SetName Evergreen.V308.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V308.Id.GuildOrDmId (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V308.Id.GuildOrDmId (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId) (Evergreen.V308.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V308.Id.DiscordGuildOrDmId (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V308.Id.DiscordGuildOrDmId (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId) (Evergreen.V308.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V308.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V308.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V308.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V308.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V308.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V308.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V308.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V308.NonemptySet.NonemptySet (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V308.Call.LocalChange
    | Local_Game Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Game.LocalChange
    | Local_Drawing Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Drawing.AnchorType Evergreen.V308.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Effect.Time.Posix Evergreen.V308.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V308.RichText.RichText (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))) Evergreen.V308.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId) Evergreen.V308.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V308.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V308.RichText.RichText (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))) Evergreen.V308.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId) Evergreen.V308.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.ChannelName.ChannelName Evergreen.V308.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.ChannelName.ChannelName Evergreen.V308.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V308.LocalState.JoinGuildError
            { guildId : Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId
            , guild : Evergreen.V308.LocalState.FrontendGuild
            , owner : Evergreen.V308.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V308.RichText.RichText (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))) (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V308.RichText.RichText (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V308.Id.DiscordGuildOrDmId_DmData (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V308.RichText.RichText (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V308.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V308.SessionIdHash.SessionIdHash Evergreen.V308.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V308.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V308.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V308.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V308.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Evergreen.V308.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.ChannelName.ChannelName (Evergreen.V308.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
        (Evergreen.V308.NonemptyDict.NonemptyDict
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) Evergreen.V308.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Evergreen.V308.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Maybe (Evergreen.V308.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V308.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V308.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V308.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V308.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V308.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V308.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) (Evergreen.V308.Discord.OptionalData String) (Evergreen.V308.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
        (Evergreen.V308.MembersAndOwner.MembersAndOwner
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Evergreen.V308.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId) Evergreen.V308.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId) Evergreen.V308.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V308.Call.ServerChange
    | Server_Game (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Game.LocalChange
    | Server_Drawing (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Drawing.AnchorType Evergreen.V308.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V308.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V308.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V308.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V308.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V308.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V308.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V308.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V308.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V308.Id.AnyGuildOrDmId Evergreen.V308.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V308.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels) (Maybe Evergreen.V308.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId) (Evergreen.V308.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V308.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V308.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V308.Local.Local LocalMsg Evergreen.V308.LocalState.LocalState
    , admin : Evergreen.V308.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId, Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V308.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V308.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V308.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V308.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ) (Evergreen.V308.NonemptyDict.NonemptyDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V308.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V308.Scroll.ScrollPosition
    , textEditor : Evergreen.V308.TextEditor.Model
    , profilePictureEditor : Evergreen.V308.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId, Evergreen.V308.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V308.Emoji.Model
    , voiceChat : Evergreen.V308.Call.Model
    , games : SeqDict.SeqDict Evergreen.V308.Id.GuildOrDmId Evergreen.V308.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V308.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V308.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V308.Range.Range
                , direction : Evergreen.V308.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V308.NonemptyDict.NonemptyDict Int Evergreen.V308.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V308.NonemptyDict.NonemptyDict Int Evergreen.V308.Touch.Touch
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
    | AdminToFrontend Evergreen.V308.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V308.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V308.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V308.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V308.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V308.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V308.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V308.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V308.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V308.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V308.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V308.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V308.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V308.Audio.LoadError Evergreen.V308.Audio.Source
    , startupData : Evergreen.V308.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V308.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V308.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V308.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V308.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V308.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId, Evergreen.V308.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V308.DmChannelId.DmChannelId, Evergreen.V308.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId, Evergreen.V308.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId, Evergreen.V308.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V308.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V308.NonemptyDict.NonemptyDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V308.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V308.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V308.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V308.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V308.DmChannelId.DmChannelId Evergreen.V308.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) Evergreen.V308.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.Slack.Id Evergreen.V308.Slack.ChannelId) Evergreen.V308.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V308.OneToOne.OneToOne String (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    , slackUsers : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.Slack.Id Evergreen.V308.Slack.UserId) (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
    , slackServers : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.Slack.Id Evergreen.V308.Slack.TeamId) (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    , slackToken : Maybe Evergreen.V308.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V308.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V308.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V308.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V308.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V308.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V308.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V308.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V308.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Evergreen.V308.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId, Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V308.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V308.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V308.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V308.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.LocalState.LoadingDiscordChannel (List Evergreen.V308.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V308.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId) Evergreen.V308.Sticker.StickerData
    , discordStickers : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.Discord.Id Evergreen.V308.Discord.StickerId) (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId) Evergreen.V308.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V308.OneToOne.OneToOne Evergreen.V308.RichText.DiscordCustomEmojiIdAndName (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V308.Postmark.ApiKey
    , serverSecret : Evergreen.V308.SecretId.SecretId Evergreen.V308.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V308.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.GamePublicId) ( Evergreen.V308.DmChannelId.GuildOrFullDmId, Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V308.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V308.DmChannelId.DmChannelId Evergreen.V308.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V308.Id.DiscordGuildOrDmId Evergreen.V308.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V308.Id.Id Evergreen.V308.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V308.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V308.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V308.Untrusted.Untrusted Evergreen.V308.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V308.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V308.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V308.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V308.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V308.PersonName.PersonName Evergreen.V308.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V308.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V308.Slack.OAuthCode Evergreen.V308.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V308.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V308.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V308.Id.Id Evergreen.V308.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V308.EmailAddress.EmailAddress (Result Evergreen.V308.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V308.EmailAddress.EmailAddress (Result Evergreen.V308.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V308.EmailAddress.EmailAddress (Result Evergreen.V308.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V308.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMaybeMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Result Evergreen.V308.Discord.HttpError Evergreen.V308.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V308.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Result Evergreen.V308.Discord.HttpError Evergreen.V308.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) (Result Evergreen.V308.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) (Result Evergreen.V308.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) (Result Evergreen.V308.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) (Result Evergreen.V308.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji (Result Evergreen.V308.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji (Result Evergreen.V308.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji (Result Evergreen.V308.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji (Result Evergreen.V308.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V308.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V308.Discord.HttpError (List ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId, Maybe Evergreen.V308.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Effect.Time.Posix Evergreen.V308.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V308.Slack.CurrentUser
            , team : Evergreen.V308.Slack.Team
            , users : List Evergreen.V308.Slack.User
            , channels : List ( Evergreen.V308.Slack.Channel, List Evergreen.V308.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Result Effect.Http.Error Evergreen.V308.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V308.Local.ChangeId Effect.Time.Posix Evergreen.V308.Call.CallId Evergreen.V308.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V308.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V308.Local.ChangeId Effect.Time.Posix Evergreen.V308.Call.CallId Evergreen.V308.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V308.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V308.Local.ChangeId Evergreen.V308.Call.ConnectionId Evergreen.V308.Cloudflare.RealtimeSessionId (List Evergreen.V308.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V308.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V308.Local.ChangeId Evergreen.V308.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Discord.UserAuth (Result Evergreen.V308.Discord.HttpError Evergreen.V308.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Result Evergreen.V308.Discord.HttpError Evergreen.V308.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
        (Result
            Evergreen.V308.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId
                , members : List (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
                }
            , List
                ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId
                , { guild : Evergreen.V308.Discord.GatewayGuild
                  , channels : List Evergreen.V308.Discord.Channel
                  , icon : Maybe Evergreen.V308.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Bool Evergreen.V308.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V308.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.AttachmentId, Evergreen.V308.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V308.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.AttachmentId, Evergreen.V308.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V308.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V308.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V308.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V308.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) (Result Evergreen.V308.Discord.HttpError (List Evergreen.V308.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Result Evergreen.V308.Discord.HttpError (List Evergreen.V308.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V308.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V308.DmChannelId.DmChannelId Evergreen.V308.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V308.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V308.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V308.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
        (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V308.Discord.HttpError
            { guild : Evergreen.V308.Discord.GatewayGuild
            , channels : List Evergreen.V308.Discord.Channel
            , icon : Maybe Evergreen.V308.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Result Evergreen.V308.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V308.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (List ( Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId, Result Effect.Http.Error Evergreen.V308.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId, Result Effect.Http.Error Evergreen.V308.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (List ( Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V308.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V308.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V308.Discord.HttpError (List Evergreen.V308.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V308.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V308.SecretId.SecretId Evergreen.V308.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V308.FileStatus.FileHash Int (Maybe (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
