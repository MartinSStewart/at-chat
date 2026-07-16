module Evergreen.V326.Types exposing (..)

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
import Evergreen.V326.AiChat
import Evergreen.V326.Audio
import Evergreen.V326.Call
import Evergreen.V326.ChannelDescription
import Evergreen.V326.ChannelName
import Evergreen.V326.Cloudflare
import Evergreen.V326.Coord
import Evergreen.V326.CssPixels
import Evergreen.V326.CustomEmoji
import Evergreen.V326.Discord
import Evergreen.V326.DiscordAttachmentId
import Evergreen.V326.DiscordUserData
import Evergreen.V326.DmChannel
import Evergreen.V326.DmChannelId
import Evergreen.V326.Drawing
import Evergreen.V326.Editable
import Evergreen.V326.EmailAddress
import Evergreen.V326.Embed
import Evergreen.V326.Emoji
import Evergreen.V326.FileStatus
import Evergreen.V326.Game
import Evergreen.V326.Go
import Evergreen.V326.GuildName
import Evergreen.V326.Id
import Evergreen.V326.ImageEditor
import Evergreen.V326.ImageViewer
import Evergreen.V326.LinkedAndOtherDiscordUsers
import Evergreen.V326.Local
import Evergreen.V326.LocalState
import Evergreen.V326.Log
import Evergreen.V326.LoginForm
import Evergreen.V326.MembersAndOwner
import Evergreen.V326.Message
import Evergreen.V326.MessageInput
import Evergreen.V326.MessageView
import Evergreen.V326.MyUi
import Evergreen.V326.NonemptyDict
import Evergreen.V326.NonemptySet
import Evergreen.V326.OneOrGreater
import Evergreen.V326.OneToOne
import Evergreen.V326.Pages.Admin
import Evergreen.V326.Pagination
import Evergreen.V326.PersonName
import Evergreen.V326.Ports
import Evergreen.V326.Postmark
import Evergreen.V326.Range
import Evergreen.V326.RichText
import Evergreen.V326.Route
import Evergreen.V326.Scroll
import Evergreen.V326.SecretId
import Evergreen.V326.SessionIdHash
import Evergreen.V326.Slack
import Evergreen.V326.Sticker
import Evergreen.V326.TextEditor
import Evergreen.V326.ToBackendLog
import Evergreen.V326.Touch
import Evergreen.V326.TwoFactorAuthentication
import Evergreen.V326.Ui.Anim
import Evergreen.V326.Untrusted
import Evergreen.V326.User
import Evergreen.V326.UserAgent
import Evergreen.V326.UserSession
import Evergreen.V326.WordSpellingGame
import List.Nonempty
import Quantity
import SeqDict
import SeqSet
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


type UserOptionSection
    = UserOption_TwoFactorAuthentication
    | UserOption_Settings
    | UserOption_WhitelistedDomains
    | UserOption_Discord
    | UserOption_ConnectedDevices
    | UserOption_Debug


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V326.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V326.Pages.Admin.Msg
    | PressedLogOut Evergreen.V326.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V326.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V326.Route.Route
    | SelectedFilesToAttach ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V326.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V326.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V326.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V326.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V326.NonemptyDict.NonemptyDict Int Evergreen.V326.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V326.NonemptyDict.NonemptyDict Int Evergreen.V326.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRoute Evergreen.V326.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V326.NonemptySet.NonemptySet (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V326.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V326.AiChat.Msg
    | GameMsg Evergreen.V326.Game.Msg
    | GoSpectatorMsg Evergreen.V326.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V326.Editable.Msg Evergreen.V326.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V326.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V326.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
        { fileId : Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
        { fileId : Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V326.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage Evergreen.V326.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V326.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V326.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V326.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V326.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.User.NotificationLevel
    | GotStartupData Evergreen.V326.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V326.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId
        , otherUserId : Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRoute Evergreen.V326.MessageInput.Msg
    | MessageInputMsg Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRoute Evergreen.V326.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V326.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V326.Range.Range, Evergreen.V326.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V326.Range.Range, Evergreen.V326.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V326.Call.FromJs)
    | VoiceChatMsg Evergreen.V326.Call.Msg
    | PressedChannelHeaderTab Evergreen.V326.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V326.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V326.Audio.LoadError Evergreen.V326.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V326.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V326.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) Evergreen.V326.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.LocalState.DiscordFrontendGuild
    , user : Evergreen.V326.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.User.FrontendUser
    , discordUsers : Evergreen.V326.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V326.SessionIdHash.SessionIdHash Evergreen.V326.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V326.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId) Evergreen.V326.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId) Evergreen.V326.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V326.Call.CallId (Evergreen.V326.NonemptyDict.NonemptyDict ( Evergreen.V326.Id.Id Evergreen.V326.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V326.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V326.Go.PublicGoMatchData Evergreen.V326.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V326.Route.Route
    , windowSize : Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V326.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V326.Audio.LoadError Evergreen.V326.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V326.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V326.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V326.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V326.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V326.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.ChannelName.ChannelName Evergreen.V326.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.ChannelName.ChannelName Evergreen.V326.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.UserSession.ToBeFilledInByBackend (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V326.GuildName.GuildName (Evergreen.V326.UserSession.ToBeFilledInByBackend (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V326.Id.DiscordGuildOrDmId_DmData (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V326.UserSession.SetViewing
    | Local_SetName Evergreen.V326.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V326.Id.GuildOrDmId (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V326.Id.GuildOrDmId (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId) (Evergreen.V326.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V326.Id.DiscordGuildOrDmId (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V326.Id.DiscordGuildOrDmId (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId) (Evergreen.V326.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V326.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V326.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V326.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V326.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V326.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V326.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V326.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V326.NonemptySet.NonemptySet (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V326.Call.LocalChange
    | Local_Game Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Game.LocalChange
    | Local_Drawing Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Drawing.AnchorType Evergreen.V326.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Effect.Time.Posix Evergreen.V326.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V326.RichText.RichText (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))) Evergreen.V326.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId) Evergreen.V326.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V326.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V326.RichText.RichText (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))) Evergreen.V326.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId) Evergreen.V326.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.ChannelName.ChannelName Evergreen.V326.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.ChannelName.ChannelName Evergreen.V326.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V326.LocalState.JoinGuildError
            { guildId : Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId
            , guild : Evergreen.V326.LocalState.FrontendGuild
            , owner : Evergreen.V326.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V326.RichText.RichText (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))) (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V326.RichText.RichText (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V326.Id.DiscordGuildOrDmId_DmData (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V326.RichText.RichText (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V326.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V326.SessionIdHash.SessionIdHash Evergreen.V326.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V326.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V326.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V326.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V326.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Evergreen.V326.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.ChannelName.ChannelName (Evergreen.V326.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
        (Evergreen.V326.NonemptyDict.NonemptyDict
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) Evergreen.V326.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Evergreen.V326.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Maybe (Evergreen.V326.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V326.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V326.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V326.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V326.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V326.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V326.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) (Evergreen.V326.Discord.OptionalData String) (Evergreen.V326.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
        (Evergreen.V326.MembersAndOwner.MembersAndOwner
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Evergreen.V326.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId) Evergreen.V326.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId) Evergreen.V326.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V326.Call.ServerChange
    | Server_Game (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Game.LocalChange
    | Server_Drawing (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Drawing.AnchorType Evergreen.V326.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V326.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V326.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V326.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V326.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V326.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V326.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V326.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V326.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V326.Id.AnyGuildOrDmId Evergreen.V326.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V326.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels) (Maybe Evergreen.V326.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId) (Evergreen.V326.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V326.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V326.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V326.Local.Local LocalMsg Evergreen.V326.LocalState.LocalState
    , admin : Evergreen.V326.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId, Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V326.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V326.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V326.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V326.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ) (Evergreen.V326.NonemptyDict.NonemptyDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V326.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V326.Scroll.ScrollPosition
    , textEditor : Evergreen.V326.TextEditor.Model
    , profilePictureEditor : Evergreen.V326.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId, Evergreen.V326.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V326.Emoji.Model
    , voiceChat : Evergreen.V326.Call.Model
    , games : SeqDict.SeqDict Evergreen.V326.Id.GuildOrDmId Evergreen.V326.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V326.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
    , friendsSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V326.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V326.Range.Range
                , direction : Evergreen.V326.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V326.NonemptyDict.NonemptyDict Int Evergreen.V326.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V326.NonemptyDict.NonemptyDict Int Evergreen.V326.Touch.Touch
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
    | AdminToFrontend Evergreen.V326.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V326.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V326.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V326.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V326.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V326.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V326.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V326.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V326.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V326.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V326.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V326.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V326.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V326.Audio.LoadError Evergreen.V326.Audio.Source
    , startupData : Evergreen.V326.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V326.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V326.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V326.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V326.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V326.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId, Evergreen.V326.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V326.DmChannelId.DmChannelId, Evergreen.V326.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId, Evergreen.V326.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId, Evergreen.V326.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V326.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V326.NonemptyDict.NonemptyDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V326.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V326.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V326.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V326.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V326.DmChannelId.DmChannelId Evergreen.V326.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) Evergreen.V326.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.Slack.Id Evergreen.V326.Slack.ChannelId) Evergreen.V326.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V326.OneToOne.OneToOne String (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    , slackUsers : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.Slack.Id Evergreen.V326.Slack.UserId) (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    , slackServers : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.Slack.Id Evergreen.V326.Slack.TeamId) (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    , slackToken : Maybe Evergreen.V326.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V326.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V326.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V326.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V326.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V326.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V326.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V326.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V326.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Evergreen.V326.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId, Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V326.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V326.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V326.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V326.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.LocalState.LoadingDiscordChannel (List Evergreen.V326.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V326.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId) Evergreen.V326.Sticker.StickerData
    , discordStickers : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.Discord.Id Evergreen.V326.Discord.StickerId) (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId) Evergreen.V326.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V326.OneToOne.OneToOne Evergreen.V326.RichText.DiscordCustomEmojiIdAndName (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V326.Postmark.ApiKey
    , serverSecret : Evergreen.V326.SecretId.SecretId Evergreen.V326.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V326.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.GamePublicId) ( Evergreen.V326.DmChannelId.GuildOrFullDmId, Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V326.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V326.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V326.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V326.DmChannelId.DmChannelId Evergreen.V326.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V326.Id.DiscordGuildOrDmId Evergreen.V326.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V326.Id.Id Evergreen.V326.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V326.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V326.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V326.Untrusted.Untrusted Evergreen.V326.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V326.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V326.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V326.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V326.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V326.PersonName.PersonName Evergreen.V326.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V326.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V326.Slack.OAuthCode Evergreen.V326.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V326.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V326.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V326.Id.Id Evergreen.V326.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V326.EmailAddress.EmailAddress (Result Evergreen.V326.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V326.EmailAddress.EmailAddress (Result Evergreen.V326.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V326.EmailAddress.EmailAddress (Result Evergreen.V326.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V326.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMaybeMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Result Evergreen.V326.Discord.HttpError Evergreen.V326.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V326.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Result Evergreen.V326.Discord.HttpError Evergreen.V326.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) (Result Evergreen.V326.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) (Result Evergreen.V326.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) (Result Evergreen.V326.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) (Result Evergreen.V326.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji (Result Evergreen.V326.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji (Result Evergreen.V326.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji (Result Evergreen.V326.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji (Result Evergreen.V326.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V326.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V326.Discord.HttpError (List ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId, Maybe Evergreen.V326.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Effect.Time.Posix Evergreen.V326.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V326.Slack.CurrentUser
            , team : Evergreen.V326.Slack.Team
            , users : List Evergreen.V326.Slack.User
            , channels : List ( Evergreen.V326.Slack.Channel, List Evergreen.V326.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Result Effect.Http.Error Evergreen.V326.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V326.Local.ChangeId Effect.Time.Posix Evergreen.V326.Call.CallId Evergreen.V326.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V326.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V326.Local.ChangeId Effect.Time.Posix Evergreen.V326.Call.CallId Evergreen.V326.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V326.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V326.Local.ChangeId Evergreen.V326.Call.ConnectionId Evergreen.V326.Cloudflare.RealtimeSessionId (List Evergreen.V326.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V326.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V326.Local.ChangeId Evergreen.V326.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Discord.UserAuth (Result Evergreen.V326.Discord.HttpError Evergreen.V326.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Result Evergreen.V326.Discord.HttpError Evergreen.V326.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
        (Result
            Evergreen.V326.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId
                , members : List (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
                }
            , List
                ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId
                , { guild : Evergreen.V326.Discord.GatewayGuild
                  , channels : List Evergreen.V326.Discord.Channel
                  , icon : Maybe Evergreen.V326.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Bool Evergreen.V326.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V326.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.AttachmentId, Evergreen.V326.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V326.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.AttachmentId, Evergreen.V326.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V326.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V326.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V326.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V326.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) (Result Evergreen.V326.Discord.HttpError (List Evergreen.V326.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Result Evergreen.V326.Discord.HttpError (List Evergreen.V326.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V326.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V326.DmChannelId.DmChannelId Evergreen.V326.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V326.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V326.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V326.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
        (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V326.Discord.HttpError
            { guild : Evergreen.V326.Discord.GatewayGuild
            , channels : List Evergreen.V326.Discord.Channel
            , icon : Maybe Evergreen.V326.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Result Evergreen.V326.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V326.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (List ( Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId, Result Effect.Http.Error Evergreen.V326.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId, Result Effect.Http.Error Evergreen.V326.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (List ( Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V326.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V326.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V326.Discord.HttpError (List Evergreen.V326.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V326.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V326.SecretId.SecretId Evergreen.V326.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V326.FileStatus.FileHash Int (Maybe (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
