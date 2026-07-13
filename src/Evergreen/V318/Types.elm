module Evergreen.V318.Types exposing (..)

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
import Evergreen.V318.AiChat
import Evergreen.V318.Audio
import Evergreen.V318.Call
import Evergreen.V318.ChannelDescription
import Evergreen.V318.ChannelName
import Evergreen.V318.Cloudflare
import Evergreen.V318.Coord
import Evergreen.V318.CssPixels
import Evergreen.V318.CustomEmoji
import Evergreen.V318.Discord
import Evergreen.V318.DiscordAttachmentId
import Evergreen.V318.DiscordUserData
import Evergreen.V318.DmChannel
import Evergreen.V318.DmChannelId
import Evergreen.V318.Drawing
import Evergreen.V318.Editable
import Evergreen.V318.EmailAddress
import Evergreen.V318.Embed
import Evergreen.V318.Emoji
import Evergreen.V318.FileStatus
import Evergreen.V318.Game
import Evergreen.V318.Go
import Evergreen.V318.GuildName
import Evergreen.V318.Id
import Evergreen.V318.ImageEditor
import Evergreen.V318.ImageViewer
import Evergreen.V318.LinkedAndOtherDiscordUsers
import Evergreen.V318.Local
import Evergreen.V318.LocalState
import Evergreen.V318.Log
import Evergreen.V318.LoginForm
import Evergreen.V318.MembersAndOwner
import Evergreen.V318.Message
import Evergreen.V318.MessageInput
import Evergreen.V318.MessageView
import Evergreen.V318.MyUi
import Evergreen.V318.NonemptyDict
import Evergreen.V318.NonemptySet
import Evergreen.V318.OneOrGreater
import Evergreen.V318.OneToOne
import Evergreen.V318.Pages.Admin
import Evergreen.V318.Pagination
import Evergreen.V318.PersonName
import Evergreen.V318.Ports
import Evergreen.V318.Postmark
import Evergreen.V318.Range
import Evergreen.V318.RichText
import Evergreen.V318.Route
import Evergreen.V318.Scroll
import Evergreen.V318.SecretId
import Evergreen.V318.SessionIdHash
import Evergreen.V318.Slack
import Evergreen.V318.Sticker
import Evergreen.V318.TextEditor
import Evergreen.V318.ToBackendLog
import Evergreen.V318.Touch
import Evergreen.V318.TwoFactorAuthentication
import Evergreen.V318.Ui.Anim
import Evergreen.V318.Untrusted
import Evergreen.V318.User
import Evergreen.V318.UserAgent
import Evergreen.V318.UserSession
import Evergreen.V318.WordSpellingGame
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
    | LoginFormMsg Evergreen.V318.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V318.Pages.Admin.Msg
    | PressedLogOut Evergreen.V318.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V318.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V318.Route.Route
    | SelectedFilesToAttach ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V318.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V318.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V318.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V318.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V318.NonemptyDict.NonemptyDict Int Evergreen.V318.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V318.NonemptyDict.NonemptyDict Int Evergreen.V318.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRoute Evergreen.V318.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V318.NonemptySet.NonemptySet (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V318.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V318.AiChat.Msg
    | GameMsg Evergreen.V318.Game.Msg
    | GoSpectatorMsg Evergreen.V318.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V318.Editable.Msg Evergreen.V318.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V318.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V318.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
        { fileId : Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
        { fileId : Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V318.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage Evergreen.V318.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V318.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V318.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V318.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V318.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.User.NotificationLevel
    | GotStartupData Evergreen.V318.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V318.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId
        , otherUserId : Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRoute Evergreen.V318.MessageInput.Msg
    | MessageInputMsg Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRoute Evergreen.V318.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V318.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V318.Range.Range, Evergreen.V318.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V318.Range.Range, Evergreen.V318.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V318.Call.FromJs)
    | VoiceChatMsg Evergreen.V318.Call.Msg
    | PressedChannelHeaderTab Evergreen.V318.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V318.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V318.Audio.LoadError Evergreen.V318.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V318.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V318.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) Evergreen.V318.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.LocalState.DiscordFrontendGuild
    , user : Evergreen.V318.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.User.FrontendUser
    , discordUsers : Evergreen.V318.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V318.SessionIdHash.SessionIdHash Evergreen.V318.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V318.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId) Evergreen.V318.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId) Evergreen.V318.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V318.Call.CallId (Evergreen.V318.NonemptyDict.NonemptyDict ( Evergreen.V318.Id.Id Evergreen.V318.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V318.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V318.Go.PublicGoMatchData Evergreen.V318.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V318.Route.Route
    , windowSize : Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V318.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V318.Audio.LoadError Evergreen.V318.Audio.Source
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V318.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V318.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V318.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V318.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V318.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.ChannelName.ChannelName Evergreen.V318.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.ChannelName.ChannelName Evergreen.V318.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.UserSession.ToBeFilledInByBackend (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V318.GuildName.GuildName (Evergreen.V318.UserSession.ToBeFilledInByBackend (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V318.Id.DiscordGuildOrDmId_DmData (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V318.UserSession.SetViewing
    | Local_SetName Evergreen.V318.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V318.Id.GuildOrDmId (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V318.Id.GuildOrDmId (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId) (Evergreen.V318.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V318.Id.DiscordGuildOrDmId (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V318.Id.DiscordGuildOrDmId (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId) (Evergreen.V318.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V318.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V318.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V318.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V318.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V318.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V318.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V318.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V318.NonemptySet.NonemptySet (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V318.Call.LocalChange
    | Local_Game Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Game.LocalChange
    | Local_Drawing Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Drawing.AnchorType Evergreen.V318.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Effect.Time.Posix Evergreen.V318.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V318.RichText.RichText (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))) Evergreen.V318.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId) Evergreen.V318.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V318.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V318.RichText.RichText (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))) Evergreen.V318.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId) Evergreen.V318.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.ChannelName.ChannelName Evergreen.V318.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.ChannelName.ChannelName Evergreen.V318.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V318.LocalState.JoinGuildError
            { guildId : Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId
            , guild : Evergreen.V318.LocalState.FrontendGuild
            , owner : Evergreen.V318.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V318.RichText.RichText (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))) (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V318.RichText.RichText (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V318.Id.DiscordGuildOrDmId_DmData (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V318.RichText.RichText (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V318.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V318.SessionIdHash.SessionIdHash Evergreen.V318.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V318.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V318.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V318.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V318.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Evergreen.V318.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.ChannelName.ChannelName (Evergreen.V318.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId)
        (Evergreen.V318.NonemptyDict.NonemptyDict
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) Evergreen.V318.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Evergreen.V318.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Maybe (Evergreen.V318.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V318.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V318.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V318.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V318.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V318.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V318.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) (Evergreen.V318.Discord.OptionalData String) (Evergreen.V318.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId)
        (Evergreen.V318.MembersAndOwner.MembersAndOwner
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Evergreen.V318.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId) Evergreen.V318.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId) Evergreen.V318.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V318.Call.ServerChange
    | Server_Game (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Game.LocalChange
    | Server_Drawing (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Drawing.AnchorType Evergreen.V318.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V318.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V318.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V318.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V318.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V318.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V318.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V318.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V318.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V318.Id.AnyGuildOrDmId Evergreen.V318.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V318.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels) (Maybe Evergreen.V318.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId) (Evergreen.V318.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V318.Editable.Model
    , domainWhitelistInput : String
    , serviceWorkerData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V318.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V318.Local.Local LocalMsg Evergreen.V318.LocalState.LocalState
    , admin : Evergreen.V318.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId, Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V318.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V318.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V318.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V318.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ) (Evergreen.V318.NonemptyDict.NonemptyDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V318.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V318.Scroll.ScrollPosition
    , textEditor : Evergreen.V318.TextEditor.Model
    , profilePictureEditor : Evergreen.V318.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId, Evergreen.V318.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V318.Emoji.Model
    , voiceChat : Evergreen.V318.Call.Model
    , games : SeqDict.SeqDict Evergreen.V318.Id.GuildOrDmId Evergreen.V318.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V318.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
    , friendsSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V318.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V318.Range.Range
                , direction : Evergreen.V318.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V318.NonemptyDict.NonemptyDict Int Evergreen.V318.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V318.NonemptyDict.NonemptyDict Int Evergreen.V318.Touch.Touch
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
    | AdminToFrontend Evergreen.V318.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V318.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V318.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V318.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V318.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V318.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V318.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V318.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V318.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V318.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V318.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V318.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V318.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V318.Audio.LoadError Evergreen.V318.Audio.Source
    , startupData : Evergreen.V318.Ports.StartupData
    , lastUrlChange : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V318.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V318.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V318.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V318.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V318.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId, Evergreen.V318.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V318.DmChannelId.DmChannelId, Evergreen.V318.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId, Evergreen.V318.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId, Evergreen.V318.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V318.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V318.NonemptyDict.NonemptyDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V318.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V318.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V318.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V318.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) Evergreen.V318.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V318.DmChannelId.DmChannelId Evergreen.V318.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) Evergreen.V318.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.Slack.Id Evergreen.V318.Slack.ChannelId) Evergreen.V318.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V318.OneToOne.OneToOne String (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    , slackUsers : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.Slack.Id Evergreen.V318.Slack.UserId) (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)
    , slackServers : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.Slack.Id Evergreen.V318.Slack.TeamId) (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    , slackToken : Maybe Evergreen.V318.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V318.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V318.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V318.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V318.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V318.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V318.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V318.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V318.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Evergreen.V318.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId, Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V318.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V318.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V318.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V318.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.LocalState.LoadingDiscordChannel (List Evergreen.V318.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V318.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId) Evergreen.V318.Sticker.StickerData
    , discordStickers : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.Discord.Id Evergreen.V318.Discord.StickerId) (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId) Evergreen.V318.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V318.OneToOne.OneToOne Evergreen.V318.RichText.DiscordCustomEmojiIdAndName (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V318.Postmark.ApiKey
    , serverSecret : Evergreen.V318.SecretId.SecretId Evergreen.V318.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V318.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.GamePublicId) ( Evergreen.V318.DmChannelId.GuildOrFullDmId, Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V318.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V318.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V318.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V318.DmChannelId.DmChannelId Evergreen.V318.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V318.Id.DiscordGuildOrDmId Evergreen.V318.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V318.Id.Id Evergreen.V318.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V318.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V318.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V318.Untrusted.Untrusted Evergreen.V318.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V318.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V318.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V318.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V318.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V318.PersonName.PersonName Evergreen.V318.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V318.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V318.Slack.OAuthCode Evergreen.V318.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V318.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V318.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V318.Id.Id Evergreen.V318.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V318.EmailAddress.EmailAddress (Result Evergreen.V318.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V318.EmailAddress.EmailAddress (Result Evergreen.V318.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V318.EmailAddress.EmailAddress (Result Evergreen.V318.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V318.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMaybeMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Result Evergreen.V318.Discord.HttpError Evergreen.V318.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V318.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Result Evergreen.V318.Discord.HttpError Evergreen.V318.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) (Result Evergreen.V318.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) (Result Evergreen.V318.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) (Result Evergreen.V318.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) (Result Evergreen.V318.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji (Result Evergreen.V318.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji (Result Evergreen.V318.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji (Result Evergreen.V318.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji (Result Evergreen.V318.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V318.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V318.Discord.HttpError (List ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId, Maybe Evergreen.V318.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Effect.Time.Posix Evergreen.V318.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V318.Slack.CurrentUser
            , team : Evergreen.V318.Slack.Team
            , users : List Evergreen.V318.Slack.User
            , channels : List ( Evergreen.V318.Slack.Channel, List Evergreen.V318.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Result Effect.Http.Error Evergreen.V318.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V318.Local.ChangeId Effect.Time.Posix Evergreen.V318.Call.CallId Evergreen.V318.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V318.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V318.Local.ChangeId Effect.Time.Posix Evergreen.V318.Call.CallId Evergreen.V318.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V318.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V318.Local.ChangeId Evergreen.V318.Call.ConnectionId Evergreen.V318.Cloudflare.RealtimeSessionId (List Evergreen.V318.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V318.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V318.Local.ChangeId Evergreen.V318.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Discord.UserAuth (Result Evergreen.V318.Discord.HttpError Evergreen.V318.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Result Evergreen.V318.Discord.HttpError Evergreen.V318.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
        (Result
            Evergreen.V318.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId
                , members : List (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
                }
            , List
                ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId
                , { guild : Evergreen.V318.Discord.GatewayGuild
                  , channels : List Evergreen.V318.Discord.Channel
                  , icon : Maybe Evergreen.V318.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Bool Evergreen.V318.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V318.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.AttachmentId, Evergreen.V318.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V318.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.AttachmentId, Evergreen.V318.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V318.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V318.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V318.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V318.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) (Result Evergreen.V318.Discord.HttpError (List Evergreen.V318.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Result Evergreen.V318.Discord.HttpError (List Evergreen.V318.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V318.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V318.DmChannelId.DmChannelId Evergreen.V318.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V318.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V318.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V318.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
        (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V318.Discord.HttpError
            { guild : Evergreen.V318.Discord.GatewayGuild
            , channels : List Evergreen.V318.Discord.Channel
            , icon : Maybe Evergreen.V318.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Result Evergreen.V318.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V318.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (List ( Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId, Result Effect.Http.Error Evergreen.V318.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId, Result Effect.Http.Error Evergreen.V318.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (List ( Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V318.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V318.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V318.Discord.HttpError (List Evergreen.V318.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V318.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V318.SecretId.SecretId Evergreen.V318.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V318.FileStatus.FileHash Int (Maybe (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
