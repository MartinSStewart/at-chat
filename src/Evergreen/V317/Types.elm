module Evergreen.V317.Types exposing (..)

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
import Evergreen.V317.AiChat
import Evergreen.V317.Audio
import Evergreen.V317.Call
import Evergreen.V317.ChannelDescription
import Evergreen.V317.ChannelName
import Evergreen.V317.Cloudflare
import Evergreen.V317.Coord
import Evergreen.V317.CssPixels
import Evergreen.V317.CustomEmoji
import Evergreen.V317.Discord
import Evergreen.V317.DiscordAttachmentId
import Evergreen.V317.DiscordUserData
import Evergreen.V317.DmChannel
import Evergreen.V317.DmChannelId
import Evergreen.V317.Drawing
import Evergreen.V317.Editable
import Evergreen.V317.EmailAddress
import Evergreen.V317.Embed
import Evergreen.V317.Emoji
import Evergreen.V317.FileStatus
import Evergreen.V317.Game
import Evergreen.V317.Go
import Evergreen.V317.GuildName
import Evergreen.V317.Id
import Evergreen.V317.ImageEditor
import Evergreen.V317.ImageViewer
import Evergreen.V317.LinkedAndOtherDiscordUsers
import Evergreen.V317.Local
import Evergreen.V317.LocalState
import Evergreen.V317.Log
import Evergreen.V317.LoginForm
import Evergreen.V317.MembersAndOwner
import Evergreen.V317.Message
import Evergreen.V317.MessageInput
import Evergreen.V317.MessageView
import Evergreen.V317.MyUi
import Evergreen.V317.NonemptyDict
import Evergreen.V317.NonemptySet
import Evergreen.V317.OneOrGreater
import Evergreen.V317.OneToOne
import Evergreen.V317.Pages.Admin
import Evergreen.V317.Pagination
import Evergreen.V317.PersonName
import Evergreen.V317.Ports
import Evergreen.V317.Postmark
import Evergreen.V317.Range
import Evergreen.V317.RichText
import Evergreen.V317.Route
import Evergreen.V317.Scroll
import Evergreen.V317.SecretId
import Evergreen.V317.SessionIdHash
import Evergreen.V317.Slack
import Evergreen.V317.Sticker
import Evergreen.V317.TextEditor
import Evergreen.V317.ToBackendLog
import Evergreen.V317.Touch
import Evergreen.V317.TwoFactorAuthentication
import Evergreen.V317.Ui.Anim
import Evergreen.V317.Untrusted
import Evergreen.V317.User
import Evergreen.V317.UserAgent
import Evergreen.V317.UserSession
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
    | LoginFormMsg Evergreen.V317.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V317.Pages.Admin.Msg
    | PressedLogOut Evergreen.V317.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V317.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V317.Route.Route
    | SelectedFilesToAttach ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V317.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V317.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V317.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V317.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V317.NonemptyDict.NonemptyDict Int Evergreen.V317.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V317.NonemptyDict.NonemptyDict Int Evergreen.V317.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRoute Evergreen.V317.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V317.NonemptySet.NonemptySet (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V317.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V317.AiChat.Msg
    | GameMsg Evergreen.V317.Game.Msg
    | GoSpectatorMsg Evergreen.V317.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V317.Editable.Msg Evergreen.V317.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V317.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V317.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
        { fileId : Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
        { fileId : Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V317.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage Evergreen.V317.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V317.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V317.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V317.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V317.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.User.NotificationLevel
    | GotStartupData Evergreen.V317.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V317.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId
        , otherUserId : Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRoute Evergreen.V317.MessageInput.Msg
    | MessageInputMsg Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRoute Evergreen.V317.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V317.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V317.Range.Range, Evergreen.V317.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V317.Range.Range, Evergreen.V317.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V317.Call.FromJs)
    | VoiceChatMsg Evergreen.V317.Call.Msg
    | PressedChannelHeaderTab Evergreen.V317.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V317.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V317.Audio.LoadError Evergreen.V317.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V317.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V317.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) Evergreen.V317.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.LocalState.DiscordFrontendGuild
    , user : Evergreen.V317.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.User.FrontendUser
    , discordUsers : Evergreen.V317.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V317.SessionIdHash.SessionIdHash Evergreen.V317.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V317.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId) Evergreen.V317.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId) Evergreen.V317.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V317.Call.CallId (Evergreen.V317.NonemptyDict.NonemptyDict ( Evergreen.V317.Id.Id Evergreen.V317.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V317.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V317.Go.PublicGoMatchData Evergreen.V317.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V317.Route.Route
    , windowSize : Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V317.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V317.Audio.LoadError Evergreen.V317.Audio.Source
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V317.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V317.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V317.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V317.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V317.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.ChannelName.ChannelName Evergreen.V317.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.ChannelName.ChannelName Evergreen.V317.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.UserSession.ToBeFilledInByBackend (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V317.GuildName.GuildName (Evergreen.V317.UserSession.ToBeFilledInByBackend (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V317.Id.DiscordGuildOrDmId_DmData (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V317.UserSession.SetViewing
    | Local_SetName Evergreen.V317.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V317.Id.GuildOrDmId (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V317.Id.GuildOrDmId (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId) (Evergreen.V317.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V317.Id.DiscordGuildOrDmId (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V317.Id.DiscordGuildOrDmId (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId) (Evergreen.V317.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V317.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V317.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V317.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V317.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V317.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V317.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V317.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V317.NonemptySet.NonemptySet (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V317.Call.LocalChange
    | Local_Game Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Game.LocalChange
    | Local_Drawing Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Drawing.AnchorType Evergreen.V317.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Effect.Time.Posix Evergreen.V317.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V317.RichText.RichText (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))) Evergreen.V317.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId) Evergreen.V317.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V317.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V317.RichText.RichText (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))) Evergreen.V317.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId) Evergreen.V317.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.ChannelName.ChannelName Evergreen.V317.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.ChannelName.ChannelName Evergreen.V317.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V317.LocalState.JoinGuildError
            { guildId : Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId
            , guild : Evergreen.V317.LocalState.FrontendGuild
            , owner : Evergreen.V317.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V317.RichText.RichText (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))) (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V317.RichText.RichText (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V317.Id.DiscordGuildOrDmId_DmData (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V317.RichText.RichText (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V317.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V317.SessionIdHash.SessionIdHash Evergreen.V317.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V317.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V317.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V317.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V317.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Evergreen.V317.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.ChannelName.ChannelName (Evergreen.V317.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
        (Evergreen.V317.NonemptyDict.NonemptyDict
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) Evergreen.V317.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Evergreen.V317.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Maybe (Evergreen.V317.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V317.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V317.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V317.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V317.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V317.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V317.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) (Evergreen.V317.Discord.OptionalData String) (Evergreen.V317.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
        (Evergreen.V317.MembersAndOwner.MembersAndOwner
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Evergreen.V317.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId) Evergreen.V317.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId) Evergreen.V317.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V317.Call.ServerChange
    | Server_Game (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Game.LocalChange
    | Server_Drawing (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Drawing.AnchorType Evergreen.V317.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V317.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V317.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V317.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V317.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V317.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V317.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V317.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V317.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V317.Id.AnyGuildOrDmId Evergreen.V317.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V317.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels) (Maybe Evergreen.V317.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId) (Evergreen.V317.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V317.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V317.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V317.Local.Local LocalMsg Evergreen.V317.LocalState.LocalState
    , admin : Evergreen.V317.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId, Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V317.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V317.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V317.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V317.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ) (Evergreen.V317.NonemptyDict.NonemptyDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V317.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V317.Scroll.ScrollPosition
    , textEditor : Evergreen.V317.TextEditor.Model
    , profilePictureEditor : Evergreen.V317.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId, Evergreen.V317.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V317.Emoji.Model
    , voiceChat : Evergreen.V317.Call.Model
    , games : SeqDict.SeqDict Evergreen.V317.Id.GuildOrDmId Evergreen.V317.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V317.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
    , friendsSearch : String
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V317.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V317.Range.Range
                , direction : Evergreen.V317.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V317.NonemptyDict.NonemptyDict Int Evergreen.V317.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V317.NonemptyDict.NonemptyDict Int Evergreen.V317.Touch.Touch
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
    | AdminToFrontend Evergreen.V317.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V317.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V317.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V317.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V317.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V317.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V317.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V317.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V317.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V317.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V317.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V317.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V317.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V317.Audio.LoadError Evergreen.V317.Audio.Source
    , startupData : Evergreen.V317.Ports.StartupData
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V317.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V317.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V317.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V317.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V317.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId, Evergreen.V317.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V317.DmChannelId.DmChannelId, Evergreen.V317.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId, Evergreen.V317.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId, Evergreen.V317.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V317.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type WordSpellingGameSwedish
    = WordSpellingGameSwedish_NotLoaded
    | WordSpellingGameSwedish_Loading
    | WordSpellingGameSwedish_Error Effect.Http.Error
    | WordSpellingGameSwedish_Loaded (Set.Set String)


type alias BackendModel =
    { users : Evergreen.V317.NonemptyDict.NonemptyDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V317.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V317.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V317.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V317.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V317.DmChannelId.DmChannelId Evergreen.V317.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) Evergreen.V317.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.Slack.Id Evergreen.V317.Slack.ChannelId) Evergreen.V317.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V317.OneToOne.OneToOne String (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    , slackUsers : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.Slack.Id Evergreen.V317.Slack.UserId) (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
    , slackServers : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.Slack.Id Evergreen.V317.Slack.TeamId) (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    , slackToken : Maybe Evergreen.V317.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V317.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V317.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V317.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V317.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V317.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V317.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V317.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V317.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Evergreen.V317.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId, Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V317.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V317.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V317.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V317.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.LocalState.LoadingDiscordChannel (List Evergreen.V317.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V317.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId) Evergreen.V317.Sticker.StickerData
    , discordStickers : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.Discord.Id Evergreen.V317.Discord.StickerId) (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId) Evergreen.V317.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V317.OneToOne.OneToOne Evergreen.V317.RichText.DiscordCustomEmojiIdAndName (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V317.Postmark.ApiKey
    , serverSecret : Evergreen.V317.SecretId.SecretId Evergreen.V317.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V317.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.GamePublicId) ( Evergreen.V317.DmChannelId.GuildOrFullDmId, Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId )
    , wordSpellingGameSwedish : WordSpellingGameSwedish
    }


type alias FrontendMsg =
    Evergreen.V317.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V317.DmChannelId.DmChannelId Evergreen.V317.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V317.Id.DiscordGuildOrDmId Evergreen.V317.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V317.Id.Id Evergreen.V317.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V317.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V317.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V317.Untrusted.Untrusted Evergreen.V317.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V317.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V317.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V317.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V317.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V317.PersonName.PersonName Evergreen.V317.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V317.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V317.Slack.OAuthCode Evergreen.V317.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V317.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V317.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V317.Id.Id Evergreen.V317.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V317.EmailAddress.EmailAddress (Result Evergreen.V317.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V317.EmailAddress.EmailAddress (Result Evergreen.V317.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V317.EmailAddress.EmailAddress (Result Evergreen.V317.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V317.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMaybeMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Result Evergreen.V317.Discord.HttpError Evergreen.V317.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V317.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Result Evergreen.V317.Discord.HttpError Evergreen.V317.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) (Result Evergreen.V317.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) (Result Evergreen.V317.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) (Result Evergreen.V317.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) (Result Evergreen.V317.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji (Result Evergreen.V317.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji (Result Evergreen.V317.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji (Result Evergreen.V317.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji (Result Evergreen.V317.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V317.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V317.Discord.HttpError (List ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId, Maybe Evergreen.V317.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Effect.Time.Posix Evergreen.V317.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V317.Slack.CurrentUser
            , team : Evergreen.V317.Slack.Team
            , users : List Evergreen.V317.Slack.User
            , channels : List ( Evergreen.V317.Slack.Channel, List Evergreen.V317.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Result Effect.Http.Error Evergreen.V317.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V317.Local.ChangeId Effect.Time.Posix Evergreen.V317.Call.CallId Evergreen.V317.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V317.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V317.Local.ChangeId Effect.Time.Posix Evergreen.V317.Call.CallId Evergreen.V317.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V317.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V317.Local.ChangeId Evergreen.V317.Call.ConnectionId Evergreen.V317.Cloudflare.RealtimeSessionId (List Evergreen.V317.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V317.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V317.Local.ChangeId Evergreen.V317.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Discord.UserAuth (Result Evergreen.V317.Discord.HttpError Evergreen.V317.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Result Evergreen.V317.Discord.HttpError Evergreen.V317.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
        (Result
            Evergreen.V317.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId
                , members : List (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
                }
            , List
                ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId
                , { guild : Evergreen.V317.Discord.GatewayGuild
                  , channels : List Evergreen.V317.Discord.Channel
                  , icon : Maybe Evergreen.V317.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Bool Evergreen.V317.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V317.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.AttachmentId, Evergreen.V317.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V317.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.AttachmentId, Evergreen.V317.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V317.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V317.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V317.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V317.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) (Result Evergreen.V317.Discord.HttpError (List Evergreen.V317.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Result Evergreen.V317.Discord.HttpError (List Evergreen.V317.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V317.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V317.DmChannelId.DmChannelId Evergreen.V317.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V317.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V317.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V317.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
        (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V317.Discord.HttpError
            { guild : Evergreen.V317.Discord.GatewayGuild
            , channels : List Evergreen.V317.Discord.Channel
            , icon : Maybe Evergreen.V317.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Result Evergreen.V317.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V317.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (List ( Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId, Result Effect.Http.Error Evergreen.V317.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId, Result Effect.Http.Error Evergreen.V317.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (List ( Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V317.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V317.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V317.Discord.HttpError (List Evergreen.V317.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V317.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V317.SecretId.SecretId Evergreen.V317.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V317.FileStatus.FileHash Int (Maybe (Evergreen.V317.Coord.Coord Evergreen.V317.CssPixels.CssPixels))
    | GotSwedishWordList (Result Effect.Http.Error String)
